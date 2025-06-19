// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract Logic1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    address payable partner;
    uint256 public ownerBalance;
    uint256 public partnerBalance;

    function initialize(address payable _partner) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        partner = _partner;
    }

    function split(uint256 amount) internal {
        uint256 half1 = amount / 2;
        uint256 half2 = amount - half1;
        (bool success, ) = owner().call{value: half2}("");
        require(success, "transfer failed");
        (bool success2, ) = partner.call{value: half1}("");
        require(success2, "transfer failed");
        ownerBalance += half2;
        partnerBalance += half1;
    }

    function deposit() external payable {
        uint256 value = msg.value;
        require(value > 0, "must deposit more than 0");
        split(value);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
