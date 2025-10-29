// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract BridgeMultiValidator is Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    address[] validators;
    mapping(address => bool) isValidator;
    mapping(bytes32 => bool) processed;
    uint256 requiredSignatures;

    constructor() Ownable(msg.sender) {}

    function setValidators(
        address[] memory _validators,
        uint256 _threshold
    ) external onlyOwner {
        validators = _validators;
        requiredSignatures = _threshold;
        for (uint256 i = 0; i < _validators.length; i++) {
            isValidator[_validators[i]] = true;
        }
    }

    function getMessageHash(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId
    ) public pure returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(user, amount, nonce, sourceChainId, targetChainId)
        );
        return message.toEthSignedMessageHash();
    }

    function verifySignatures(
        bytes32 messageHash,
        bytes[] memory signatures
    ) public view returns (bool) {
        uint256 validCount = 0;
        address[] memory seen = new address[](validators.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(messageHash, signatures[i]);
            if (!isValidator[signer]) revert("Invalid signer");

            for (uint256 j = 0; j < validCount; j++) {
                if (seen[j] == signer) revert("Duplicate signer");
            }

            seen[validCount] = signer;
            validCount++;
        }

        return validCount >= requiredSignatures;
    }

    function claimTokensWithProof(
        address user,
        uint256 amount,
        uint256 sourceChainId,
        uint256 targetChainId,
        uint256 nonce,
        bytes[] calldata signatures
    ) external {
        bytes32 message = getMessageHash(
            user,
            amount,
            nonce,
            sourceChainId,
            targetChainId
        );
        if (processed[message]) revert("already proccessed message");
        bool signed = verifySignatures(message, signatures);
        require(signed, "invalid signatures");
        processed[message] = true;
        // after this confirmation -- we transfer or mint tokens -- no need for it now ,I only want to learn about how bridges work ( maybe ill add it later);
    }
}
