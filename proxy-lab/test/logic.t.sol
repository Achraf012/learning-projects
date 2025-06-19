// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../lib/forge-std/src/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/logic1.sol";
import "../src/logic2.sol";
import "../src/mockToken.sol";

contract logicTest is Test {
    address owner = address(0x1234);
    address partner = address(0x4324);
    address user = address(0x3412);
    Logic1 public logic;
    ERC1967Proxy public proxy;
    Logic1 public box;
    MkToken public mockToken;

    function setUp() public {
        logic = new Logic1();
        bytes memory initData = abi.encodeWithSelector(
            Logic1.initialize.selector,
            partner
        );
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(logic), initData);
        box = Logic1(address(proxy));
        vm.prank(user);
        mockToken = new MkToken("TOKEN", "TKN");
    }

    function testInitialState() public view {
        assertEq(box.owner(), owner);
    }

    function testSplitEth() public {
        vm.deal(user, 100);
        vm.prank(user);
        box.deposit{value: 40}();
        assertEq(box.partnerBalance(), 20);
        vm.prank(user);
        box.deposit{value: 25}();
        assertEq(box.ownerBalance(), 33);
    }

    function test_Upgrade_And_SplitToken() public {
        Logic2 logic2 = new Logic2();
        vm.prank(owner);
        box.upgradeToAndCall(address(logic2), "");
        vm.startPrank(user);
        Logic2 box2 = Logic2(address(proxy));
        mockToken.approve(address(box2), 100);
        box2.depositTokens(100, IERC20(mockToken));
        assertEq(box.partnerBalance(), 50);
    }
}
