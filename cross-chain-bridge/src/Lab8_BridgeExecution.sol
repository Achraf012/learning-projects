// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BridgeEIP712 is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    address[] validators;
    struct digestMessage {
        address user;
        uint256 amount;
        uint256 nonce;
        uint256 sourceChainId;
        uint256 targetChainId;
    }
    mapping(address => bool) public isValidator;
    mapping(bytes32 => bool) processed;
    mapping(address => uint256) userNonce;
    uint256 requiredSignatures;
    event BridgeRequest(
        address indexed user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId,
        bytes32 digestHash
    );
    event BridgeClaimed(
        address indexed user,
        uint256 amount,
        uint256 nonce,
        uint256 sourceChainId,
        uint256 targetChainId,
        bytes32 digestHash
    );
    bytes32 public constant MESSAGE_TYPEHASH =
        keccak256(
            "digestMessage(address user,uint256 amount,uint256 nonce,uint256 sourceChainId,uint256 targetChainId)"
        );

    constructor(
        address _token
    ) EIP712("BridgeMultiValidator", "1") Ownable(msg.sender) {
        token = IERC20(_token);
    }

    function setValidators(
        address[] memory _validators,
        uint256 _threshold
    ) external onlyOwner {
        // ill use this just because im learning logic not because its the best thing to do so its for tests only
        // making a validatorVersion mapping will do better for big number of validators to use less gas
        for (uint256 i = 0; i < validators.length; i++) {
            isValidator[validators[i]] = false;
        }
        validators = _validators;
        requiredSignatures = _threshold;
        for (uint256 i = 0; i < _validators.length; i++) {
            isValidator[_validators[i]] = true;
        }
    }

    function _hashBridgeMessage(
        digestMessage memory message
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MESSAGE_TYPEHASH,
                    message.user,
                    message.amount,
                    message.nonce,
                    message.sourceChainId,
                    message.targetChainId
                )
            );
    }

    function _digest(
        digestMessage memory message
    ) internal view returns (bytes32) {
        bytes32 structHash = _hashBridgeMessage(message);
        return _hashTypedDataV4(structHash);
    }

    function verifySignatures(
        digestMessage memory message,
        bytes[] memory signatures
    ) public view returns (bool) {
        bytes32 digestHash = _digest(message);
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

    function sendTokens(uint256 _amount, uint256 _targetChainId) external {
        uint256 currentNonce = userNonce[msg.sender];
        digestMessage memory message = digestMessage({
            user: msg.sender,
            amount: _amount,
            nonce: currentNonce,
            sourceChainId: block.chainid,
            targetChainId: _targetChainId
        });
        userNonce[msg.sender] = currentNonce + 1;
        bytes32 hashedMessage = _digest(message);
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        emit BridgeRequest(
            msg.sender,
            _amount,
            currentNonce,
            block.chainid,
            _targetChainId,
            hashedMessage
        );
    }

    function claimTokens(
        digestMessage memory message,
        bytes[] calldata signatures
    ) external {
        bytes32 digestHash = _digest(message);
        if (processed[digestHash]) revert("already proccessed message");
        bool signed = verifySignatures(message, signatures);
        require(signed, "invalid signatures");
        processed[digestHash] = true;
        IERC20(token).safeTransfer(message.user, message.amount);
        emit BridgeClaimed(
            message.user,
            message.amount,
            message.nonce,
            message.sourceChainId,
            message.targetChainId,
            digestHash
        );
    }
}
