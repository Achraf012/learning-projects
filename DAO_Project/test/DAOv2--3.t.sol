// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "forge-std/Test.sol";
import "../src/DAO-v2.sol";
import "../src/GovernanceToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/DAO-v3.sol";

contract v2test is Test {
    Token token;
    DAO2 dao;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address tokenOwner = makeAddr("tokenOwner");
    ERC1967Proxy public proxy;
    DAO2 public box;

    function setUp() public {
        vm.prank(tokenOwner);
        token = new Token("money", "mn");
        dao = new DAO2();
        bytes memory initData = abi.encodeWithSelector(
            DAO2.initialize.selector,
            token
        );
        vm.prank(user1);
        proxy = new ERC1967Proxy(address(dao), initData);
        box = DAO2(address(proxy));
    }

    function testInitialState() public view {
        assertEq(box.owner(), user1);
    }

    function testRevertsOnReinitialize() public {
        vm.expectRevert("InvalidInitialization()");
        box.initialize(token);
    }

    function testUpgradeRevertsIfNotOwner() public {
        DAO3 dao3 = new DAO3();
        vm.prank(user2);
        vm.expectRevert();
        box.upgradeToAndCall(address(dao3), "");
    }

    function testInitializeSetsTokenACorrectly() public view {
        assertEq(address(box.token()), address(token));
    }

    function testUpgradeToV3() public {
        DAO3 dao3 = new DAO3();
        bytes memory data = abi.encodeWithSignature("initializeV2()");

        vm.prank(user1);
        box.upgradeToAndCall(address(dao3), data);
        DAO3 dao3proxy = DAO3(address(box));
        assertEq(dao3proxy.owner(), user1);
    }

    function test_secondUpgradeFail() public {
        DAO3 dao3 = new DAO3();
        bytes memory data = abi.encodeWithSignature("initializeV2()");

        vm.prank(user1);
        box.upgradeToAndCall(address(dao3), data);
        DAO3 dao3proxy = DAO3(address(box));
        assertEq(dao3proxy.owner(), user1);
        vm.expectRevert();
        vm.prank(user1);

        box.upgradeToAndCall(address(dao3), data);
    }

    function testUpgradePreservesProposalStorage() public {
        vm.startPrank(user1);
        box.createProposal("you upgraded this succesfully", 15 days);
        DAO3 dao3 = new DAO3();
        bytes memory data = abi.encodeWithSignature("initializeV2()");
        box.upgradeToAndCall(address(dao3), data);
        DAO3 dao3Proxy = DAO3(address(box));

        (uint256 id, string memory description, , , , ) = dao3Proxy.getProposal(
            1
        );
        assertEq(id, 1);
        assertEq(description, "you upgraded this succesfully");
    }
}
