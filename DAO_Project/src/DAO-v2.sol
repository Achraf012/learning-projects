// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract DAO is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    IERC20 public token;
    error AlreadyVoted();
    error VotingTimeEnded();
    error VotingIsStillGoing();
    event ProposalCreated(
        uint256 indexed id,
        string description,
        uint256 deadline
    );

    event Voted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event VotesCounted(
        uint256 indexed proposalId,
        bool passed,
        uint256 yesVotes,
        uint256 noVotes
    );

    // constructor(address tokenAddress) {
    //     token = IERC20(tokenAddress);
    // }
    function initialize(IERC20 _token) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        token = _token;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    uint256 public proposalId = 0;
    struct Proposal {
        uint256 id;
        string description;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool passed;
        mapping(address user => bool voted) voters;
    }
    mapping(uint256 id => Proposal) public proposals;

    function createProposal(
        string calldata description,
        uint256 duration
    ) external onlyOwner {
        proposalId++;
        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.description = description;
        proposal.deadline = block.timestamp + duration;
        proposal.yesVotes = 0;
        proposal.noVotes = 0;
        proposal.passed = false;
        emit ProposalCreated(proposalId, description, proposal.deadline);
    }

    function vote(uint256 Id, bool support) external {
        uint256 weight = token.balanceOf(msg.sender);
        require(weight > 0, "No tokens to vote with");

        Proposal storage proposal = proposals[Id];

        if (block.timestamp >= proposal.deadline) {
            revert VotingTimeEnded();
        }
        if (proposal.voters[msg.sender]) {
            revert AlreadyVoted();
        }
        if (support) {
            proposal.yesVotes += weight;
        } else {
            proposal.noVotes += weight;
        }
        proposal.voters[msg.sender] = true;
        emit Voted(Id, msg.sender, support, weight);
    }

    function countVotes(uint256 Id) external {
        Proposal storage proposal = proposals[Id];
        if (block.timestamp <= proposal.deadline) {
            revert VotingIsStillGoing();
        }
        if (proposal.yesVotes >= proposal.noVotes) {
            proposal.passed = true;
        }
        emit VotesCounted(
            Id,
            proposal.passed,
            proposal.yesVotes,
            proposal.noVotes
        );
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
