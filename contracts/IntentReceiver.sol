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

    constructor(
        address _sourceTokenAddress
    ) {
        sourceTokenAddress = _sourceTokenAddress;
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
            address to,
            address swapper,
            bytes memory swapData
        ) = abi.decode(payload, (address, address, address, bytes));
        executeIntent(tokenAddress, to, swapper, swapData);
    }

    function executeIntent(
        address tokenAddress,
        address to,
        address swapper,
        bytes memory swapData
    ) payable public {
        IERC20Upgradeable source = IERC20Upgradeable(sourceTokenAddress);
        uint256 amount = source.balanceOf(address(this));

        require(amount > 0, "Amount must be greater than 0");

        if (tokenAddress != sourceTokenAddress) {
            amount = _swapTokensAndTransfer(sourceTokenAddress, tokenAddress, amount, to, swapper, swapData);
        } else {
            source.safeTransfer(to, amount);
        }

        payable(to).transfer(address(this).balance);
    }

    function _swapTokensAndTransfer(
        address fromToken,
        address toToken,
        uint256 amount,
        address recipient,
        address swapper,
        bytes memory swapData
    ) internal returns (uint256) {
        IERC20Upgradeable fromAsset = IERC20Upgradeable(fromToken);
        IERC20Upgradeable toAsset = IERC20Upgradeable(toToken);
        
        fromAsset.safeApprove(swapper, amount);
        uint256 toAssetPreviousBalance = toAsset.balanceOf(address(this));
        swapper.call(swapData); 
        uint256 toAssetCurrentBalance = toAsset.balanceOf(address(this));
        require(toAssetCurrentBalance - toAssetPreviousBalance > 0, "Swap failed");

        toAsset.safeTransfer(recipient, toAssetCurrentBalance - toAssetPreviousBalance);
    }

    receive() external payable {}
}