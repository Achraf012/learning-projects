// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SignatureVerifier {
    address public validator;

    constructor(address _validator) {
        validator = _validator;
    }

    function verify(
        bytes32 messageHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        bytes32 ethSignedHash = getEthSignedMessageHash(messageHash);
        address signer = ECDSA.recover(ethSignedHash, v, r, s);
        return signer == validator;
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }
}
