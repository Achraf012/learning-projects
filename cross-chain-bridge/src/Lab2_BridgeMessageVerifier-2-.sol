// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract BridgeMessageVerifier {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;
    address public validator;
    // just storing which nonces have already been used. --no replay attack--
    mapping(uint256 => bool) public processedNonces;
    error NonceAlreadyUsed();

    constructor(address _validator) {
        validator = _validator;
    }

    function getMessageHash(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 chainId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, amount, nonce, chainId));
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) public pure returns (bytes32) {
        return messageHash.toEthSignedMessageHash();
    }

    function verify(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 chainId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        if (processedNonces[nonce] == true) {
            revert NonceAlreadyUsed();
        }
        bytes32 messageHash = getMessageHash(user, amount, nonce, chainId);
        bytes32 ethSigned = getEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSigned, v, r, s);
        processedNonces[nonce] = true;
        return signer == validator;
    }
}
