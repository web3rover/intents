// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

contract IntentSender {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///////////////////////////////////////////////////
    /////////////// STG Configuration ////////////////
    /////////////////////////////////////////////////

    // destinationChainID => true
    mapping (uint256 => bool) public destinationConfigured;

    // destinationChainId => destinationPoolId (ex: USDC pool ID)
    mapping (uint256 => uint256) public destinationPoolId;

    // chain id of the chain where the intent was created
    uint256 public sourceChainId; 

    // pool id of the pool where the intent was created (ex: USDC pool ID)
    uint256 public sourcePoolId;

    // address of the token that can be bridged (ex: USDC)
    address public sourceTokenAddress;

    // address of the STG router contract
    address public router;

    constructor(
        uint256 _sourceChainId,
        uint256 _sourcePoolId,
        address _sourceTokenAddress,
        address _router
    ) {
        sourceChainId = _sourceChainId;
        sourcePoolId = _sourcePoolId;
        sourceTokenAddress = _sourceTokenAddress;
        router = _router;
    }

    function setDestination(uint256 _destinationChainId, uint256 _destinationPoolId) external {
        destinationConfigured[_destinationChainId] = true;
        destinationPoolId[_destinationChainId] = _destinationPoolId;
    }

    function sendIntent(uint256 _destinationChainId, address _sourceToken, uint256 _amount) external {
        require(destinationConfigured[_destinationChainId], "Destination not configured");
        require(_amount > 0, "Amount must be greater than 0");
        require(_sourceToken == sourceTokenAddress, "Token not supported");

        IERC20Upgradeable asset = IERC20Upgradeable(_sourceToken);
        asset.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
