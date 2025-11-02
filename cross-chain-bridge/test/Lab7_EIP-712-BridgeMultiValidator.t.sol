// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "forge-std/Test.sol";
import "../src/Lab7_EIP-712-BridgeMultiValidator.sol";

contract Lab7Test is Test {
    address owner;
    address user;
    address val1;
    address val2;
    address val3;
    address val4;
    uint256 val1PK;
    uint256 val2PK;
    uint256 val3PK;
    uint256 val4PK;

    BridgeEIP712 bridge;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        val1PK = 0x3a;
        val2PK = 0x32a;
        val3PK = 0x3b;
        val4PK = 0x2f;
        val1 = vm.addr(val1PK);
        val2 = vm.addr(val2PK);
        val3 = vm.addr(val3PK);
        val4 = vm.addr(val4PK);
        vm.startPrank(owner);
        bridge = new BridgeEIP712();
        address[] memory vals = new address[](3);
        vals[0] = val1;
        vals[1] = val2;
        vals[2] = val3;
        bridge.setValidators(vals, 2);
        vm.stopPrank();
        vm.deal(user, 10 ether);
    }

    function signWith3Sigs() public view returns (bytes[] memory) {
        bytes32 hashedMSG = bridge.digest(user, 1 ether, 1, 1, 2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, hashedMSG);
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(val2PK, hashedMSG);
        (uint8 d, bytes32 w, bytes32 t) = vm.sign(val3PK, hashedMSG);
        bytes memory sig1 = abi.encodePacked(r, s, v);
        bytes memory sig2 = abi.encodePacked(b, c, a);
        bytes memory sig3 = abi.encodePacked(w, t, d);
        bytes[] memory sigs = new bytes[](3);

        sigs[0] = sig1;
        sigs[1] = sig2;
        sigs[2] = sig3;

        return sigs;
    }

    function signWith2Sigs() public view returns (bytes[] memory) {
        bytes32 hashedMSG = bridge.digest(user, 1 ether, 1, 1, 2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, hashedMSG);
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(val2PK, hashedMSG);

        bytes memory sig1 = abi.encodePacked(r, s, v);
        bytes memory sig2 = abi.encodePacked(b, c, a);

        bytes[] memory sigs = new bytes[](2);

        sigs[0] = sig1;
        sigs[1] = sig2;

        return sigs;
    }

    function signWith1Sig() public view returns (bytes[] memory) {
        bytes32 hashedMSG = bridge.digest(user, 1 ether, 1, 1, 2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, hashedMSG);

        bytes memory sig1 = abi.encodePacked(r, s, v);

        bytes[] memory sigs = new bytes[](1);

        sigs[0] = sig1;

        return sigs;
    }

    function testVerifyWithThresholdSignatures() external view {
        bytes[] memory sigs = signWith3Sigs();
        bool verified = bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs);
        assertTrue(verified);
        bytes[] memory sigs2 = signWith2Sigs();
        bool verified2 = bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs2);
        assertTrue(verified2);
    }

    function testVerifyWithInsufficientSignatures() external view {
        bytes[] memory sigs3 = signWith1Sig();
        bool verified3 = bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs3);
        assertFalse(verified3);
    }

    function testVerifyWithInvalidSigner() external {
        bytes32 hashedMSG = bridge.digest(user, 1 ether, 1, 1, 2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, hashedMSG);
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(val2PK, hashedMSG);
        (uint8 d, bytes32 w, bytes32 t) = vm.sign(val4PK, hashedMSG);
        bytes memory sig1 = abi.encodePacked(r, s, v);
        bytes memory sig2 = abi.encodePacked(b, c, a);
        bytes memory sig4 = abi.encodePacked(w, t, d);
        bytes[] memory sigs = new bytes[](3);

        sigs[0] = sig1;
        sigs[1] = sig2;
        sigs[2] = sig4;
        vm.expectRevert("Invalid signer");
        bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs);
    }

    function testFuzz_DigestConsistency(
        address randomUser,
        uint256 amount
    ) external view {
        bytes32 hashedMSG = bridge.digest(randomUser, amount, 1, 1, 2);
        bytes32 hashedMSG1 = bridge.digest(randomUser, amount, 1, 1, 2);
        assertEq(hashedMSG, hashedMSG1);
    }

    function testPreventReplay() external {
        bytes[] memory sigs = signWith3Sigs();
        bool verified = bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs);
        assertTrue(verified);
        bridge.claimTokensWithProof(user, 1 ether, 1, 2, 1, sigs);
        vm.expectRevert();
        bridge.claimTokensWithProof(user, 1 ether, 1, 2, 1, sigs);
    }

    function testNonOwnerSetValidators() external {
        address[] memory vals = new address[](3);
        vals[0] = val1;
        vals[1] = val2;
        vals[2] = val4;
        vm.prank(user);
        vm.expectRevert();
        bridge.setValidators(vals, 1);
    }

    function testValidatorCountEnforced() external {
        address[] memory vals = new address[](3);
        vals[0] = val1;
        vals[1] = val2;
        vals[2] = val4;
        vm.prank(owner);
        vm.expectRevert("threshold cannot exceed number of validators.");
        bridge.setValidators(vals, 5);
    }

    function testTooManySignatures() public {}

    function testDuplicateSigner() public {
        bytes32 msgHash = bridge.digest(user, 1 ether, 1, 1, 2);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, msgHash);

        bytes memory sig1 = abi.encodePacked(r, s, v);

        bytes[] memory sigs = new bytes[](2);
        sigs[0] = sig1;
        sigs[1] = sig1;

        vm.expectRevert("Duplicate signer");
        bridge.verifySignatures(user, 1 ether, 1, 1, 2, sigs);
    }

    function testFuzz_VerifySignatures(
        address randomUser,
        uint256 amount
    ) public view {
        bytes32 hashedMSG = bridge.digest(randomUser, amount, 1, 1, 1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(val1PK, hashedMSG);
        (uint8 a, bytes32 b, bytes32 c) = vm.sign(val2PK, hashedMSG);
        (uint8 d, bytes32 w, bytes32 t) = vm.sign(val3PK, hashedMSG);
        bytes memory sig1 = abi.encodePacked(r, s, v);
        bytes memory sig2 = abi.encodePacked(b, c, a);
        bytes memory sig3 = abi.encodePacked(w, t, d);
        bytes[] memory sigs = new bytes[](3);

        sigs[0] = sig1;
        sigs[1] = sig2;
        sigs[2] = sig3;
        bool verified = bridge.verifySignatures(
            randomUser,
            amount,
            1,
            1,
            1,
            sigs
        );
        assertTrue(verified);
    }
}
