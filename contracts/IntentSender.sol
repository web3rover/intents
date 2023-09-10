// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "./interfaces/IStargateRouter.sol";
import "./IntentReceiver.sol";

contract IntentSender {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct IntentData {
        uint16 destinationChainId; 
        address sourceToken;
        uint256 amount;
        address destinationToken;
        uint256 destinationNativeAmount;
        address sourceSwapper;
        address destinationSwapper;
        bytes sourceSwapData;
        bytes destinationSwapData;
    }

    uint256 public constant MAX_BPS = 10000;

    uint256 public constant GAS_REQUIRED_ON_DESTINATION = 600000;

    ///////////////////////////////////////////////////
    /////////////// STG Configuration ////////////////
    /////////////////////////////////////////////////

    // minimum quantity of tokens to recieve on the destination chain. (99.94% of the amount sent)
    uint256 public constant minimumAmountInDestination = 9994;

    // destinationChainID => true
    mapping (uint16 => bool) public destinationConfigured;

    // destinationChainId => destinationPoolId (ex: USDC pool ID)
    mapping (uint16 => uint256) public destinationPoolId;

    // destinationChainId => destinationAddress (ex: address of IntentReceiver contract)
    mapping (uint16 => address) public destinationAddress;

    // chain id of the chain where the intent was created
    uint16 public sourceChainId; 

    // pool id of the pool where the intent was created (ex: USDC pool ID)
    uint256 public sourcePoolId;

    // address of the token that can be bridged (ex: USDC)
    address public sourceTokenAddress;

    // address of the STG router contract
    address public stgRouter;

    constructor(
        uint16 _sourceChainId,
        uint256 _sourcePoolId,
        address _sourceTokenAddress,
        address _stgRouter
    ) payable {
        sourceChainId = _sourceChainId;
        sourcePoolId = _sourcePoolId;
        sourceTokenAddress = _sourceTokenAddress;
        stgRouter = _stgRouter;
    }

    function setDestination(uint16 _destinationChainId, uint256 _destinationPoolId, address _destinationAddress) external {
        destinationConfigured[_destinationChainId] = true;
        destinationPoolId[_destinationChainId] = _destinationPoolId;
        destinationAddress[_destinationChainId] = _destinationAddress;
    }

    function sendIntent(
        IntentData calldata _intentData
    ) external payable {
        require(destinationConfigured[_intentData.destinationChainId], "Destination not configured");
        require(_intentData.amount > 0, "Amount must be greater than 0");

        _receiveAsset(_intentData.sourceToken, _intentData.amount);
        uint amount = _intentData.amount;
        if (_intentData.sourceToken != sourceTokenAddress) {
            amount = _swapTokens(_intentData.sourceToken, sourceTokenAddress, _intentData.amount, _intentData.sourceSwapper, _intentData.sourceSwapData);
        }

        _approveAssetForTransfer(sourceTokenAddress, amount);

        uint256 destinationAmountMin = (amount * minimumAmountInDestination) / MAX_BPS;
        
        bytes memory destinationPayload = abi.encode(_intentData.destinationToken, msg.sender, _intentData.destinationSwapper, _intentData.destinationSwapData);
        uint256 fee = _getCrossChainTransferFee(_intentData.destinationChainId, destinationPayload, _intentData.destinationNativeAmount);

        uint256 _destinationPoolId = destinationPoolId[_intentData.destinationChainId];

        _transferCrossChain(
            _intentData.destinationChainId, 
            sourcePoolId, 
            _destinationPoolId, 
            amount, 
            msg.sender, 
            fee,
            destinationAmountMin,
            _intentData.destinationNativeAmount,
            destinationPayload
        );
    }

    function _swapTokens(
        address fromToken,
        address toToken,
        uint256 amount,
        address swapper,
        bytes memory swapData
    ) internal returns (uint256) {
        IERC20Upgradeable fromAsset = IERC20Upgradeable(fromToken);
        fromAsset.safeApprove(swapper, amount);

        IERC20Upgradeable asset = IERC20Upgradeable(toToken);
        uint256 previousBalance = asset.balanceOf(address(this));
        
        // no native token support for swap
        // use swapper.call{value: nativeValue}(_swap.callData)
        swapper.call(swapData); 

        uint256 currentBalance = asset.balanceOf(address(this));
        require(currentBalance - previousBalance > 0, "Swap failed");
        return currentBalance - previousBalance;
    }

    function _receiveAsset(address _token, uint256 _amount) internal {
        IERC20Upgradeable asset = IERC20Upgradeable(_token);
        asset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _approveAssetForTransfer(address _token, uint256 _amount) internal {
        IERC20Upgradeable asset = IERC20Upgradeable(_token);
        asset.safeApprove(stgRouter, _amount);
    }

    function _getCrossChainTransferFee(
        uint16 _destinationChainId,
        bytes memory destinationPayload,
        uint256 _destinationNativeAmount
    ) view internal returns (uint256 fee) {
        IStargateRouter router = IStargateRouter(stgRouter);
        (fee, ) = router.quoteLayerZeroFee(
            _destinationChainId,
            1,
            abi.encodePacked(destinationAddress[_destinationChainId]),
            destinationPayload,
            IStargateRouter.lzTxObj(GAS_REQUIRED_ON_DESTINATION, _destinationNativeAmount, abi.encodePacked(destinationAddress[_destinationChainId]))
        );
    }

    function getCrossChainTransferFee(
        uint16 _destinationChainId,
        uint256 _destinationNativeAmount,
        address _destinationSwapper,
        bytes calldata _destinationSwapData
    ) view external returns (uint256 fee) {
        bytes memory destinationPayload = abi.encode(address(0), msg.sender, _destinationSwapper, _destinationSwapData);
        return _getCrossChainTransferFee(_destinationChainId, destinationPayload, _destinationNativeAmount);
    }

    function _transferCrossChain(
        uint16 _destinationChainId,
        uint256 _sourcePoolId,
        uint256 _destinationPoolId,
        uint256 _amount,
        address _toAddress,
        uint256 _fee,
        uint256 _destinationAmountMin,
        uint256 _destinationNativeAmount,
        bytes memory destinationPayload
    ) internal {
        IStargateRouter router = IStargateRouter(stgRouter);
        address dstAddr = destinationAddress[_destinationChainId];
        router.swap{ value: _fee }(
            _destinationChainId,
            _sourcePoolId,
            _destinationPoolId,
            payable(msg.sender),
            _amount,
            _destinationAmountMin,
            IStargateRouter.lzTxObj(GAS_REQUIRED_ON_DESTINATION, _destinationNativeAmount, abi.encodePacked(dstAddr)),
            abi.encodePacked(dstAddr),
            destinationPayload
        );
    }

    receive() external payable {}
}