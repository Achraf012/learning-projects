// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.29;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/positionAMM.sol";

contract testAMM is Test {
    PositionAMM public amm;
    address user1;
    address user2;

    function setUp() public {
        amm = new PositionAMM();
        user1 = makeAddr("user");
        user2 = makeAddr("user2");
    }

    function test_mint() public {
        amm.moveTick(20);
        vm.prank(user1);
        amm.mintPosition(100, 5, 10);
        assertEq(amm.activeLiquidity(), 0);

        int256 l1 = amm.liquidityDeltas(5);
        int256 l2 = amm.liquidityDeltas(10);

        assertEq(l1, 100);
        assertEq(l2, -100);
    }

    function test_burn() public {
        amm.moveTick(15);
        vm.startPrank(user1);
        amm.mintPosition(100, 5, 20);
        assertEq(amm.activeLiquidity(), 100);

        amm.burnPosition(0);

        int256 l1 = amm.liquidityDeltas(5);
        int256 l2 = amm.liquidityDeltas(20);

        assertEq(l1, 0);
        assertEq(l2, 0);
    }

    function test_moveTick() public {
        amm.moveTick(1);
        vm.prank(user1);
        amm.mintPosition(100, 5, 20);
        vm.prank(user2);
        amm.mintPosition(100, 6, 30);
        amm.moveTick(35);
        assertEq(amm.activeLiquidity(), 0);
        amm.moveTick(7);
        assertEq(amm.activeLiquidity(), 200);
        amm.moveTick(1);
        assertEq(amm.activeLiquidity(), 0);
    }
}
