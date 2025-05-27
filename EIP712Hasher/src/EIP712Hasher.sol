// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Hasher {
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(uint256 => mapping(bool => uint256)) public voteResults;
    struct Vote {
        address voter;
        uint256 proposalId;
        bool support;
    }

    bytes32 internal constant VOTE_TYPEHASH =
        keccak256("Vote(address voter,uint256 proposalId,bool support)");
    bytes32 internal constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    string constant NAME = "MyDAO";
    string constant VERSION = "1";

    function getDomainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(NAME)),
                    keccak256(bytes(VERSION)),
                    block.chainid,
                    address(this)
                )
            );
    }

    function getStructHash(
        address voter,
        uint256 proposalId,
        bool support
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(VOTE_TYPEHASH, voter, proposalId, support));
    }

    function getMessageHash(
        address voter,
        uint256 proposalId,
        bool support
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    getDomainSeparator(),
                    getStructHash(voter, proposalId, support)
                )
            );
    }

    function voteBySig(
        address voter,
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = getMessageHash(voter, proposalId, support);

        address recovered = ECDSA.recover(digest, v, r, s);

        require(recovered == voter, "Invalid signature");
        require(!hasVoted[voter][proposalId], "Already voted");

        hasVoted[voter][proposalId] = true;
        voteResults[proposalId][support] += 1;
    }
}
