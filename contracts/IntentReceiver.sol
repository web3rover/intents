// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IUniswapRouter.sol";

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
            amount = _swapTokens(sourceTokenAddress, tokenAddress, _amount, to);
        }

        // IERC20Upgradeable asset = IERC20Upgradeable(tokenAddress);
        // asset.safeTransfer(to, amount);
    }

    function _swapTokens(
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
        uint256 previousBalance = asset.balanceOf(address(this));
        IUniswapRouter.ExactInputSingleParams memory params = IUniswapRouter
            .ExactInputSingleParams({
                tokenIn: fromToken,
                tokenOut: toToken,
                fee: 3000,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        IUniswapRouter(uniswapRouter).exactInputSingle(params);
        // uint256 currentBalance = asset.balanceOf(address(this));
        // require(currentBalance - previousBalance > 0, "Swap failed");
        // return currentBalance - previousBalance;
    }

    receive() external payable {}
}