// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IUniswapRouterPolygon.sol";

import "hardhat/console.sol";

contract IntentReceiver {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // address of the token that can be bridged (ex: USDC)
    address public sourceTokenAddress;

    // address of the uniswap router contract
    address public uniswapRouter;


    constructor(
        address _sourceTokenAddress,
        address _uniswapRouter
    ) {
        sourceTokenAddress = _sourceTokenAddress;
        uniswapRouter = _uniswapRouter;
    }

    function receiveIntent(
        address tokenAddress,
        address to,
        uint256 _amount
    ) payable external {
        require(_amount > 0, "Amount must be greater than 0");

        uint amount = _amount;
        if (tokenAddress != sourceTokenAddress) {
            amount = _swapTokensAndTransfer(sourceTokenAddress, tokenAddress, _amount, to);
            return;
        }

        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        token.safeTransfer(to, amount);
    }

    function _swapTokensAndTransfer(
        address fromToken,
        address toToken,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = fromToken;
        path[1] = toToken;

        IERC20Upgradeable fromAsset = IERC20Upgradeable(fromToken);
        fromAsset.safeApprove(uniswapRouter, amount);

        IERC20Upgradeable asset = IERC20Upgradeable(toToken);
        uint256 previousBalance = asset.balanceOf(recipient);
        IUniswapRouterPolygon.ExactInputSingleParams memory params = IUniswapRouterPolygon.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            fee: 3000,
            recipient: recipient,
            amountIn: amount,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });
        IUniswapRouterPolygon(uniswapRouter).exactInputSingle(params);
        uint256 currentBalance = asset.balanceOf(recipient);
        require(currentBalance - previousBalance > 0, "Swap failed");
        return currentBalance - previousBalance;
    }

    receive() external payable {}
}