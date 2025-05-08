// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "./LiquidityPool.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract factory is ReentrancyGuard {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address router;
    address immutable owner;
    event RouterSet(address indexed owner, address indexed Router);

    constructor() {
        owner = msg.sender;
    }

    function setRouter(address _router) external {
        require(_router != address(0), "Address Not Available ( 0 Address)");
        require(msg.sender == owner, "Not The Owner");
        require(router == address(0), "Router already set");
        router = _router;
        emit RouterSet(msg.sender, _router);
    }

    function getRouter() external view returns (address) {
        return router;
    }

    function createPair(address tokenA, address tokenB) external nonReentrant {
        require(tokenA != tokenB, "Cant Use Same Token");

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(getPair[token0][token1] == address(0), "Pair already exists");
        LiquidityPool pool = new LiquidityPool(router);
        address pair = address(pool);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        pool.initialize(token0, token1);
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
