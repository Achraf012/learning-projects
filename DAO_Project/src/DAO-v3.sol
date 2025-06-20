// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../src/DAO-v2.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DAO3 is DAO2, EIP712Upgradeable {
    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;
    bytes32 public constant VOTE_TYPEHASH =
        keccak256(
            "Vote (address voter ,uint256 proposalId ,bool support ,uint256 nonce,uint256 deadline)"
        );

    function initializeV2() public reinitializer(2) {
        __EIP712_init("DAO", "1");
    }

    constructor() {
        _disableInitializers();
    }

    function voteBySig(
        address voter,
        uint256 proposalId,
        bool support,
        uint256 deadline,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp <= deadline, "Signature expired");
        require(nonces[voter] == nonce, "Invalid nonce");

        bytes32 structHash = keccak256(
            abi.encode(
                VOTE_TYPEHASH,
                voter,
                proposalId,
                support,
                nonce,
                deadline
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        address recovered = ECDSA.recover(digest, v, r, s);
        require(recovered == voter, "Invalid signature");

        Proposal storage proposal = proposals[proposalId];

        if (block.timestamp >= proposal.deadline) revert VotingTimeEnded();
        if (proposal.voters[voter]) revert AlreadyVoted();

        uint256 weight = token.balanceOf(voter);
        require(weight > 0, "No tokens to vote with");

        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }

        proposal.voters[voter] = true;
        nonces[voter]++;

        emit Voted(proposalId, voter, support, weight);
    }
}
