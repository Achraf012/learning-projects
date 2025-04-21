// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "forge-std/Test.sol";
import "../contracts/Escrow.sol";
import "forge-std/console.sol";
pragma solidity 0.8.21;

contract EscrowTest is Test {
    Escrow public escrow;
    address buyer;
    address payable seller;
    address payable feeRecipient;
    address arbitrator;
    uint128 amount;
    uint32 deadline;
    uint32 duration;
    uint16 feeAmount;

    function setUp() public {
        // feeRecipient = payable(makeAddr("feeRecipient"));
        buyer = makeAddr("buyer");
        seller = payable(makeAddr("seller"));
        arbitrator = makeAddr("arbitrator");
        vm.deal(buyer, 1 ether);
        vm.deal(seller, 1 ether);
        amount = 1 ether;
        duration = 3700;
        // feeAmount = 3;

        deadline = uint32(block.timestamp + duration);

        escrow = new Escrow(
            seller,
            arbitrator,
            feeRecipient,
            buyer,
            amount,
            deadline,
            feeAmount
        );
    }

    function testBuyerCanDeposit() external {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();
        assertEq(address(escrow).balance, 1 ether);
        assertEq(uint(escrow.getState()), uint(Escrow.EscrowState.Deposited));
    }

    function testOnlyBuyerCanDeposit() external {
        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(Escrow.NotTheBuyer.selector, buyer, seller)
        );
        escrow.deposit{value: 1 ether}();
    }

    function testonlyBuyerCanApprove() external {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.prank(seller);
        vm.expectRevert(
            abi.encodeWithSelector(Escrow.NotTheBuyer.selector, buyer, seller)
        );
        escrow.approve();
    }

    function testBuyerCanApprove() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        escrow.approve();
        assertEq(uint(escrow.getState()), uint(Escrow.EscrowState.Approved));
    }

    function testArbitratorCanResolveDispute() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        escrow.openDispute();
        vm.stopPrank();
        vm.prank(arbitrator);
        escrow.resolveDispute(seller);
        assertEq(address(seller).balance, 2 ether);
    }

    function testCannotApproveReleaseAfterDispute() external {
        vm.startPrank(buyer);
        vm.expectRevert(bytes("Cannot dispute at this stage"));
        escrow.openDispute();
        vm.stopPrank();
    }

    function testDepositingFundsUpdatestheEscrowBalance() external {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();
        assertEq(address(escrow).balance, 1 ether);
    }

    function testCannotResolveDisputeBeforeItIsDisputed() external {
        vm.prank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.prank(arbitrator);
        vm.expectRevert(Escrow.NotDisputed.selector);
        escrow.resolveDispute(seller);
    }

    function testCannotApproveAfterDeadline() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 3800);
        vm.expectRevert(Escrow.DeadlinePassed.selector);
        escrow.approve();
    }

    function testCanOpenDisputeBeforeDeadline() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 8);
        escrow.openDispute();
        assertEq(uint(escrow.getState()), uint(Escrow.EscrowState.Disputed));
    }

    function testArbitratorCanResolveAfterDeadline() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 8);
        escrow.openDispute();
        vm.stopPrank();
        vm.prank(arbitrator);
        escrow.resolveDispute(seller);
        assertEq(uint(escrow.getState()), uint(Escrow.EscrowState.Resolved));
    }

    function testCannotDepositZeroEther() external {
        vm.startPrank(buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                Escrow.PriceProblem.selector,
                0 ether,
                1 ether
            )
        );
        escrow.deposit{value: 0 ether}();
    }

    function testCannotDisputeTwice() external {
        vm.startPrank(buyer);
        escrow.deposit{value: 1 ether}();
        vm.warp(block.timestamp + 8);
        escrow.openDispute();
        vm.expectRevert(bytes("Cannot dispute at this stage"));
        escrow.openDispute();
    }

    function testFuzz_CannotApproveUnlessBuyer(address caller) external {
        vm.assume(caller != buyer);
        vm.prank(caller);
        vm.expectRevert();
        escrow.approve();
    }
}
