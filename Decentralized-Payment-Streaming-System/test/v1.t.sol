// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "forge-std/Test.sol";
import "../contracts/v1.sol";
import "../test/reentrancyAttack.sol";

contract DPSS1TestWrapper is DPSS1 {
    function getStream(uint256 id) external view returns (Stream memory) {
        return streams[id];
    }
}

contract streamTest is Test {
    DPSS1TestWrapper public dpss1;
    Attack public attack;
    address payer;
    address payable recipient;

    uint256 amount;
    uint256 startTime;
    uint256 duration;
    uint256 rate;
    bool active;
    uint256 releasedAmount;

    function setUp() external {
        dpss1 = new DPSS1TestWrapper();
        attack = new Attack(address(dpss1));

        payer = makeAddr("payer");
        recipient = payable(makeAddr("recipient"));
        vm.deal(payer, 1_000_000 ether);
    }

    function setConditions(uint256 period, uint256 _value) public {
        vm.prank(payer);
        dpss1.createStream{value: _value}(recipient, period);
    }

    function testCreateStream() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);

        assertEq(dpss1.streamID(), 1);
        DPSS1.Stream memory stream = dpss1.getStream(0);
        uint256 expectedRate = value / period;
        assertEq(stream.rate, expectedRate);
        assertEq(stream.recipient, recipient);
        assertEq(stream.payer, payer);
        assertEq(stream.amount, 1 ether);
        assertEq(stream.startTime, block.timestamp);
        assertEq(stream.duration, 5 days);
        assertEq(stream.active, true);
        assertEq(stream.releasedAmount, 0);
    }

    function testWithdraw() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);

        vm.warp(block.timestamp + 2 days);
        vm.prank(recipient);
        dpss1.withdraw(0);

        DPSS1.Stream memory stream = dpss1.getStream(0);
        assertApproxEqAbs(
            stream.releasedAmount,
            (2 days * value) / period,
            0.0001 ether
        );
    }

    function testOnlyRecipientCanWithdraw() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);

        vm.warp(block.timestamp + 2 days);
        vm.prank(payer);
        vm.expectRevert(
            abi.encodeWithSelector(DPSS1.NoStreamOrNotRecipient.selector)
        );
        dpss1.withdraw(0);
    }

    function testStreamNotFound() external {
        vm.expectRevert(
            abi.encodeWithSelector(DPSS1.NoStreamOrNotRecipient.selector)
        );
        dpss1.withdraw(0);
    }

    function testStreamTimeEnded() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);

        vm.warp(block.timestamp + 6 days);
        vm.prank(payer);
        vm.expectRevert(abi.encodeWithSelector(DPSS1.StreamTimeEnded.selector));
        dpss1.cancelStream(0);
    }

    function testNothingToWithdraw() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(recipient);
        dpss1.withdraw(0);
        vm.expectRevert(
            abi.encodeWithSelector(DPSS1.NothingToWithdraw.selector)
        );
        dpss1.withdraw(0);
    }

    function testRecipientCannotCancelStream() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditions(period, value);
        vm.startPrank(recipient);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert(
            abi.encodeWithSelector(DPSS1.NoStreamOrNotThePayer.selector)
        );
        dpss1.cancelStream(0);
    }

    function testStreamWithZeroDuration() external {
        uint256 value = 1 ether;
        uint256 period = 0;
        vm.expectRevert(
            abi.encodeWithSelector(DPSS1.NotValideStreamDuration.selector)
        );
        setConditions(period, value);
    }

    function testReentrancyAttack() external {
        uint256 value = 3 ether;
        uint256 period = 2 days;
        vm.prank(payer);
        dpss1.createStream{value: value}(payable(address(attack)), period);
        vm.warp(block.timestamp + 1 days);
        vm.prank(address(attack));
        vm.expectRevert(bytes("ETH transfer failed"));
        dpss1.withdraw(0);
    }

    function testLargeAmountStream() external {
        uint256 value = 99999 ether;
        uint256 period = 5 days;
        setConditions(period, value);
        DPSS1.Stream memory stream = dpss1.getStream(0);
        uint256 expectedRate = value / period;
        assertEq(stream.rate, expectedRate);
        assertEq(stream.recipient, recipient);
        assertEq(stream.amount, value);
        vm.warp(block.timestamp + 2 days);
        vm.prank(recipient);
        dpss1.withdraw(0);
        DPSS1.Stream memory stream1 = dpss1.getStream(0);
        assertApproxEqAbs(
            stream1.releasedAmount,
            (2 days * value) / period,
            0.0001 ether
        );

        assertApproxEqAbs(
            recipient.balance,
            (2 days * value) / period,
            0.0001 ether
        );
    }

    function testStreamWithMaximumDuration() external {
        uint256 value = 1 ether;
        uint256 period = type(uint32).max;
        setConditions(period, value);
        DPSS1.Stream memory stream = dpss1.getStream(0);
        uint256 expectedRate = value / period;
        assertEq(stream.rate, expectedRate);
        assertEq(stream.recipient, recipient);
        assertEq(stream.amount, value);
        vm.warp(block.timestamp + 200 days);
        vm.prank(recipient);
        dpss1.withdraw(0);
        DPSS1.Stream memory stream1 = dpss1.getStream(0);
        assertApproxEqAbs(
            stream1.releasedAmount,
            (200 days * value) / period,
            0.0001 ether
        );

        assertApproxEqAbs(
            recipient.balance,
            (200 days * value) / period,
            0.0001 ether
        );
    }
}
