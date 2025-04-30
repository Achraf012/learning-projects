// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../contracts/v2.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract DPSS2TestWrapper is DPSS2 {
    function getStream(uint256 id) external view returns (Stream memory) {
        return streams[id];
    }
}

contract DPSS2Test is Test, ReentrancyGuard {
    using SafeERC20 for IERC20;

    DPSS2TestWrapper public dpss2;
    address public payer;
    address payable public recipient;
    uint256 public amount;
    uint256 public duration;
    uint256 public streamID;
    ERC20Mock token;

    function setUp() public {
        dpss2 = new DPSS2TestWrapper();
        payer = makeAddr("payer");
        recipient = payable(makeAddr("recipient"));
        vm.deal(payer, 100 ether);
        token = new ERC20Mock("MockToken", "MTK");
        token.mint(payer, 1000 ether);
    }

    function setConditionsToETH(uint256 period, uint256 _value) public {
        vm.prank(payer);
        dpss2.createStream{value: _value}(recipient, period, address(0), 0);
    }

    function setConditionsToERC20(uint256 period, uint256 _amount) public {
        vm.prank(payer);
        dpss2.createStream(recipient, period, address(token), _amount);
    }

    function testPauseStreamByPayer() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditionsToETH(period, value);

        vm.prank(payer);
        dpss2.pauseStream(0);

        DPSS2.Stream memory stream = dpss2.getStream(0);
        assertEq(stream.paused, true);
        assertEq(stream.pausedAt, block.timestamp);
    }

    function testPauseStreamFailsIfAlreadyPaused() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditionsToETH(period, value);
        vm.prank(payer);
        dpss2.pauseStream(0);
        vm.expectRevert(
            abi.encodeWithSelector(DPSS2.StreamAlreadyPaused.selector)
        );
        dpss2.pauseStream(0);
    }

    function testResumeStreamFailsIfNotPaused() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditionsToETH(period, value);
        vm.startPrank(payer);
        vm.expectRevert(abi.encodeWithSelector(DPSS2.StreamNotPaused.selector));
        dpss2.resumeStream(0);
    }

    function testResumeStreamUpdatesTotalPausedTime() external {
        uint256 value = 1 ether;
        uint256 period = 5 days;
        setConditionsToETH(period, value);
        vm.startPrank(payer);
        vm.warp(300);
        dpss2.pauseStream(0);
        vm.warp(400);
        dpss2.resumeStream(0);
        DPSS2.Stream memory stream = dpss2.getStream(0);
        assertEq(stream.totalPausedTime, 100);
    }

    function testCreateStreamWithERC20TransfersTokensCorrectly() external {
        uint256 value = 100;
        uint256 period = 5 days;
        vm.prank(payer);
        token.approve(address(dpss2), value);

        setConditionsToERC20(period, value);

        assertEq(token.balanceOf(address(dpss2)), value);
    }

    function testCancelStreamWithERC20RefundsCorrectly() external {
        uint256 value = 100;
        uint256 period = 5 days;
        vm.prank(payer);
        token.approve(address(dpss2), value);

        setConditionsToERC20(period, value);

        vm.prank(payer);
        dpss2.cancelStream(0);

        assertApproxEqAbs(
            token.balanceOf(payer),
            1000 ether - value,
            0.0001 ether
        );
        assertEq(token.balanceOf(address(dpss2)), 0);
        assertApproxEqAbs(token.balanceOf(recipient), 100, 0.0001 ether);
    }

    function fuzzWithdrawFundsWithRandomTime(uint256 streamId) public {
        DPSS2.Stream memory stream = dpss2.getStream(streamId);
        uint256 timePassed = bound(
            block.timestamp - stream.startTime,
            0,
            stream.duration
        );

        vm.warp(stream.startTime + timePassed);

        vm.startPrank(stream.recipient);

        uint256 balanceBefore = token.balanceOf(address(stream.recipient));
        dpss2.withdrawFunds(streamId);
        uint256 balanceAfter = token.balanceOf(address(stream.recipient));

        assertGt(balanceAfter, balanceBefore);

        vm.stopPrank();
    }

    function invariantRefundAmountNeverExceedsStreamAmount() external {
        uint256 value = 100;
        uint256 period = 5 days;
        vm.prank(payer);
        token.approve(address(dpss2), value);

        setConditionsToERC20(period, value);
        DPSS2.Stream memory stream = dpss2.getStream(0);

        uint256 refundAmount = stream.amount -
            (stream.releasedAmount +
                (block.timestamp - stream.startTime) *
                stream.rate);

        assert(refundAmount <= stream.amount);
    }
}
