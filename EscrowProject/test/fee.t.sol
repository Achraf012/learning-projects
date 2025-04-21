// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "forge-std/Test.sol";
import "../contracts/EscrowFactory.sol";
import "../contracts/Escrow.sol";
import "../src/Rejection.sol";
pragma solidity 0.8.21;

contract feeTest is Test {
    event EscrowCreated(
        address indexed owner,
        address seller,
        address buyer,
        address arbitrator,
        uint32 duration,
        uint16 fee
    );
    address user;
    address payable seller;
    address payable FeeRecipient;
    address arbitrator;
    address buyer;
    uint128 amount;
    uint32 duration;
    uint16 feeAmount;

    Factory public factory;
    Escrow public escrow;
    RejectsEther public rejection;
    event FeeRecipientSet(address feeRecipient);

    function setUp() external {
        user = address(0x4);
        // vm.deal(buyer, 1 ether);
        seller = payable(address(0x1));
        // FeeRecipient = payable(address(0x5));
        arbitrator = address(0x2);
        buyer = address(0x3);
        amount = 1 ether;
        duration = 7 days;
        feeAmount = 3;

        factory = new Factory();
        rejection = new RejectsEther();
    }

    function test_CorrectFeeIsSet() external {
        vm.startPrank(payable(user));

        factory.createEscrow(
            seller,
            arbitrator,
            payable(user),
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(user);
        Escrow e = Escrow(payable(escrows[0]));
        assertEq(feeAmount, e.getFeeAmount());
    }

    function test_FeeIsSentToFeeRecipient_OnReleaseFunds() external {
        vm.startPrank(payable(user));
        uint128 fee = uint128((uint256(amount) * feeAmount) / 100);

        factory.createEscrow(
            seller,
            arbitrator,
            payable(user),
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(user);
        Escrow e = Escrow(payable(escrows[0]));
        vm.stopPrank();
        vm.deal(buyer, 1.01 ether);
        vm.startPrank(buyer);
        e.deposit{value: amount}();
        assertEq(address(e).balance, amount);
        e.approve();
        vm.stopPrank();
        vm.prank(seller);
        e.releaseFunds();

        assertEq(seller.balance, amount - fee);
        assertEq(user.balance, fee);
    }

    function test_RevertsIfFeeTransferFails() external {
        vm.startPrank(payable(user));

        factory.createEscrow(
            seller,
            arbitrator,
            payable(rejection),
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(user);
        Escrow e = Escrow(payable(escrows[0]));
        vm.stopPrank();
        vm.deal(buyer, 1.01 ether);
        vm.startPrank(buyer);
        e.deposit{value: amount}();
        e.approve();
        vm.stopPrank();
        vm.prank(seller);
        vm.expectRevert(bytes("transfer fee failed"));
        e.releaseFunds();
    }

    function testFuzz_RevertIfFeeBelowMinimum() external {
        vm.startPrank(payable(user));
        uint16 fuzzFeeAmount;
        vm.assume(fuzzFeeAmount < 1);
        vm.expectRevert();
        factory.createEscrow(
            seller,
            arbitrator,
            payable(rejection),
            buyer,
            amount,
            duration,
            fuzzFeeAmount
        );
    }

    function test_EmitFeeRecipientSetEvent() external {
        vm.startPrank(payable(user));
        vm.expectEmit(true, false, false, false);
        emit FeeRecipientSet(payable(rejection));
        factory.createEscrow(
            seller,
            arbitrator,
            payable(rejection),
            buyer,
            amount,
            duration,
            feeAmount
        );
    }
}
