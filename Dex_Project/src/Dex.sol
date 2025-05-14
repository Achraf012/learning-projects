// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Factory.sol";
import "./LiquidityPool.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function transfer(address to, uint256 value) external returns (bool);
}

contract router {
    using SafeERC20 for IERC20;
    address public immutable factoryAddress;
    IWETH public immutable WETH;

    event LiquidityAdded(
        address indexed tokenA,
        address indexed tokenB,
        address indexed user,
        uint256 amountA,
        uint256 amountB
    );

    event LiquidityRemoved(
        address indexed tokenA,
        address indexed tokenB,
        address indexed user,
        uint256 amountA,
        uint256 amountB
    );

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        address indexed user,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _factory, address _weth) {
        require(_factory != address(0), "Address Not Available ( 0 Address)");
        factoryAddress = _factory;
        WETH = IWETH(_weth);
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
        emit LiquidityAdded(tokenA, tokenB, msg.sender, depositA, depositB);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 lpAmount,
        uint256 minA,
        uint256 minB
    ) external {
        require(lpAmount > 0, "ZERO_LP");

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
        emit LiquidityRemoved(tokenA, tokenB, msg.sender, amountA, amountB);
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

        require(minAmountOut < amountOut, "Amount Out Less Than Minimum");

        IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);

        if (tokenIn < tokenOut) {
            LiquidityPool(pair).swap(0, amountOut, to);
        } else {
            LiquidityPool(pair).swap(amountOut, 0, to);
        }
        emit SwapExecuted(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to
    ) external {
        address pair = getPair(address(tokenIn), address(tokenOut));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            tokenOut
        );
        uint256 amountIn = LiquidityPool(pair).getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
        require(maxAmountIn >= amountIn, "Amount Out Less Than Minimum");

        IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
        if (tokenIn < tokenOut) {
            LiquidityPool(pair).swap(0, amountOut, to);
        } else {
            LiquidityPool(pair).swap(amountOut, 0, to);
        }
        emit SwapExecuted(tokenIn, tokenOut, msg.sender, amountIn, amountOut);
    }

    function swapExactEthForTokens(
        address tokenOut,
        uint256 minAmountOut,
        address to
    ) external payable {
        require(msg.value > 0, "ZERO_ETH");
        WETH.deposit{value: msg.value}();
        address pair = getPair(address(WETH), address(tokenOut));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            address(WETH),
            tokenOut
        );
        uint256 amountOut = LiquidityPool(pair).getAmountOut(
            msg.value,
            reserveIn,
            reserveOut
        );
        require(minAmountOut <= amountOut, "Amount Out Less Than Minimum");

        WETH.transfer(pair, msg.value);
        if (address(WETH) < tokenOut) {
            LiquidityPool(pair).swap(0, amountOut, to);
        } else {
            LiquidityPool(pair).swap(amountOut, 0, to);
        }
        emit SwapExecuted(
            address(WETH),
            tokenOut,
            msg.sender,
            msg.value,
            amountOut
        );
    }

    function swapTokensForExactEth(
        address tokenIn,
        uint256 amountOut,
        uint256 maxAmountIn
    ) external {
        address pair = getPair(address(tokenIn), address(WETH));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            address(WETH)
        );
        uint256 amountIn = LiquidityPool(pair).getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
        require(maxAmountIn >= amountIn, "Amount Out Less Than Minimum");

        IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
        if (address(WETH) < tokenIn) {
            LiquidityPool(pair).swap(amountOut, 0, address(this));
        } else {
            LiquidityPool(pair).swap(0, amountOut, address(this));
        }
        WETH.withdraw(amountOut);
        (bool success, ) = msg.sender.call{value: amountOut}("");
        require(success, "Transfer Failed");
        emit SwapExecuted(
            tokenIn,
            address(WETH),
            msg.sender,
            amountIn,
            amountOut
        );
    }

    function swapExactTokensForEth(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) external {
        address pair = getPair(address(tokenIn), address(WETH));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            tokenIn,
            address(WETH)
        );
        uint256 amountOut = LiquidityPool(pair).getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        require(minAmountOut <= amountOut, "Amount Out Less Than Minimum");

        IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
        if (address(WETH) < tokenIn) {
            LiquidityPool(pair).swap(0, amountOut, address(this));
        } else {
            LiquidityPool(pair).swap(amountOut, 0, address(this));
        }
        WETH.withdraw(amountOut);
        (bool success, ) = msg.sender.call{value: amountOut}("");
        require(success, "Transfer Failed");
        emit SwapExecuted(
            tokenIn,
            address(WETH),
            msg.sender,
            amountIn,
            amountOut
        );
    }

    function swapEthForExactTokens(
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to
    ) external payable {
        require(msg.value > 0, "ZERO_ETH");
        WETH.deposit{value: msg.value}();
        address pair = getPair(address(WETH), address(tokenOut));
        (uint256 reserveIn, uint256 reserveOut) = getReserves(
            address(WETH),
            tokenOut
        );
        uint256 amountIn = LiquidityPool(pair).getAmountIn(
            amountOut,
            reserveIn,
            reserveOut
        );
        require(maxAmountIn >= amountIn, "Amount Out Less Than Minimum");

        WETH.transfer(pair, amountIn);
        if (address(WETH) < tokenOut) {
            LiquidityPool(pair).swap(0, amountOut, to);
        } else {
            LiquidityPool(pair).swap(amountOut, 0, to);
        }
        if (msg.value > amountIn) {
            uint256 refund = msg.value - amountIn;
            (bool success, ) = msg.sender.call{value: refund}("");
            require(success, "Refund failed");
        }
        emit SwapExecuted(
            address(WETH),
            tokenOut,
            msg.sender,
            amountIn,
            amountOut
        );
    }

    receive() external payable {}
}
