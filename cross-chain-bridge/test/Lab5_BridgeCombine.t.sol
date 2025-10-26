// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "forge-std/Test.sol";
import "../src/Lab3_BridgeCore.sol";
import "../src/Lab4_BridgeTarget.sol";
import "../src/Lab2_BridgeMessageVerifier-2-.sol";

contract BridgeCombineTest is Test {
    address validator;
    uint256 validatorPk;
    BridgeMessageVerifier verifier;
    BridgeCore core;
    BridgeTarget target;
    address user;

    function setUp() public {
        validatorPk = 0x1cd;
        validator = vm.addr(validatorPk);
        verifier = new BridgeMessageVerifier(validator);
        core = new BridgeCore(validator, verifier);
        target = new BridgeTarget(validator, verifier);
        user = makeAddr("user");
        vm.deal(user, 10 ether);
    }

    function testFullBridgeFlow() public {
        vm.prank(user);
        core.deposit{value: 2 ether}(2 ether, 1, block.chainid);
        bytes32 messageHash = verifier.getMessageHash(
            user,
            2 ether,
            1,
            block.chainid
        );
        bytes32 ethHash = verifier.getEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(validatorPk, ethHash);
        vm.prank(user);
        target.claim(user, 2 ether, 1, block.chainid, v, r, s);
        bytes32 key = keccak256(abi.encodePacked(uint256(1), block.chainid));
        assertTrue(target.processedMessage(key));
        assertEq(target.claimed(user), 2 ether);
    }
}
