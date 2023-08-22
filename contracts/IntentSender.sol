// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IUniswapRouter.sol";
import "./IntentReceiver.sol";

contract IntentSender {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MAX_BPS = 10000;

    uint256 public constant GAS_REQUIRED_ON_DESTINATION = 5000000;

    ///////////////////////////////////////////////////
    /////////////// STG Configuration ////////////////
    /////////////////////////////////////////////////

    // minimum quantity of tokens to recieve on the destination chain. (99.94% of the amount sent)
    uint256 public constant minimumAmountInDestination = 9994;

    // destinationChainID => true
    mapping (uint16 => bool) public destinationConfigured;

    // destinationChainId => destinationPoolId (ex: USDC pool ID)
    mapping (uint16 => uint256) public destinationPoolId;

    // chain id of the chain where the intent was created
    uint16 public sourceChainId; 

    // pool id of the pool where the intent was created (ex: USDC pool ID)
    uint256 public sourcePoolId;

    // address of the token that can be bridged (ex: USDC)
    address public sourceTokenAddress;

    // address of the STG router contract
    address public stgRouter;

    ///////////////////////////////////////////////////////
    /////////////// Uniswap Configuration ////////////////
    /////////////////////////////////////////////////////

    // address of the uniswap router contract
    address public uniswapRouter;

    constructor(
        uint16 _sourceChainId,
        uint256 _sourcePoolId,
        address _sourceTokenAddress,
        address _stgRouter,
        address _uniswapRouter
    ) payable {
        sourceChainId = _sourceChainId;
        sourcePoolId = _sourcePoolId;
        sourceTokenAddress = _sourceTokenAddress;
        stgRouter = _stgRouter;
        uniswapRouter = _uniswapRouter;
    }

    function setDestination(uint16 _destinationChainId, uint256 _destinationPoolId) external {
        destinationConfigured[_destinationChainId] = true;
        destinationPoolId[_destinationChainId] = _destinationPoolId;
    }

    function sendIntent(
        uint16 _destinationChainId, 
        address _sourceToken,
        uint256 _amount,
        address _destinationToken,
        uint256 _destinationNativeAmount
    ) external payable {
        require(destinationConfigured[_destinationChainId], "Destination not configured");
        require(_amount > 0, "Amount must be greater than 0");

        _receiveAsset(_sourceToken, _amount);
        uint amount = _amount;
        if (_sourceToken != sourceTokenAddress) {
            amount = _swapTokens(_sourceToken, sourceTokenAddress, _amount);
        }

        _approveAssetForTransfer(sourceTokenAddress, amount);

        uint256 destinationAmountMin = (amount * minimumAmountInDestination) / MAX_BPS;

        bytes memory destinationPayload = abi.encodeWithSignature("receiveIntent(address,address,uint256)", _destinationToken, msg.sender, destinationAmountMin);
        uint256 fee = _getCrossChainTransferFee(_destinationChainId, msg.sender, destinationPayload, _destinationNativeAmount);

        _transferCrossChain(
            _destinationChainId, 
            sourcePoolId, 
            destinationPoolId[_destinationChainId], 
            amount, 
            msg.sender, 
            fee,
            destinationAmountMin,
            _destinationNativeAmount
        );
    }

    function _swapTokens(
        address fromToken,
        address toToken,
        uint256 amount
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        IERC20Upgradeable fromAsset = IERC20Upgradeable(fromToken);
        fromAsset.safeApprove(uniswapRouter, amount);

        IERC20Upgradeable asset = IERC20Upgradeable(toToken);
        uint256 previousBalance = asset.balanceOf(address(this));
        IUniswapRouter.ExactInputSingleParams memory params = IUniswapRouter
            .ExactInputSingleParams({
                tokenIn: fromToken,
                tokenOut: toToken,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        IUniswapRouter(uniswapRouter).exactInputSingle(params);
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
        address _toAddress,
        bytes memory destinationPayload,
        uint256 _destinationNativeAmount
    ) view internal returns (uint256 fee) {
        IStargateRouter router = IStargateRouter(stgRouter);
        (fee, ) = router.quoteLayerZeroFee(
            _destinationChainId,
            1,
            abi.encodePacked(_toAddress),
            destinationPayload,
            IStargateRouter.lzTxObj(GAS_REQUIRED_ON_DESTINATION, _destinationNativeAmount, abi.encodePacked(_toAddress))
        );
    }

    function _transferCrossChain(
        uint16 _destinationChainId,
        uint256 _sourcePoolId,
        uint256 _destinationPoolId,
        uint256 _amount,
        address _toAddress,
        uint256 _fee,
        uint256 _destinationAmountMin,
        uint256 _destinationNativeAmount
    ) internal {
        IStargateRouter router = IStargateRouter(stgRouter);
        router.swap{ value: _fee }(
            _destinationChainId,
            _sourcePoolId,
            _destinationPoolId,
            payable(address(this)),
            _amount,
            _destinationAmountMin,
            IStargateRouter.lzTxObj(GAS_REQUIRED_ON_DESTINATION, _destinationNativeAmount, "0x"),
            abi.encodePacked(_toAddress),
            "0x"
        );
    }

    receive() external payable {}
}
