// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract BoxUUPS is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public value;

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
    }

    function setValue(uint256 _value) external virtual {
        value = _value;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
