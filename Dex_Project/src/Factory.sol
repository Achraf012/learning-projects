// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "./LiquidityPool.sol";

contract factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external {
        require(tokenA != tokenB, "Cant Use Same Token");
        require(getPair[tokenA][tokenB] == address(0), "Pair already exists");

        LiquidityPool Pool = new LiquidityPool();
        Pool.initialize(tokenA, tokenB);
        address pair = address(Pool);
        getPair[tokenA][tokenB] = pair;
        getPair[tokenB][tokenA] = pair;
        allPairs.push(pair);
    }

    function getPairAddress(
        address tokenA,
        address tokenB
    ) external view returns (address) {
        require(tokenA != tokenB, "Cant Use Same Token");
        address pair = getPair[tokenA][tokenB];
        require(pair != address(0), "Pair does not exist");
        return getPair[tokenA][tokenB];
    }
}
