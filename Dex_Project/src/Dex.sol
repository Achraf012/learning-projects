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
    ) external view returns (uint256 reserveA, uint256 reserveB) {
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
        IERC20(tokenIn).transferFrom(msg.sender, pair, amountIn);

        (uint256 reserve0, uint256 reserve1) = LiquidityPool(pair)
            .getReserves();
        uint256 amountOut = LiquidityPool(pair).getAmountOut(
            amountIn,
            reserve0,
            reserve1
        );
        require(minAmountOut >= amountOut, "Amount Out Less Than Minimum");
        address token0 = tokenIn < tokenOut ? tokenIn : tokenOut;

        bool isToken0In = tokenIn == token0;

        uint amount0Out = isToken0In ? 0 : amountOut;
        uint amount1Out = isToken0In ? amountOut : 0;
        LiquidityPool(pair).swap(amount0Out, amount1Out, to);
    }
}
