// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DPSS1 is ReentrancyGuard {
    struct Stream {
        address payer;
        address payable recipient;
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 rate;
        bool active;
        uint256 releasedAmount;
    }

    mapping(uint256 ID => Stream) public streams;
    uint256 public streamID;

    error StreamTimeEnded();
    error NothingToWithdraw();
    error NoStreamOrNotRecipient();
    error NoStreamOrNotThePayer();
    error StreamNotFound();
    error NothingToRefund();

    event StreamCreated(
        uint256 indexed id,
        address indexed payer,
        address indexed recipient,
        uint256 amount,
        uint256 duration
    );
    event StreamWithdrawn(
        uint256 indexed id,
        address indexed recipient,
        uint256 amount
    );
    event StreamCancelled(
        uint256 indexed id,
        address indexed payer,
        uint256 releasedAmount
    );

    function createStream(
        address payable _recipient,
        uint16 _duration
    ) external payable {
        streams[streamID] = Stream({
            payer: msg.sender,
            recipient: _recipient,
            amount: msg.value,
            startTime: block.timestamp,
            duration: _duration,
            rate: msg.value / _duration,
            active: true,
            releasedAmount: 0
        });

        emit StreamCreated(
            streamID,
            msg.sender,
            _recipient,
            msg.value,
            _duration
        );
        unchecked {
            streamID++;
        }
    }

    function withdraw(uint256 id) external nonReentrant {
        Stream storage stream = streams[id];
        address payer = stream.payer;
        address payable recipient = stream.recipient;
        uint256 released = stream.releasedAmount;
        uint256 rate = stream.rate;

        if (payer == address(0) || msg.sender != recipient)
            revert NoStreamOrNotRecipient();

        uint256 endTime = stream.startTime + stream.duration;
        uint256 timePassed = block.timestamp < endTime
            ? block.timestamp - stream.startTime
            : stream.duration;

        uint256 value = (timePassed * rate) - released;
        if (value == 0) revert NothingToWithdraw();

        stream.releasedAmount += value;
        _sendEther(recipient, value);

        emit StreamWithdrawn(id, recipient, value);
    }

    function cancelStream(uint256 id) external nonReentrant {
        Stream storage stream = streams[id];
        if (!stream.active) revert StreamTimeEnded();

        address payer = stream.payer;
        if (payer == address(0) || msg.sender != payer)
            revert NoStreamOrNotThePayer();

        address payable recipient = stream.recipient;
        uint256 released = stream.releasedAmount;
        uint256 rate = stream.rate;

        uint256 endTime = stream.startTime + stream.duration;
        uint256 timePassed = block.timestamp < endTime
            ? block.timestamp - stream.startTime
            : stream.duration;

        uint256 recipientOwed = (timePassed * rate) - released;
        uint256 refundAmount = stream.amount - (released + recipientOwed);

        if (recipientOwed > 0) {
            stream.releasedAmount += recipientOwed;
            _sendEther(recipient, recipientOwed);
        }

        if (refundAmount > 0) {
            _sendEther(payable(msg.sender), refundAmount);
        }

        stream.active = false;
        emit StreamCancelled(id, msg.sender, stream.releasedAmount);
    }

    function _sendEther(address payable to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH transfer failed");
    }
}
