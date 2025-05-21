// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DAO {
    using SafeERC20 for IERC20;
    IERC20 public token;
    error AlreadyVoted();
    error VotingTimeEnded();
    error VotingIsStillGoing();

    constructor(address tokenAddress) {
        token = IERC20(tokenAddress);
    }

    uint256 proposalId = 0;
    struct Proposal {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool passed;
        mapping(address user => bool voted) voters;
    }
    mapping(uint256 id => Proposal) proposals;

    function createProposal(
        string calldata description,
        uint256 duration
    ) external {
        proposalId++;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = description;
        proposal.deadline = block.timestamp + duration;
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        proposal.passed = false;
    }

    function vote(uint256 Id, bool support) external {
        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No tokens to vote with");

        Proposal storage proposal = proposals[Id];

        if (block.timestamp > proposal.deadline) {
            revert VotingTimeEnded();
        }
        if (proposal.voters[msg.sender] == true) {
            revert AlreadyVoted();
        }
        if (support == true) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }
        proposal.voters[msg.sender] = true;
    }

    function countVotes(uint256 Id) external {
        Proposal storage proposal = proposals[Id];
        if (block.timestamp < proposal.deadline) {
            revert VotingIsStillGoing();
        }
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.passed = true;
        }
    }

    function getProposal(
        uint256 Id
    )
        external
        view
        returns (
            uint256 id,
            string memory description,
            uint256 deadline,
            uint256 yesVotes,
            uint256 noVotes,
            bool passed
        )
    {
        Proposal storage proposal = proposals[Id];
        return (
            proposal.id,
            proposal.description,
            proposal.deadline,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.passed
        );
    }
}
