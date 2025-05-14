// SPDX-License-Identifier: SEE LICENSE IN LICENSE
import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol"; // Provides assertApproxEqAbs function
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";
import "../src/Dex.sol";
import "../src/Factory.sol";
import "../src/LiquidityPool.sol";
import "../src/tokenA.sol";
import "../src/tokenB.sol";
import "../src/wethToken.sol";

pragma solidity 0.8.27;

contract projectTest is Test {
    LiquidityPool liquidityPool;
    MkToken1 testMkToken1;
    MkToken2 testMkToken2;
    MockWETH weth;
    factory _factory;
    router _router;
    address public owner;
    address user;

    function setUp() public {
        user = makeAddr("user");
        owner = makeAddr("owner");
        _factory = new factory();
        weth = new MockWETH();
        _router = new router(address(_factory), address(weth));
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
    function createAndApprove(address _user) public {
        createPair();
        vm.startPrank(_user);

        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
    }

    function testAddLiquidityUpdatesReservesCorrectly() external {
        createAndApprove(user);
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

    function testAddLiquidityMintsCorrectLPAmount() external {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        uint256 initialTotalSupply = liquidityPool.totalSupply();
        console.log(initialTotalSupply);
        assertGt(initialTotalSupply, 0);
        uint256 userLpBalance = liquidityPool.balanceOf(user);
        assertEq(initialTotalSupply, userLpBalance);
        address token0 = liquidityPool.token0();
        address token1 = liquidityPool.token1();

        uint reserve0 = IERC20(token0).balanceOf(address(liquidityPool));
        uint reserve1 = IERC20(token1).balanceOf(address(liquidityPool));

        (uint r0, uint r1) = liquidityPool.getReserves();

        assertEq(r0, reserve0);
        assertEq(r1, reserve1);
    }

    function testAddLiquidityRevertsIfMinAmountsNotMet() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        vm.stopPrank();
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            200,
            100,
            160,
            100
        );
    }

    function testAddLiquidityFailsIfNotApproved() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        vm.stopPrank();
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), 0);
        testMkToken2.approve(address(_router), 0);
        vm.expectRevert();
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
    }

    function testAddLiquidityCanBeCalledOnlyAfterPoolExists() public {
        vm.startPrank(user);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert(bytes("Pair does not exist"));
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
    }

    function testRemoveLiquidityReturnsCorrectTokenAmounts() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        uint256 userBalance0 = testMkToken1.balanceOf(user);
        uint256 userBalance1 = testMkToken2.balanceOf(user);

        uint256 lpAmount = liquidityPool.balanceOf(user);
        ERC20(address(liquidityPool)).approve(address(_router), lpAmount);

        _router.removeLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            lpAmount,
            0,
            0
        );

        assertApproxEqAbs(userBalance0, 10 * 1e18, 100);
        assertApproxEqAbs(userBalance1, 10 * 1e18, 100);
    }

    function testRemoveLiquidityBurnsLPTokens() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        uint256 lpAmount = liquidityPool.balanceOf(user);
        ERC20(address(liquidityPool)).approve(address(_router), lpAmount);

        _router.removeLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            lpAmount,
            0,
            0
        );

        uint256 userLpBalance = liquidityPool.balanceOf(user);
        assertEq(userLpBalance, 0);
        assertEq(
            liquidityPool.totalSupply(),
            0,
            "Total supply should be zero after removing all liquidity"
        );
    }

    function testRemoveLiquidityFailsIfZeroLPTokens() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        uint256 lpAmountBefore = liquidityPool.balanceOf(user);

        ERC20(address(liquidityPool)).transfer(address(owner), lpAmountBefore);
        uint256 lpAmountafter = liquidityPool.balanceOf(user);
        console.log("before:", lpAmountBefore, "after", lpAmountafter);
        ERC20(address(liquidityPool)).approve(address(_router), lpAmountafter);
        vm.expectRevert();
        _router.removeLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            30,
            0,
            0
        );
    }

    function testRouterCannotAddLiquidityBeforePoolInitialization() public {
        vm.startPrank(user);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert(bytes("Pair does not exist"));
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
    }

    function testLPTokenShareIsFairAcrossMultipleUsers() public {
        createAndApprove(user);
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            100,
            90,
            80,
            60
        );
        ERC20(testMkToken1).transfer(owner, 500);
        ERC20(testMkToken2).transfer(owner, 500);
        vm.stopPrank();
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            200,
            180,
            160,
            120
        );
        uint256 userLpBalance = liquidityPool.balanceOf(user);
        uint256 ownerLpBalance = liquidityPool.balanceOf(owner);

        assertApproxEqAbs(
            userLpBalance * 2,
            ownerLpBalance,
            100,
            "LP token share is not fair across multiple users"
        );
    }

    // ---------------- swaptokens for exact tokens ----------------
    function testSwapExactTokensForTokens_should_swap_and_emit_event() public {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectEmit(true, true, false, true); // indexed1, indexed2, indexed3, data
        emit router.SwapExecuted(
            address(testMkToken1),
            address(testMkToken2),
            msg.sender,
            100,
            62
        );
        _router.swapExactTokensForTokens(
            address(testMkToken1),
            address(testMkToken2),
            100,
            40,
            msg.sender
        );
    }

    function testSwapExactTokensForTokens_should_revert_if_amountOut_less_than_minAmountOut()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapExactTokensForTokens(
            address(testMkToken1),
            address(testMkToken2),
            100,
            63,
            msg.sender
        );
    }

    function testSwapExactTokensForTokens_should_fail_if_insufficient_allowance_or_balance()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapExactTokensForTokens(
            address(testMkToken1),
            address(testMkToken2),
            101,
            40,
            msg.sender
        );
    }

    function testSwapTokensForExactTokens_should_swap_and_emit_event() public {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectEmit(true, true, false, true); // indexed1, indexed2, indexed3, data
        emit router.SwapExecuted(
            address(testMkToken1),
            address(testMkToken2),
            msg.sender,
            100,
            62
        );
        _router.swapTokensForExactTokens(
            address(testMkToken1),
            address(testMkToken2),
            62,
            100,
            msg.sender
        );
    }

    function testSwapTokensForExactTokens_should_revert_if_amountIn_greater_than_maxAmountIn()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapTokensForExactTokens(
            address(testMkToken1),
            address(testMkToken2),
            62,
            63,
            msg.sender
        );
    }

    function testSwapTokensForExactTokens_should_fail_if_insufficient_allowance_or_balance()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(testMkToken2),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapTokensForExactTokens(
            address(testMkToken1),
            address(testMkToken2),
            150,
            101,
            msg.sender
        );
    }

    function testSwapExactTokensForTokens_should_fail_if_pair_does_not_exist()
        public
    {
        vm.startPrank(user);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert(bytes("Pair does not exist"));
        _router.swapExactTokensForTokens(
            address(testMkToken1),
            address(testMkToken2),
            100,
            40,
            msg.sender
        );
    }

    function testSwapTokensForExactTokens_should_fail_if_pair_does_not_exist()
        public
    {
        vm.startPrank(user);
        testMkToken1.approve(address(_router), type(uint256).max);
        testMkToken2.approve(address(_router), type(uint256).max);
        vm.expectRevert(bytes("Pair does not exist"));
        _router.swapTokensForExactTokens(
            address(testMkToken1),
            address(testMkToken2),
            62,
            100,
            msg.sender
        );
    }

    // ---------------- swap-using-ETH ----------------
    function makeandApproveWETH() public {
        vm.startPrank(user);
        vm.deal(user, 100 ether);
        weth.deposit{value: 50 ether}();
        weth.approve(address(_router), type(uint256).max);
        testMkToken1.approve(address(_router), type(uint256).max);
        _factory.createPair(address(testMkToken1), address(weth));
        address liquidityPoolAddress = _factory.allPairs(0);
        liquidityPool = LiquidityPool(liquidityPoolAddress);
    }

    function testSwapExactTokensForETH_should_swap_and_emit_event() public {
        makeandApproveWETH();
        vm.startPrank(user);
        _router.addLiquidity(
            address(testMkToken1),
            address(weth),
            300,
            50,
            0,
            0
        );

        testMkToken1.approve(address(_router), type(uint256).max);
        weth.approve(address(_router), type(uint256).max);
        vm.expectEmit(true, true, false, true); // indexed1, indexed2, indexed3, data
        emit router.SwapExecuted(
            address(testMkToken1),
            address(weth),
            msg.sender,
            100,
            12
        );
        _router.swapExactTokensForEth(address(testMkToken1), 100, 0);
    }

    function testSwapExactTokensForETH_should_revert_if_amountOut_less_than_minAmountOut()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(weth),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        weth.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapExactTokensForEth(address(testMkToken1), 100, 63);
    }

    function testSwapExactTokensForETH_should_fail_if_insufficient_allowance_or_balance()
        public
    {
        vm.startPrank(user);
        createAndApprove(user);
        testMkToken1.transfer(address(owner), 100);
        testMkToken1.approve(address(owner), type(uint256).max);
        _router.addLiquidity(
            address(testMkToken1),
            address(weth),
            300,
            250,
            200,
            150
        );
        vm.startPrank(owner);
        testMkToken1.approve(address(_router), type(uint256).max);
        weth.approve(address(_router), type(uint256).max);
        vm.expectRevert();
        _router.swapExactTokensForEth(address(testMkToken1), 101, 40);
    }
}
