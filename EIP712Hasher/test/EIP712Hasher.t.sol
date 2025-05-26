// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "lib/forge-std/src/Test.sol";
import "../src/EIP712Hasher.sol";
import "lib/forge-std/src/console.sol";

contract EIP712HasherTest is Test {
    EIP712Hasher hasher;

    address voter;
    uint256 proposalId;
    bool support;

    function setUp() public {
        hasher = new EIP712Hasher();

        voter = address(0xABCD);
        proposalId = 42;
        support = true;
    }

    function testPrintStructHash() public view {
        bytes32 structHash = hasher.getStructHash(voter, proposalId, support);
        console.log("Struct Hash:");
        console.logBytes32(structHash);
    }

    function testPrintDomainSeparator() public view {
        bytes32 domainSeparator = hasher.getDomainSeparator();
        console.log("Domain Separator:");
        console.logBytes32(domainSeparator);
    }

    function testPrintMessageHash() public view {
        bytes32 messageHash = hasher.getMessageHash(voter, proposalId, support);
        console.log("Message Hash (to sign):");
        console.logBytes32(messageHash);
    }

    function testSignAndRecover() public {
        uint256 privateKey = 0xA11CE;
        address signer = vm.addr(privateKey);
        voter = signer;

        bytes32 digest = hasher.getMessageHash(voter, proposalId, support);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        address recovered = ecrecover(digest, v, r, s);

        console.log("Expected Signer: ", signer);
        console.log("Recovered Signer:", recovered);

        assertEq(recovered, signer);
    }
}
