// File: src/BoxV2.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../src/BoxUUPS.sol";

contract BoxV2 is BoxUUPS {
    /// @notice new V2 function
    function setValue(uint256 _value) external override onlyOwner {}

    function add() external {
        value += 1;
    }

    /// @notice marker to prove we’re on V2
}
