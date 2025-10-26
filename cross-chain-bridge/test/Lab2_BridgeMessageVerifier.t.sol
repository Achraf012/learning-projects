// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/forge-std/src/Test.sol";
import "../src/Lab2_BridgeMessageVerifier.sol";

contract Lab2_BridgeMessageVerifierTest is Test {
    BridgeMessageVerifier bridge;
    uint256 validatorPK;
    uint256 hackerPK;
    address validator;

    function setUp() public {
        validatorPK = 0xa1234;
        hackerPK = 0xb1234;
        validator = vm.addr(validatorPK);
        bridge = new BridgeMessageVerifier(validator);
    }

    function testValidatorSignature() public view {
        address user = address(0x123);
        uint256 amount = 100;
        uint256 nonce = 1;
        uint256 chainId = 1;
        bytes32 messageHash = bridge.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = bridge.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPK, ethHash);
        bool valid = bridge.verify(user, amount, nonce, chainId, v, r, s);
        assertTrue(valid, "Validator signature should be valid");
    }

    function testHackerSignatureFails() public view {
        address user = address(0x123);
        uint256 amount = 100;
        uint256 nonce = 1;
        uint256 chainId = 1;
        bytes32 messageHash = bridge.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = bridge.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(hackerPK, ethHash);
        bool valid = bridge.verify(user, amount, nonce, chainId, v, r, s);
        assertFalse(valid, "Hacker signature should fail");
    }
}
