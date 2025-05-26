// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EIP712Hasher {
    struct Vote {
        address voter;
        uint256 proposalId;
        bool support;
    }

    bytes32 constant VOTE_TYPEHASH =
        keccak256("Vote(address voter,uint256 proposalId,bool support)");
    bytes32 constant DOMAIN_TYPEHASH =
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
}
