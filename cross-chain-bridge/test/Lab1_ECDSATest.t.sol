// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/forge-std/src/Test.sol";
import "src/Lab1-SignatureVerifier.sol";

contract Lab1_ECDSATest is Test {
    SignatureVerifier verifier;
    uint256 validatorPK;
    uint256 hackerPK;
    address validator;

    function setUp() public {
        validatorPK = 0xA123;
        hackerPK = 0xB123;
        validator = vm.addr(validatorPK);
        verifier = new SignatureVerifier(validator);
    }

    function testVerifySig() public view {
        bytes32 messageHash = keccak256("Achraf Bridge Lab 1");
        bytes32 ethSigHash = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPK, ethSigHash);
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(hackerPK, ethSigHash);
        bool valid = verifier.verify(messageHash, v, r, s);
        bool valid2 = verifier.verify(messageHash, a, b, c);
        assertTrue(valid);
        assertFalse(valid2);
    }
}
