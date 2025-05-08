// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityPool is ERC20 {
    using SafeERC20 for IERC20;
    address public immutable router;
    address public immutable factory;
    address public token0;
    address public token1;
    uint256 reserve0;
    uint256 reserve1;
    bool initialized;
    event PoolInitialized(address token0, address token1);
    event LiquidityAdded(
        address indexed to,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed to,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity
    );
    event Swapped(address indexed to, uint256 amount0Out, uint256 amount1Out);

    constructor(address _router) ERC20("LP Token", "LPT") {
        require(_router != address(0), "Address Not Available ( 0 Address)");
        factory = msg.sender;
        router = _router;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) {
            return 0;
        }
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    function initialize(address _token0, address _token1) external {
        require(factory == msg.sender, "not allowed");
        require(!initialized, "Already Initialized");
        require(_token0 != _token1, "Cant Use Same Token");
        (token0, token1) = _token0 < _token1
            ? (_token0, _token1)
            : (_token1, _token0);
        initialized = true;
        emit PoolInitialized(token0, token1);
    }

    function getReserves() external view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function getRemoveAmounts(
        uint256 lpAmount
    ) external view returns (uint256, uint256) {
        uint256 amount0 = (lpAmount * reserve0) / totalSupply();
        uint256 amount1 = (lpAmount * reserve1) / totalSupply();
        return (amount0, amount1);
    }

    function _updateReserves() internal {
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }

    function addLiquidity(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external {
        require(msg.sender == address(router), "Only router can call this");

        require(initialized, "Not Initialized");

        uint256 mintAmount;
        if (totalSupply() == 0) {
            mintAmount = sqrt(amount0 * amount1);
        } else {
            uint256 share0 = (amount0 * totalSupply()) / reserve0;
            uint256 share1 = (amount1 * totalSupply()) / reserve1;
            mintAmount = min(share0, share1);
        }
        _mint(to, mintAmount);
        _updateReserves();
        emit LiquidityAdded(to, amount0, amount1, mintAmount);
    }

    function removeLiquidity(uint256 lp, address to) external {
        require(msg.sender == address(router), "Only router can call this");
        require(initialized, "Not Initialized");

        uint256 tokenAmount0 = (lp * reserve0) / totalSupply();
        uint256 tokenAmount1 = (lp * reserve1) / totalSupply();

        _burn(address(this), lp);
        IERC20(token0).safeTransfer(to, tokenAmount0);
        IERC20(token1).safeTransfer(to, tokenAmount1);
        _updateReserves();
        emit LiquidityRemoved(to, tokenAmount0, tokenAmount1, lp);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external {
        require(msg.sender == router, "Only router can call");
        require(initialized, "Not Initialized");
        require(
            amount0Out != 0 || amount1Out != 0,
            "Insufficient output amount"
        );
        require(to != token0 && to != token1, "Invalid recipient");

        if (amount0Out > 0) {
            IERC20(token0).safeTransfer(to, amount0Out);
        }
        if (amount1Out > 0) {
            IERC20(token1).safeTransfer(to, amount1Out);
        }

        _updateReserves();
        emit Swapped(to, amount0Out, amount1Out);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256) {
        require(amountIn < reserveIn, "Insufficient liquidity");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        return amountOut;
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256) {
        require(amountOut < reserveOut, "Insufficient liquidity");

        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        uint256 amountIn = (numerator / denominator) + 1;
        return amountIn;
    }
}
