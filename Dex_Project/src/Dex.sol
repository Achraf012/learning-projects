// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Factory.sol";
import "./LiquidityPool.sol";

contract router {
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
}
