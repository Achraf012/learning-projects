// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/forge-std/src/Test.sol";
import "../src/Lab2_BridgeMessageVerifier-2-.sol";
import "../src/Lab4_BridgeTarget.sol";

contract BridgeTargetTest is Test {
    uint256 validatorPk;
    uint256 hackerPk;
    BridgeMessageVerifier verifier;
    BridgeTarget target;
    address user;

    function setUp() public {
        validatorPk = 0x1adf;
        hackerPk = 0x2dc;
        user = makeAddr("user");
        vm.deal(user, 10 ether);
        address validator = vm.addr(validatorPk);
        verifier = new BridgeMessageVerifier(validator);
        target = new BridgeTarget(validator, verifier);
    }

    function testClaim_Successful() public {
        uint256 amount = 1 ether;
        uint256 nonce = 1;
        uint chainId = 1;
        bytes32 messageHash = verifier.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPk, ethHash);
        vm.prank(user);
        target.claim(user, amount, nonce, chainId, v, r, s);
        assertEq(target.claimed(user), 1 ether);
        bytes32 key = keccak256(abi.encodePacked(nonce, chainId));
        assertTrue(target.processedMessage(key));
    }

    function testClaim_InvalidSignature() public {
        uint256 amount = 1 ether;
        uint256 nonce = 1;
        uint chainId = 1;
        bytes32 messageHash = verifier.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(hackerPk, ethHash);
        vm.expectRevert(BridgeTarget.InvalidSignature.selector);
        vm.prank(user);
        target.claim(user, amount, nonce, chainId, v, r, s);
    }

    function testClaim_ReplayFails() public {
        uint256 amount = 1 ether;
        uint256 nonce = 1;
        uint chainId = 1;
        bytes32 messageHash = verifier.getMessageHash(
            user,
            amount,
            nonce,
            chainId
        );
        bytes32 ethHash = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPk, ethHash);
        vm.startPrank(user);
        target.claim(user, amount, nonce, chainId, v, r, s);
        assertEq(target.claimed(user), 1 ether);
        bytes32 key = keccak256(abi.encodePacked(nonce, chainId));
        assertTrue(target.processedMessage(key));
        vm.expectRevert();
        target.claim(user, amount, nonce, chainId, v, r, s);
    }
}
