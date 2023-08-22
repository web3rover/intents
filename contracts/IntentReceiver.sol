// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract IntentReceiver {
    bool public called = false;

    constructor() {
        console.log("IntentReceiver constructor");
    }

    function receiveIntent(
        address tokenAddress,
        address to,
        uint256 amount
    ) payable external {
        called = true;
    }

    receive() external payable {}
}