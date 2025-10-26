// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/forge-std/src/Test.sol";
import "../src/Lab3_BridgeCore.sol";
import "../src/Lab2_BridgeMessageVerifier-2-.sol";

contract BridgeCore_v1_test is Test {
    BridgeCore bridge;
    address validator;
    BridgeMessageVerifier verifier;
    address user = makeAddr("user");

    event Deposit(
        address indexed from,
        uint256 amount,
        uint256 nonce,
        uint256 chainId
    );

    function setUp() public {
        validator = makeAddr("validator");
        verifier = new BridgeMessageVerifier(validator);
        bridge = new BridgeCore(validator, verifier);
        vm.deal(user, 10 ether);
    }

    function testDeposit_WrongAmount() public {
        vm.expectRevert();
        vm.prank(user);
        bridge.deposit{value: 0.5 ether}(1 ether, 1, 1);
        bool valid = bridge.usedNonces(user, 1);
        assertFalse(valid);
    }

    function testDeposit_successful() public {
        vm.prank(user);
        vm.expectEmit(true, false, false, true);
        emit Deposit(user, 1 ether, 1, 1);
        bridge.deposit{value: 1 ether}(1 ether, 1, 1);
        assertEq(bridge.balances(user), 1 ether);
        bool passed = bridge.usedNonces(user, 1);
        assertTrue(passed);
    }

    function testDeposit_RevertIfNonceUsed() public {
        vm.startPrank(user);
        bridge.deposit{value: 1 ether}(1 ether, 1, 1);

        vm.expectRevert();
        bridge.deposit{value: 1 ether}(1 ether, 1, 1);
        assertEq(bridge.balances(user), 1 ether);
    }
}
