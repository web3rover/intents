// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IUniswapRouterL2.sol";
import "./interfaces/IStargateReceiver.sol";

import "hardhat/console.sol";

contract IntentReceiver is IStargateReceiver {
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

    function sgReceive(
        uint16 _srcChainId,              // the remote chainId sending the tokens
        bytes memory _srcAddress,        // the remote Bridge address
        uint256 _nonce,                  
        address _token,                  // the token contract on the local chain
        uint256 amountLD,                // the qty of local _token contract tokens  
        bytes memory payload
    ) external payable {
        (
            address tokenAddress,
            address to
        ) = abi.decode(payload, (address, address));
        executeIntent(tokenAddress, to);
    }

    function executeIntent(
        address tokenAddress,
        address to
    ) payable public {
        IERC20Upgradeable source = IERC20Upgradeable(sourceTokenAddress);
        uint256 amount = source.balanceOf(address(this));

        require(amount > 0, "Amount must be greater than 0");

        if (tokenAddress != sourceTokenAddress) {
            amount = _swapTokensAndTransfer(sourceTokenAddress, tokenAddress, amount, to);
        } else {
            source.safeTransfer(to, amount);
        }

        payable(to).transfer(address(this).balance);
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
        IUniswapRouterL2.ExactInputSingleParams memory params = IUniswapRouterL2.ExactInputSingleParams({
            tokenIn: fromToken,
            tokenOut: toToken,
            fee: 3000,
            recipient: recipient,
            amountIn: amount,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });
        IUniswapRouterL2(uniswapRouter).exactInputSingle(params);
        uint256 currentBalance = asset.balanceOf(recipient);
        require(currentBalance - previousBalance > 0, "Swap failed");
        return currentBalance - previousBalance;
    }

    receive() external payable {}
}