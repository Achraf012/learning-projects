// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityPool is ERC20 {
    using SafeERC20 for IERC20;
    address public factory;
    address public token0;
    address public token1;
    uint256 reserve0;
    uint256 reserve1;
    bool initialized;

    constructor() ERC20("LP Token", "LPT") {
        factory = msg.sender;
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
    }

    function getReserves() public view returns (uint256, uint256) {
        return (reserve0, reserve1);
    }

    function _updateReserves() internal {
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
    }

    function addLiquidity(uint amount0, uint amount1) external {
        require(initialized, "Not Initialized");
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);
        uint256 mintAmount;
        if (totalSupply() == 0) {
            mintAmount = sqrt(amount0 * amount1);
        } else {
            uint256 share0 = (amount0 * totalSupply()) / reserve0;
            uint256 share1 = (amount1 * totalSupply()) / reserve1;
            mintAmount = min(share0, share1);
        }
        _mint(msg.sender, mintAmount);
        _updateReserves();
    }

    function removeLiquidity(uint256 lp) external {
        require(initialized, "Not Initialized");

        uint256 tokenAmount0 = (lp * reserve0) / totalSupply();
        uint256 tokenAmount1 = (lp * reserve1) / totalSupply();
        _burn(msg.sender, lp);
        IERC20(token0).safeTransfer(msg.sender, tokenAmount0);
        IERC20(token1).safeTransfer(msg.sender, tokenAmount1);
        _updateReserves();
    }

    function swap(uint amountIn, address tokenIn) external {
        require(initialized, "Not Initialized");

        require(tokenIn == token0 || tokenIn == token1, "Invalid token");

        bool isToken0In = tokenIn == token0;
        address tokenOut = isToken0In ? token1 : token0;
        uint reserveIn = isToken0In ? reserve0 : reserve1;
        uint reserveOut = isToken0In ? reserve1 : reserve0;

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint amountInWithFee = amountIn * 997;

        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        uint amountOut = numerator / denominator;

        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);

        _updateReserves();
    }

    function getAmountOut(
        uint amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        uint256 amountOut = numerator / denominator;
        return amountOut;
    }

    function getAmountOutView(
        uint amountIn
    ) external view returns (uint amountOut) {
        (uint reserveIn, uint reserveOut) = getReserves();
        return getAmountOut(amountIn, reserveIn, reserveOut);
    }
}
