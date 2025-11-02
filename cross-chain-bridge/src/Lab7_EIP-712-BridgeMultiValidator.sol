// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract BridgeEIP712 is Ownable, EIP712 {
    address[] validators;
    mapping(address => bool) isValidator;
    mapping(bytes32 => bool) processed;
    uint256 requiredSignatures;
    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256(
            "BridgeMessage("
            "address user,uint256 amount,uint256 nonce,uint256 sourceChainId,uint256 targetChainId)"
        );

    constructor() EIP712("BridgeMultiValidator", "1") Ownable(msg.sender) {}

    function setValidators(
        address[] memory _validators,
        uint256 _threshold
    ) external onlyOwner {
        require(
            _validators.length > _threshold,
            "threshold cannot exceed number of validators."
        );
        validators = _validators;
        requiredSignatures = _threshold;
        for (uint256 i = 0; i < _validators.length; i++) {
            isValidator[_validators[i]] = true;
        }
    }

    function _hashBridgeMessage(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MESSAGE_TYPEHASH,
                    user,
                    amount,
                    nonce,
                    sourceChainId,
                    targetChainId
                )
            );
    }

    function digest(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId
    ) public view returns (bytes32) {
        bytes32 structHash = _hashBridgeMessage(
            user,
            amount,
            nonce,
            sourceChainId,
            targetChainId
        );
        return _hashTypedDataV4(structHash);
    }

    function verifySignatures(
        address user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId,
        bytes[] memory signatures
    ) public view returns (bool) {
        bytes32 digestHash = digest(
            user,
            amount,
            nonce,
            sourceChainId,
            targetChainId
        );
        uint256 validCount = 0;
        address[] memory seen = new address[](validators.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = ECDSA.recover(digestHash, signatures[i]);
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
        bytes32 digestHash = digest(
            user,
            amount,
            nonce,
            sourceChainId,
            targetChainId
        );
        if (processed[digestHash]) revert("already proccessed message");
        bool signed = verifySignatures(
            user,
            amount,
            nonce,
            sourceChainId,
            targetChainId,
            signatures
        );
        require(signed, "invalid signatures");
        processed[digestHash] = true;
        // after this confirmation -- we transfer or mint tokens -- no need for it now ,I only want to learn about how bridges work ( maybe ill add it later);
    }
}
