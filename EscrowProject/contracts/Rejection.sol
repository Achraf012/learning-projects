// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

contract RejectsEther {
    fallback() external payable {
        revert("I don't accept ETH");
    }

    receive() external payable {
        revert("Nope");
    }
}
