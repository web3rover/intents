// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "hardhat/console.sol";

import "./interfaces/IStargateRouter.sol";

contract IntentSender {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///////////////////////////////////////////////////
    /////////////// STG Configuration ////////////////
    /////////////////////////////////////////////////

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
    address public router;

    constructor(
        uint16 _sourceChainId,
        uint256 _sourcePoolId,
        address _sourceTokenAddress,
        address _router
    ) {
        sourceChainId = _sourceChainId;
        sourcePoolId = _sourcePoolId;
        sourceTokenAddress = _sourceTokenAddress;
        router = _router;
    }

    function setDestination(uint16 _destinationChainId, uint256 _destinationPoolId) external {
        destinationConfigured[_destinationChainId] = true;
        destinationPoolId[_destinationChainId] = _destinationPoolId;
    }

    function sendIntent(uint16 _destinationChainId, address _sourceToken, uint256 _amount) external {
        require(destinationConfigured[_destinationChainId], "Destination not configured");
        require(_amount > 0, "Amount must be greater than 0");
        require(_sourceToken == sourceTokenAddress, "Token not supported");

        _receiveAsset(_sourceToken, _amount);
        _approveAssetForTransfer(_sourceToken, _amount);

        uint256 fee = getCrossChainTransferFee(_destinationChainId, msg.sender);
        _transferCrossChain(
            _destinationChainId, 
            sourcePoolId, 
            destinationPoolId[_destinationChainId], 
            _amount, 
            msg.sender, 
            fee
        );
    }

    function _receiveAsset(address _token, uint256 _amount) internal {
        IERC20Upgradeable asset = IERC20Upgradeable(_token);
        asset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function _approveAssetForTransfer(address _token, uint256 _amount) internal {
        IERC20Upgradeable asset = IERC20Upgradeable(_token);
        asset.safeApprove(router, _amount);
    }

    function getCrossChainTransferFee(
        uint16 _destinationChainId,
        address _toAddress
    ) public returns (uint256 fee) {
        IStargateRouter router = IStargateRouter(router);
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
        IStargateRouter router = IStargateRouter(router);
        router.swap{ value: _fee }(
            _destinationChainId,
            _sourcePoolId,
            _destinationPoolId,
            payable(address(this)),
            _amount,
            _amount,
            IStargateRouter.lzTxObj(0, 0, "0x"),
            abi.encodePacked(_toAddress),
            "0x"
        );
    }
}
