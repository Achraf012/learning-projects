// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract vesting is Ownable, ReentrancyGuard {
    IERC20 public token;
    using SafeERC20 for IERC20;
    uint256 public claimingWindowEndTime;
    uint256 public claimTime;
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 releasedAmount;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
    }
    error CliffNotOver();
    error NoTokensToClaim();
    error NotReasonableTime();
    error ClaimingWindowNotOver();
    event TokensVested(address indexed beneficiary, uint256 amount);
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    event TokensWithdrawn(address indexed owner, uint256 amount);
    mapping(address beneficiary => VestingSchedule) vestingSchedules;

    constructor(IERC20 _token, uint256 _claimTime) Ownable(msg.sender) {
        token = _token;
        if (_claimTime < 30 days || _claimTime > 90 days) {
            revert NotReasonableTime();
        }
        claimTime = _claimTime * 1 days;
    }

    function setVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 cliffDurationInDays,
        uint256 vestingDurationInDays
    ) external onlyOwner {
        require(
            vestingSchedules[beneficiary].totalAmount == 0,
            "Vesting schedule already set"
        );
        uint256 cliffDuration = cliffDurationInDays * 1 days;
        uint256 vestingDuration = vestingDurationInDays * 1 days;
        vestingSchedules[beneficiary] = VestingSchedule({
            totalAmount: totalAmount,
            releasedAmount: 0,
            startTime: block.timestamp,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration
        });
        uint256 newClaimingWindowEnd = block.timestamp +
            cliffDuration +
            claimTime;

        if (newClaimingWindowEnd > claimingWindowEndTime) {
            claimingWindowEndTime = newClaimingWindowEnd;
        }
        emit TokensVested(beneficiary, totalAmount);
    }

    function claimableAmount(
        address beneficiary
    ) internal view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[beneficiary];
        if (block.timestamp < schedule.startTime + schedule.cliffDuration) {
            revert CliffNotOver();
        }
        uint256 elapsedTime = block.timestamp - schedule.startTime;
        uint256 vestedAmount = (schedule.totalAmount * elapsedTime) /
            schedule.vestingDuration;
        uint256 claimable = vestedAmount - schedule.releasedAmount;
        return claimable > 0 ? claimable : 0;
    }

    function claimTokens() external nonReentrant {
        address beneficiary = msg.sender;
        uint256 claimAmount = claimableAmount(beneficiary);
        if (claimAmount == 0) {
            revert NoTokensToClaim();
        }

        VestingSchedule storage schedule = vestingSchedules[beneficiary];

        schedule.releasedAmount += claimAmount;
        token.safeTransfer(msg.sender, claimAmount);
        emit TokensClaimed(beneficiary, claimAmount);
    }

    function withdrawRemainingTokens() external onlyOwner nonReentrant {
        if (block.timestamp < claimingWindowEndTime) {
            revert ClaimingWindowNotOver();
        }
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) {
            revert NoTokensToClaim();
        }

        token.safeTransfer(owner(), balance);
        emit TokensWithdrawn(msg.sender, balance);
    }
}
