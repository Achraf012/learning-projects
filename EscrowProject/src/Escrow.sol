// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Escrow is ReentrancyGuard {
    address payable immutable seller;
    address immutable buyer;
    address immutable arbitrator;
    uint128 amount;
    uint32 immutable deadline;

    error PriceProblem(uint256 price, uint256 amount);
    error NotTheOwner(address owner, address user);
    error NotTheArbitrator(address arbitrator, address user);
    error NotTheBuyer(address buyer, address user);
    error NotTheSeller(address seller, address user);
    error NotDisputed();
    error NotApproved();
    error AlreadyDisputed();
    error WrongAddress();
    error DeadlinePassed();
    error StillActive();
    error InvalidDeadline();

    event Deposited(address indexed buyer, uint256 amount);
    event Approved(address indexed seller);
    event FundsReleased(address indexed to, uint256 amount);
    event DisputeOpened(address indexed buyer);
    event DisputeResolved(address indexed to, uint256 amount);
    event Cancelled(address indexed buyer, uint256 amount);
    event RefundedAfterDeadline(address indexed buyer, uint256 amount);

    enum EscrowState {
        Created,
        Deposited,
        Approved,
        Released,
        Disputed,
        Resolved
    }

    EscrowState public state;

    constructor(
        address payable _seller,
        address _arbitrator,
        address _buyer,
        uint128 _amount,
        uint32 duration
    ) {
        if (duration < 3600 || duration > 30 days) {
            revert InvalidDeadline();
        }
        seller = _seller;
        arbitrator = _arbitrator;
        buyer = _buyer;
        deadline = uint32(block.timestamp + duration);
        amount = _amount;
        state = EscrowState.Created;
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        revert("Fallback not allowed");
    }

    function getState() external view returns (EscrowState) {
        return state;
    }

    function getRemainingTime() external view returns (int256) {
        return int256(uint256(deadline)) - int256(block.timestamp);
    }

    function deposit() public payable {
        if (amount != msg.value) {
            revert PriceProblem(msg.value, amount);
        }
        if (msg.sender != buyer) {
            revert NotTheBuyer(buyer, msg.sender);
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }
        state = EscrowState.Deposited;
        emit Deposited(msg.sender, msg.value);
    }

    function approve() external {
        if (msg.sender != buyer) {
            revert NotTheBuyer(buyer, msg.sender);
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }
        state = EscrowState.Approved;
        emit Approved(msg.sender);
    }

    function releaseFunds() external nonReentrant {
        if (state != EscrowState.Approved) {
            revert NotApproved();
        }
        if (msg.sender != seller) {
            revert NotTheSeller(seller, msg.sender);
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }

        (bool success, ) = seller.call{value: amount}("");
        require(success, "transfer funds failed");
        emit FundsReleased(seller, amount);
        delete amount;
        state = EscrowState.Released;
    }

    function openDispute() external {
        if (msg.sender != buyer) {
            revert NotTheBuyer(buyer, msg.sender);
        }
        if (state != EscrowState.Deposited && state != EscrowState.Approved) {
            revert("Cannot dispute at this stage");
        }
        if (block.timestamp > deadline) {
            revert DeadlinePassed();
        }

        state = EscrowState.Disputed;
        emit DisputeOpened(msg.sender);
    }

    function resolveDispute(address payable to) external nonReentrant {
        if (state != EscrowState.Disputed) {
            revert NotDisputed();
        }
        if (msg.sender != arbitrator) {
            revert NotTheArbitrator(arbitrator, msg.sender);
        }
        if (to != seller && to != buyer) {
            revert WrongAddress();
        }

        (bool success, ) = to.call{value: amount}("");
        require(success, "transfer funds failed");
        emit DisputeResolved(to, amount);
        delete amount;
        state = EscrowState.Resolved;
    }

    function cancel() external nonReentrant {
        if (msg.sender != buyer) {
            revert NotTheBuyer(buyer, msg.sender);
        }
        if (state != EscrowState.Deposited) {
            revert("Can't cancel now");
        }

        (bool success, ) = buyer.call{value: amount}("");
        require(success, "Refund failed");
        emit Cancelled(buyer, amount);
        delete amount;
        state = EscrowState.Resolved;
    }

    function refundAfterDeadline() external nonReentrant {
        if (block.timestamp <= deadline) {
            revert StillActive();
        }
        if (state != EscrowState.Deposited) {
            revert("Refund not allowed in current state");
        }

        (bool success, ) = buyer.call{value: amount}("");
        require(success, "Refund failed");
        emit RefundedAfterDeadline(buyer, amount);
        delete amount;
        state = EscrowState.Resolved;
    }
}
