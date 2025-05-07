// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
        return LiquidityPool(pair).getReserves();
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address to
    ) external {
        address pair = getPair(address(tokenIn), address(tokenOut));

        (address token0, ) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        bool isToken0In = tokenIn == token0;

        (uint256 reserve0, uint256 reserve1) = getReserves(tokenIn, tokenOut);
        (uint256 reserveIn, uint256 reserveOut) = isToken0In
            ? (reserve0, reserve1)
            : (reserve1, reserve0);

        uint256 amountOut = LiquidityPool(pair).getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );

        require(minAmountOut <= amountOut, "Amount Out Less Than Minimum");
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);

        uint amount0Out = isToken0In ? 0 : amountOut;
        uint amount1Out = isToken0In ? amountOut : 0;
        LiquidityPool(pair).swap(amount0Out, amount1Out, to);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 minA,
        uint256 minB
    ) external {
        address pair = getPair(address(tokenA), address(tokenB));
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB);
        uint256 amountBOptimal = (amountA * reserveB) / reserveA;
        uint256 amountAOptimal = (amountB * reserveA) / reserveB;
        if (amountBOptimal <= amountB) {
            require(
                amountBOptimal >= minB && amountA >= minA,
                "Amounts Less Than Minimum "
            );

            IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
            IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountBOptimal);
            LiquidityPool(pair).addLiquidity(
                amountBOptimal,
                amountA,
                msg.sender
            );
        } else {
            require(
                amountBOptimal >= minB && amountA >= minA,
                "Amounts Less Than Minimum "
            );

            IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountAOptimal);
            IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
            LiquidityPool(pair).addLiquidity(
                amountAOptimal,
                amountB,
                msg.sender
            );
        }
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
        require(
            amountA >= minA && amountB >= minB,
            "Amounts Less Than Minimum "
        );

        IERC20(pair).safeTransferFrom(msg.sender, pair, lpAmount);
        LiquidityPool(pair).removeLiquidity(lpAmount, msg.sender);
    }

    function swapTokensForExactTokens() external {}
}
