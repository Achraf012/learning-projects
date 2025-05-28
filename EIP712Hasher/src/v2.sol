// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

contract hasher is EIP712 {
    constructor() EIP712("achraf", "1") {}

    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(bool => uint256)) public voteResults;
    mapping(address => uint256) public nonces;
    struct vote {
        address voter;
        uint256 Id;
        bool agree;
        uint256 nonce;
        uint256 deadline;
    }
    bytes32 internal constant VOTE_TYPEHASH =
        keccak256(
            "vote(address voter,uint256 Id,bool agree , uint256 nonce , uint256 deadline)"
        );

    function voteBySig(
        address voter,
        uint256 id,
        bool agree,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp < deadline, "Signature Expired");
        bytes32 structHash = (
            keccak256(
                abi.encode(VOTE_TYPEHASH, voter, id, agree, deadline, nonce)
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address recovered = ECDSA.recover(digest, v, r, s);
        require(recovered == voter, "Invalid signature");
        require(!hasVoted[voter][id], "Already voted");

        hasVoted[voter][id] = true;
        voteResults[id][agree] += 1;
        nonces[voter]++;
    }
}
