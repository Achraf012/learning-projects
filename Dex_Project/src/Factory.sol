// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "./LiquidityPool.sol";

contract factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address router;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function setRouter(address _router) external {
        require(msg.sender == owner, "Not The Owner");
        require(router == address(0), "Router already set");
        router = _router;
    }

    function getRouter() external view returns (address) {
        return router;
    }

    function createPair(address tokenA, address tokenB) external {
        require(tokenA != tokenB, "Cant Use Same Token");

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(getPair[token0][token1] == address(0), "Pair already exists");

        LiquidityPool pool = new LiquidityPool(router);
        pool.initialize(token0, token1);
        address pair = address(pool);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
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
