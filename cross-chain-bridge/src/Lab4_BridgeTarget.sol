// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../src/Lab2_BridgeMessageVerifier-2-.sol";

contract BridgeTarget {
    using ECDSA for bytes32;
    BridgeMessageVerifier verifier;
    address validator;
    mapping(bytes32 => bool) public processedMessage;
    mapping(address => uint256) public claimed;
    error NonceAlreadyProcessed();
    error InvalidSignature();
    event Claimed(
        address indexed user,
        uint256 amount,
        uint256 nonce,
        uint256 chainId
    );

    constructor(address _validator, BridgeMessageVerifier _verifier) {
        validator = _validator;
        verifier = _verifier;
    }

    function claim(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 key = keccak256(abi.encodePacked(nonce, chainId));
        if (processedMessage[key]) {
            revert NonceAlreadyProcessed();
        }
        bytes32 messageHash = verifier.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = verifier.getEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethHash, v, r, s);
        if (signer != validator) revert InvalidSignature();
        else {
            processedMessage[key] = true;
            claimed[user] += amount;
        }
        emit Claimed(user, amount, nonce, chainId);
    }
}
