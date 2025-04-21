// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "forge-std/Test.sol";
import "../contracts/EscrowFactory.sol";
import "../contracts/Escrow.sol";
pragma solidity 0.8.21;

contract factoryTest is Test {
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

    function setUp() external {
        user = address(0x4);
        seller = payable(address(0x1));
        FeeRecipient = payable(address(0x5));
        arbitrator = address(0x2);
        buyer = address(0x3);
        amount = 1 ether;
        duration = 7 days;
        feeAmount = 5;

        factory = new Factory();
    }

    function testCreateEscrow() public {
        vm.startPrank(seller);

        vm.expectEmit(true, true, true, true);

        emit EscrowCreated(
            seller,
            seller,
            buyer,
            arbitrator,
            duration,
            feeAmount
        );
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(seller);

        assertEq(escrows.length, 1);
    }

    function testUserCanCreateMultipleEscrows() external {
        vm.startPrank(user);
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            duration,
            feeAmount
        );
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(user);
        assertEq(escrows.length, 2);
    }

    function testDifferentUsersHaveSeparateEscrowLists() external {
        vm.prank(seller);
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            duration,
            feeAmount
        );
        vm.prank(user);
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            duration,
            feeAmount
        );
        address[] memory escrows = factory.getUserEscrows(user);
        assertEq(escrows.length, 1);
        address[] memory escrows2 = factory.getUserEscrows(seller);
        assertEq(escrows2.length, 1);
    }

    function testFuzz_RevertIfDeadlineIsInPast(uint32 fuzzedDeadline) external {
        vm.assume(fuzzedDeadline < 3000);

        vm.expectRevert();
        factory.createEscrow(
            seller,
            arbitrator,
            FeeRecipient,
            buyer,
            amount,
            fuzzedDeadline,
            feeAmount
        );
    }
}
