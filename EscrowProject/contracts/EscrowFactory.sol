// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;
import "../contracts/Escrow.sol";

contract Factory {
    mapping(address => address[]) Escrows;

    event EscrowCreated(
        address indexed owner,
        address seller,
        address buyer,
        address arbitrator,
        uint32 duration
    );

    function createEscrow(
        address payable _seller,
        address _arbitrator,
        address _buyer,
        uint128 _amount,
        uint32 duration
    ) external {
        Escrow escrow = new Escrow(
            _seller,
            _arbitrator,
            _buyer,
            _amount,
            duration
        );
        Escrows[msg.sender].push(address(escrow));
        emit EscrowCreated(msg.sender, _seller, _buyer, _arbitrator, duration);
    }

    function getUserEscrows(
        address user
    ) external view returns (address[] memory) {
        return Escrows[user];
    }
}
