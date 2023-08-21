// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "./interfaces/IStargateRouter.sol";
import "./interfaces/IUniswapRouter.sol";

contract IntentSender {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MAX_BPS = 10000;

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

    function sendIntent(uint16 _destinationChainId, address _sourceToken, uint256 _amount) external {
        require(destinationConfigured[_destinationChainId], "Destination not configured");
        require(_amount > 0, "Amount must be greater than 0");

        _receiveAsset(_sourceToken, _amount);
        uint amount = _amount;
        if (_sourceToken != sourceTokenAddress) {
            amount = _swapTokens(_sourceToken, sourceTokenAddress, _amount);
        }
        
        // _approveAssetForTransfer(sourceTokenAddress, amount);

        // uint256 fee = getCrossChainTransferFee(_destinationChainId, msg.sender);

        // _transferCrossChain(
        //     _destinationChainId, 
        //     sourcePoolId, 
        //     destinationPoolId[_destinationChainId], 
        //     amount, 
        //     msg.sender, 
        //     fee
        // );
    }

    //implement pending
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
        IUniswapV2Router01(uniswapRouter).swapExactTokensForTokens(amount, 0, path, msg.sender);
        uint256 currentBalance = asset.balanceOf(address(this));
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

    function getCrossChainTransferFee(
        uint16 _destinationChainId,
        address _toAddress
    ) view public returns (uint256 fee) {
        IStargateRouter router = IStargateRouter(stgRouter);
        (fee, ) = router.quoteLayerZeroFee(
            _destinationChainId,
            1,
            abi.encodePacked(_toAddress),
            "",
            IStargateRouter.lzTxObj(0, 0, "0x")
        );
    }

    function _transferCrossChain(
        uint16 _destinationChainId,
        uint256 _sourcePoolId,
        uint256 _destinationPoolId,
        uint256 _amount,
        address _toAddress,
        uint256 _fee
    ) internal {
        uint256 destinationAmountMin = (_amount * minimumAmountInDestination) / MAX_BPS;

        IStargateRouter router = IStargateRouter(stgRouter);
        router.swap{ value: _fee }(
            _destinationChainId,
            _sourcePoolId,
            _destinationPoolId,
            payable(address(this)),
            _amount,
            destinationAmountMin,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(_toAddress),
            "0x"
        );
    }

    receive() external payable {}
}
