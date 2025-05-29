// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../src/v2.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

contract hasherTest is Hasher {
    function getTypeHash() external pure returns (bytes32) {
        return VOTE_TYPEHASH;
    }

    function gethashTypedDataV4(
        bytes32 structHash
    ) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }
}

contract testV2 is Test {
    hasherTest hasher;
    address user;
    bool agree;
    uint256 id;

    function setUp() public {
        hasher = new hasherTest();
        user = address(0x123);
    }

    function testVoteBySig() public {
        // Private key for test signer (any uint256)
        uint256 privateKey = 0xA11CE;

        // Derive the signer address from private key
        address voter = vm.addr(privateKey);

        id = 1;
        agree = true;
        uint256 nonce = hasher.nonces(voter);
        uint256 deadline = block.timestamp + 1 hours;

        // 1. Recreate the struct hash off-chain exactly as the contract does
        bytes32 structHash = keccak256(
            abi.encode(hasher.getTypeHash(), voter, id, agree, deadline, nonce)
        );

        // 2. Get the EIP712 digest to sign
        bytes32 digest = hasher.gethashTypedDataV4(structHash);

        // 3. Sign digest with the private key using Foundry's cheatcode
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // 4. Call voteBySig with generated signature parts
        hasher.voteBySig(voter, id, agree, deadline, nonce, v, r, s);

        // 5. Assert that the vote was counted correctly
        assertTrue(hasher.hasVoted(voter, id));
        assertEq(hasher.voteResults(id, agree), 1);
        assertEq(hasher.nonces(voter), nonce + 1);
    }
}
