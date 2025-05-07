// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "../src/Dex.sol";
import "../src/Factory.sol";
import "../src/LiquidityPool.sol";
import "../src/tokenA.sol";
import "../src/tokenB.sol";

pragma solidity 0.8.27;

contract projectTest is Test {
    LiquidityPool liquidityPool;
    MkToken1 testMkToken1;
    MkToken2 testMkToken2;
    factory _factory;
    router _router;
    address public owner;
    address user;

    function setUp() public {
        user = makeAddr("user");
        owner = makeAddr("owner");
        _factory = new factory();
        _router = new router(address(_factory));
        _factory.setRouter(address(_router));
        vm.startPrank(user);
        testMkToken1 = new MkToken1("TOKEN1", "TK1");
        testMkToken2 = new MkToken2("TOKEN2", "TK2");
        vm.stopPrank();
    }

    function createPair() public {
        _factory.createPair(address(testMkToken1), address(testMkToken2));
        address liquidityPoolAddress = _factory.allPairs(0);
        liquidityPool = LiquidityPool(liquidityPoolAddress);
    }

    function testLPAddress() external {
        createPair();
        console.log(_factory.allPairs(0));
        vm.expectRevert(bytes("Pair already exists"));
        _factory.createPair(address(testMkToken2), address(testMkToken1));
    }

    function testInitializeFail_WrongCaller() external {
        createPair();
        (uint256 reserve1, uint256 reserve2) = liquidityPool.getReserves();
        console.log(reserve1, reserve2);
        vm.expectRevert(bytes("not allowed"));
        vm.prank(user);
        liquidityPool.initialize(address(testMkToken1), address(testMkToken2));
    }

    function testRevert_SameToken() external {
        vm.expectRevert(bytes("Cant Use Same Token"));
        _factory.createPair(address(testMkToken1), address(testMkToken1));
    }

    function testRevert_InitializeDoubleCall() external {
        createPair();

        vm.startPrank(address(_factory));
        vm.expectRevert(bytes("Pair already exists"));
        _factory.createPair(address(testMkToken1), address(testMkToken2));
    }

    // ---------------  Router - Add/Remove Liquidity-----------------------------
    function testAddLiquidityUpdatesReservesCorrectly() external {
        createPair();
        vm.startPrank(user);

        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );

        (uint256 reserve0, uint256 reserve1) = _router.getReserves(
            address(testMkToken1),
            address(testMkToken2)
        );

        assertEq(reserve0, 100);
        assertEq(reserve1, 90);
    }
}
