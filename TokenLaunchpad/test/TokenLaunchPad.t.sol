// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/TokenSale.sol";
import "../src/vesting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract MockERC20 is ERC20 {
    event Minted(address indexed to, uint256 amount);

    constructor() ERC20("MockToken", "MTK") {
        _mint(msg.sender, 1_000_000 ether);
        emit Minted(msg.sender, 1_000_000 ether);
    }
}

contract TokenSaleTest is Test {
    tokenSale public tokenSaleInstance;
    vesting public vestingContract;
    MockERC20 public mockToken;

    uint256 public price = 1e16;
    uint256 public softCap = 1 ether;
    uint256 public hardCap = 10 ether;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public cliff = 10;
    uint256 public vestingDuration = 20;
    uint256 public claimTime = 60 * 1 days;
    uint256 public totalTokensForSale = 100_000 ether;
    address owner = address(1);
    address user = address(2);
    address user2 = address(3);

    function setUp() public {
        startTime = block.timestamp + 1 days;
        endTime = block.timestamp + 10 days;
        console.log("the owner is ", owner);
        console.log("msg", msg.sender);

        vm.startPrank(owner);

        // Deal some ETH to the addresses involved in the tests
        vm.deal(user, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(owner, 10 ether); // Ensure the owner has enough ETH for testing

        mockToken = new MockERC20();

        vestingContract = new vesting(IERC20(mockToken), claimTime);

        tokenSaleInstance = new tokenSale(
            vestingContract,
            cliff,
            vestingDuration,
            IERC20(mockToken),
            price,
            startTime,
            endTime,
            softCap,
            hardCap,
            tokenSale.SaleType.PRESALE,
            totalTokensForSale
        );

        // Transfer tokens to the Vesting and TokenSale contracts for initial distribution
        mockToken.transfer(address(vestingContract), totalTokensForSale);
        mockToken.transfer(address(tokenSaleInstance), totalTokensForSale);
        vestingContract.transferOwnership(address(tokenSaleInstance));
        vm.stopPrank();
    }

    function testRevertIfSaleNotStarted() public {
        vm.prank(user);
        vm.expectRevert(tokenSale.SaleNotStarted.selector);
        tokenSaleInstance.buyToken{value: 1 ether}();
    }

    function testRevertIfHardCapExceeded() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 6 ether}();

        vm.prank(user2);
        vm.expectRevert(tokenSale.hardCapExceeded.selector);
        tokenSaleInstance.buyToken{value: 5 ether}();
    }

    function testClaimBeforeCliffReverts() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime - 1 days);
        vm.prank(user);
        vm.expectRevert(vesting.CliffNotOver.selector);
        vestingContract.claimTokens();
    }

    function testClaimAfterCliffAndBeforeClaimingWindowEnds() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime + (cliff + 1) * 1 days);
        vm.prank(user);
        vestingContract.claimTokens();

        assertGt(mockToken.balanceOf(user), 0);
    }

    function testDoubleClaimRevertsIfNothingLeft() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime + (cliff + vestingDuration + 1) * 1 days);
        vm.prank(user);
        vestingContract.claimTokens();

        vm.prank(user);
        vm.expectRevert(vesting.NoTokensToClaim.selector);
        vestingContract.claimTokens();
    }

    function testClaimRefundsIfSoftCapNotReached() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 0.5 ether}();

        vm.warp(endTime + 1 days);
        vm.prank(user);
        tokenSaleInstance.claimRefunds();
    }

    function testWithdrawFundsIfSoftCapReached() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime + 1 days);
        vm.prank(owner); // <- make sure the owner is calling
        tokenSaleInstance.withdrawFunds();
    }

    function testRevertWithdrawFundsIfSoftCapNotReached() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 0.5 ether}();

        vm.warp(endTime + 1 days);
        vm.prank(owner);
        vm.expectRevert(tokenSale.softCapNotReached.selector);
        tokenSaleInstance.withdrawFunds();
    }

    function testOwnerWithdrawsUnclaimedTokensAfterClaimingWindow() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime + (cliff + claimTime + 1) * 1 days);
        vm.prank(address(tokenSaleInstance));
        vestingContract.withdrawRemainingTokens();

        assertGt(mockToken.balanceOf(owner), 0);
    }

    function testRevertWithdrawRemainingBeforeWindowEnds() public {
        vm.warp(startTime);
        vm.prank(user);
        tokenSaleInstance.buyToken{value: 1 ether}();

        vm.warp(endTime + (cliff + 10) * 1 days);
        vm.prank(address(tokenSaleInstance));
        vm.expectRevert(vesting.ClaimingWindowNotOver.selector);
        vestingContract.withdrawRemainingTokens();
    }
}
