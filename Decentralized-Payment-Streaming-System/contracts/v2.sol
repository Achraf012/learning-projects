// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DPSS2 is ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct Stream {
        address payer;
        address payable recipient;
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 rate;
        bool paused;
        uint256 releasedAmount;
        uint256 pausedAt;
        uint256 totalPausedTime;
        IERC20 token;
    }

    mapping(uint256 ID => Stream) public streams;
    uint256 public streamID;

    error StreamTimeEnded();
    error NothingToWithdraw();
    error NoStreamOrNotRecipient();
    error NoStreamOrNotThePayer();
    error StreamNotFound();
    error NothingToRefund();
    error NotValideStreamDuration();
    error RecipientAddressZero();
    error StreamNotPaused();
    error StreamAlreadyPaused();
    error NoFundsSent();
    error StreamPaused();
    error NotEnoughToExtendStream();

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

    function _send(address payable to, uint256 amount, IERC20 token) internal {
        if (address(token) != address(0)) {
            token.safeTransfer(to, amount);
        } else {
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
        }
    }

    function createStream(
        address payable _recipient,
        uint256 _duration,
        address _token
    ) external payable {
        if (msg.value == 0) revert NoFundsSent();
        if (_recipient == address(0)) revert RecipientAddressZero();
        if (_duration == 0) revert NotValideStreamDuration();
        IERC20 token = IERC20(_token);
        if (_token == address(0)) {
            if (msg.value == 0) revert NoFundsSent();
        } else {
            if (msg.value != 0) revert NoFundsSent();
            token.safeTransferFrom(msg.sender, address(this), msg.value);
        }
        streams[streamID] = Stream({
            payer: msg.sender,
            recipient: _recipient,
            amount: msg.value,
            startTime: block.timestamp,
            duration: _duration,
            rate: msg.value / _duration,
            paused: false,
            releasedAmount: 0,
            pausedAt: 0,
            totalPausedTime: 0,
            token: token
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

    function fundStream(uint256 streamId) external payable nonReentrant {
        if (msg.value == 0) revert NoFundsSent();
        Stream storage stream = streams[streamId];
        if (stream.recipient == address(0)) revert StreamNotFound();
        if (msg.value < stream.rate) revert NotEnoughToExtendStream();

        stream.amount += msg.value;
        uint256 extraDuration = msg.value / stream.rate;
        stream.duration += extraDuration;
    }

    function withdrawFunds(uint256 streamid) external nonReentrant {
        Stream storage stream = streams[streamid];
        if (stream.paused) revert StreamPaused();
        address payable recipient = stream.recipient;
        uint256 released = stream.releasedAmount;
        uint256 rate = stream.rate;

        uint256 endTime = stream.startTime + stream.duration;
        uint256 adjustedTime = block.timestamp - stream.totalPausedTime;
        uint256 timePassed = adjustedTime < endTime
            ? adjustedTime - stream.startTime
            : stream.duration;

        uint256 value = (timePassed * rate) - released;
        if (value == 0) revert NothingToWithdraw();

        stream.releasedAmount += value;
        _send(recipient, value, stream.token);

        emit StreamWithdrawn(streamid, recipient, value);
    }

    function pauseStream(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        if (stream.paused) revert StreamAlreadyPaused();
        if (stream.payer != msg.sender) revert NoStreamOrNotThePayer();
        if (stream.startTime + stream.duration < block.timestamp)
            revert StreamTimeEnded();

        stream.pausedAt = block.timestamp;
        stream.paused = true;
    }

    function resumeStream(uint256 streamId) external {
        Stream storage stream = streams[streamId];
        if (!stream.paused) revert StreamNotPaused();
        if (stream.payer != msg.sender) revert NoStreamOrNotThePayer();

        stream.totalPausedTime += block.timestamp - stream.pausedAt;
        stream.pausedAt = 0;
        stream.paused = false;
    }

    function cancelStream(uint256 id) external nonReentrant {
        Stream storage stream = streams[id];
        if (msg.sender != stream.payer) revert NoStreamOrNotThePayer();
        uint256 endTime = stream.startTime + stream.duration;

        uint256 adjustedTime = block.timestamp;
        if (stream.paused) {
            adjustedTime = stream.pausedAt;
        }
        adjustedTime -= stream.totalPausedTime;

        if (adjustedTime > endTime) revert StreamTimeEnded();

        address payable recipient = stream.recipient;
        uint256 released = stream.releasedAmount;
        uint256 rate = stream.rate;

        uint256 timePassed = adjustedTime < endTime
            ? adjustedTime - stream.startTime
            : stream.duration;

        uint256 recipientOwed = (timePassed * rate) - released;
        uint256 refundAmount = stream.amount - (released + recipientOwed);

        if (recipientOwed > 0) {
            stream.releasedAmount += recipientOwed;
            _send(recipient, recipientOwed, stream.token);
        }

        if (refundAmount > 0) {
            _send(payable(msg.sender), refundAmount, stream.token);
        }
        delete streams[id];

        emit StreamCancelled(id, msg.sender, stream.releasedAmount);
    }
}
