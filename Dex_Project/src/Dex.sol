// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Factory.sol";
import "./LiquidityPool.sol";

contract router {
    using SafeERC20 for IERC20;
    address public factoryAddress;

    constructor(address _factory) {
        factoryAddress = _factory;
    }

    function getPair(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        pair = factory(factoryAddress).getPairAddress(tokenA, tokenB);
    }

    function getReserves(
        address tokenA,
        address tokenB
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        address pair = factory(factoryAddress).getPairAddress(tokenA, tokenB);
        (uint256 r0, uint256 r1) = LiquidityPool(pair).getReserves();

        if (tokenA < tokenB) {
            return (r0, r1);
        } else {
            return (r1, r0);
        }
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external {
        address pair = getPair(address(tokenIn), address(tokenOut));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            tokenOut
        );

        uint256 amountOut = LiquidityPool(pair).getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );

        require(minAmountOut <= amountOut, "Amount Out Less Than Minimum");
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);
        if (tokenIn < tokenOut) {
            LiquidityPool(pair).swap(0, amountOut, to);
        } else {
            LiquidityPool(pair).swap(amountOut, 0, to);
        }
    }

    function _calculateLiquidityAmounts(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minA,
        uint256 minB
    ) internal view returns (uint256 depositA, uint256 depositB, address pair) {
        require(amountA > 0 && amountB > 0, "Zero amount not allowed");
        pair = getPair(tokenA, tokenB);
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            require(amountA >= minA && amountB >= minB, "Amounts < Min");
            return (amountA, amountB, pair);
        }

        uint256 amountBOptimal = (amountA * reserveB) / reserveA;
        if (amountBOptimal <= amountB) {
            require(amountBOptimal >= minB && amountA >= minA, "Amounts < Min");
            return (amountA, amountBOptimal, pair);
        } else {
            uint256 amountAOptimal = (amountB * reserveA) / reserveB;
            require(amountAOptimal >= minA && amountB >= minB, "Amounts < Min");
            return (amountAOptimal, amountB, pair);
        }
    }

    function _safeTransferLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 depositA,
        uint256 depositB
    ) internal {
        (uint256 amount0, uint256 amount1) = tokenA < tokenB
            ? (depositA, depositB)
            : (depositB, depositA);

        IERC20(tokenA).safeTransferFrom(msg.sender, pair, depositA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, depositB);

        LiquidityPool(pair).addLiquidity(amount0, amount1, msg.sender);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minA,
        uint256 minB
    ) external {
        (
            uint256 depositA,
            uint256 depositB,
            address pair
        ) = _calculateLiquidityAmounts(
                tokenA,
                tokenB,
                amountA,
                amountB,
                minA,
                minB
            );

        _safeTransferLiquidity(tokenA, tokenB, pair, depositA, depositB);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 lpAmount,
        uint256 minA,
        uint256 minB
    ) external {
        address pair = getPair(address(tokenA), address(tokenB));
        (uint256 amountA, uint256 amountB) = LiquidityPool(pair)
            .getRemoveAmounts(lpAmount);
        (amountA, amountB) = tokenA < tokenB
            ? (amountA, amountB)
            : (amountB, amountA);
        require(
            amountA >= minA && amountB >= minB,
            "Amounts Less Than Minimum "
        );

        IERC20(pair).safeTransferFrom(msg.sender, pair, lpAmount);
        LiquidityPool(pair).removeLiquidity(lpAmount, msg.sender);
    }

    function swapTokensForExactTokens() external {}
}
