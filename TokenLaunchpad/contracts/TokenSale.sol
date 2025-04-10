// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; // <-- Import SafeERC20
import "./vesting.sol";

contract tokenSale is Ownable, ReentrancyGuard {
    enum SaleType {
        PRESALE,
        FAIRLAUNCH,
        IDO
    }
    uint256 price;
    uint256 softCap;
    uint256 hardCap;
    uint256 StartTime;
    uint256 EndTime;
    uint256 raisedAmount;
    uint256 totalETHCommitted;
    uint256 public totalTokensForSale;
    vesting public vestingContract;
    uint256 public cliffDuration;
    uint256 public vestingDuration;

    mapping(address => uint256) investors; //  Amount each user invested
    mapping(address => uint256) tokenBalances; // Tokens allocated per user.
    error hardCapExceeded();
    error softCapExceeded();
    error SaleNotStarted();
    error SaleHasEnded();
    error SaleIsNotActive();
    error onlyforPresale();
    error softCapNotReached();
    event TokensPurchased(
        address indexed buyer,
        uint256 amountETH,
        uint256 tokensAllocated
    );
    event TokensClaimed(address indexed user, uint256 tokenAmount);
    event RefundClaimed(address indexed user, uint256 amountETH);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    SaleType public saleType;
    IERC20 token;
    using SafeERC20 for IERC20;

    constructor(
        vesting _vestingContract,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        IERC20 _tokenAddress,
        uint256 _price,
        uint256 _StartTime,
        uint256 _EndTime,
        uint256 _softCap,
        uint256 _hardCap,
        SaleType _saletype,
        uint256 _totalTokensForSale
    ) Ownable(msg.sender) {
        vestingContract = _vestingContract;
        price = _price;
        StartTime = _StartTime;
        EndTime = _EndTime;
        softCap = _softCap;
        hardCap = _hardCap;
        saleType = _saletype;
        token = _tokenAddress;
        totalTokensForSale = _totalTokensForSale;
        cliffDuration = _cliffDuration;
        vestingDuration = _vestingDuration;
    }

    modifier saleIsActive() {
        if (block.timestamp < StartTime) {
            revert SaleNotStarted();
        }
        if (block.timestamp > EndTime) {
            revert SaleHasEnded();
        }
        _;
    }

    modifier saleHasEnded() {
        if (block.timestamp <= EndTime) {
            revert SaleIsNotActive();
        }
        _;
    }

    function buyToken() external payable saleIsActive {
        if (raisedAmount + msg.value > hardCap) {
            revert hardCapExceeded();
        }
        investors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        if (saleType == SaleType.PRESALE || saleType == SaleType.IDO) {
            uint256 tokens = (msg.value * 1e18) / price;

            tokenBalances[msg.sender] += tokens;
            vestingContract.setVestingSchedule(
                msg.sender,
                tokens,
                cliffDuration,
                vestingDuration
            );
            emit TokensPurchased(msg.sender, msg.value, tokens);
        } else if (saleType == SaleType.FAIRLAUNCH) {
            require(totalTokensForSale > 0, "No tokens for sale");

            totalETHCommitted += msg.value;
            emit TokensPurchased(msg.sender, msg.value, 0);
        }
    }

    function claimTokens() external saleHasEnded nonReentrant {
        if (saleType == SaleType.PRESALE || saleType == SaleType.IDO) {
            uint256 amount = tokenBalances[msg.sender];
            tokenBalances[msg.sender] = 0;
            token.safeTransfer(msg.sender, amount);
            emit TokensClaimed(msg.sender, amount);
        }
        if (saleType == SaleType.FAIRLAUNCH) {
            uint256 tokenPrice = totalETHCommitted / totalTokensForSale;
            uint256 amount = investors[msg.sender];
            tokenBalances[msg.sender] = 0;
            uint256 userTokenAmount = (amount * 1e18) / tokenPrice;
            token.safeTransfer(msg.sender, userTokenAmount);
            emit TokensClaimed(msg.sender, userTokenAmount);
        }
    }

    function claimRefunds() external saleHasEnded nonReentrant {
        if (softCap <= raisedAmount) {
            revert softCapExceeded();
        }
        if (saleType == SaleType.PRESALE) {
            uint256 amount = investors[msg.sender];
            require(amount > 0, "No refund available");
            investors[msg.sender] = 0;
            (bool succes, ) = payable(msg.sender).call{value: amount}("");
            require(succes, "Refund failed");
            emit RefundClaimed(msg.sender, amount);
        } else {
            revert onlyforPresale();
        }
    }

    function withdrawFunds() external saleHasEnded onlyOwner nonReentrant {
        if (softCap > raisedAmount) {
            revert softCapNotReached();
        }
        uint256 amount = raisedAmount;
        raisedAmount = 0;
        (bool succes, ) = payable(msg.sender).call{value: amount}("");
        require(succes, "Refund failed");
        emit FundsWithdrawn(msg.sender, amount);
    }
}
