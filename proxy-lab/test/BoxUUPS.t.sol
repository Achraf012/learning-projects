// File: test/ProxyTest.t.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import "forge-std/Test.sol";
import "../src/BoxUUPS.sol";
import "../src/box2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ProxyTest is Test {
    address owner = address(0x1234);
    address user = address(0x4324);

    BoxUUPS public logicV1;
    ERC1967Proxy public proxy;
    BoxUUPS public box;

    function setUp() public {
        // 1) Deploy V1 logic
        logicV1 = new BoxUUPS();

        // 2) Encode initialize(owner)
        bytes memory initData = abi.encodeWithSelector(
            BoxUUPS.initialize.selector,
            owner
        );

        // 3) Deploy proxy as `owner`
        vm.prank(owner);
        proxy = new ERC1967Proxy(address(logicV1), initData);

        // 4) Wrap proxy with V1 interface
        box = BoxUUPS(address(proxy));
    }

    function testInitialState() public {
        assertEq(box.owner(), owner);
        assertEq(box.value(), 0);
    }

    function testSetValue() public {
        vm.prank(user);
        box.setValue(42);
        assertEq(box.value(), 42);
    }

    function testUpgradeAndAdd() public {
        vm.prank(owner);
        box.setValue(42);
        assertEq(box.value(), 42);

        BoxV2 logicV2 = new BoxV2();

        vm.prank(owner);

        BoxUUPS(address(proxy)).upgradeToAndCall(address(logicV2), "");

        BoxV2 boxV2 = BoxV2(address(proxy));
        boxV2.add();
        assertEq(boxV2.value(), 43);

        vm.prank(user);
        vm.expectRevert();
        box.setValue(42);
    }
}
