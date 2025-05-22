// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "../src/DAO-v1.sol";
import "../src/GovernanceToken.sol";

contract v1test is Test {
    Token token;
    DAO dao;
    address user1;
    address user2;
    address tokenOwner;

    function setUp() public {
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        tokenOwner = makeAddr("tokenOwner");

        vm.startPrank(tokenOwner);
        token = new Token("money", "mn");
        dao = new DAO(address(token));
    }

    function mintToUsers(uint256 amount1, uint256 amount2) public {
        // vm.startPrank(tokenOwner);
        token.mint(user1, amount1);
        token.mint(user2, amount2);
        vm.stopPrank();
    }

    function testUserCanCreatNewProposal() public {
        // vm.prank(user1);
        dao.createProposal("a simple proposal testing description", 3 days);

        (, string memory description, uint256 deadline, , , ) = dao.getProposal(
            1
        );
        console.log("Description: %s", description);
        console.log("Deadline: %s", deadline);
    }

    function testProposalIdIncrementsCorrectly() public {
        dao.createProposal("a simple proposal testing description", 3 days);
        dao.createProposal("a second proposal testing description", 4 days);
        assertEq(dao.proposalId(), 2);
    }

    function testVoteYesIncreasesYesVotesByWeight() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.prank(user1);
        dao.vote(1, true);
        (, , , uint256 yesVotes, , ) = dao.getProposal(1);
        assertEq(yesVotes, 100);
    }

    function testVoteNoIncreasesNoVotesByWeight() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.prank(user1);
        dao.vote(1, false);
        (, , , , uint256 noVotes, ) = dao.getProposal(1);
        assertEq(noVotes, 100);
    }

    function testVoteRevertsIfAlreadyVoted() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.prank(user1);
        dao.vote(1, false);
        vm.expectRevert();
        dao.vote(1, true);
    }

    function testVoteRevertsIfNoTokenBalance() public {
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.expectRevert(bytes("No tokens to vote with"));
        dao.vote(1, false);
    }

    function testVoteRevertsIfAfterDeadline() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 1);
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        dao.vote(1, false);
    }

    function testCountVotesRevertsIfBeforeDeadline() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.expectRevert();
        dao.countVotes(1);
    }

    function testCountVotesMarksPassedIfYesVotesGreater() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.prank(user1);
        dao.vote(1, true);
        vm.prank(user2);
        dao.vote(1, false);
        vm.warp(block.timestamp + 3 days);
        dao.countVotes(1);
        (, , , , , bool passed) = dao.getProposal(1);
        assertEq(passed, true);
    }

    function testCountVotesDoesNotMarkPassedIfNoVotesGreaterOrEqual() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        vm.prank(user1);
        dao.vote(1, false);
        vm.prank(user2);
        dao.vote(1, false);
        vm.warp(block.timestamp + 3 days);
        dao.countVotes(1);
        (, , , , , bool passed) = dao.getProposal(1);
        assertEq(passed, false);
    }

    function testMultipleProposalsKeepSeparateVotes() public {
        mintToUsers(100, 50);
        dao.createProposal("a simple proposal testing description", 3 days);
        dao.createProposal("a second proposal testing description", 4 days);
        vm.prank(user1);
        dao.vote(1, true);
        vm.prank(user2);
        dao.vote(2, false);
        vm.warp(block.timestamp + 3 days);
        dao.countVotes(1);
        vm.warp(block.timestamp + 4 days);
        dao.countVotes(2);

        (, , , uint256 yesVotes, , ) = dao.getProposal(1);
        (, , , , uint256 noVotes, ) = dao.getProposal(2);

        assertEq(yesVotes, 100);
        assertEq(noVotes, 50);
    }
}
