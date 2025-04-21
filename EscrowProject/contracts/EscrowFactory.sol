// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;
import "../contracts/Escrow.sol";

contract Factory {
    mapping(address => address[]) Escrows;
    error InvalidDeadline();
    error InvalidFeeAmount();

    event FeeRecipientSet(address feeRecipient);
    event EscrowCreated(
        address indexed owner,
        address seller,
        address buyer,
        address arbitrator,
        uint32 duration,
        uint16 fee
    );

    function createEscrow(
        address payable _seller,
        address _arbitrator,
        address payable _feeRecipient,
        address _buyer,
        uint128 _amount,
        uint32 duration,
        uint16 _feeAmount
    ) external {
        if (duration < 3600 || duration > 30 days) {
            revert InvalidDeadline();
        }
        if (_feeAmount < 1 || _feeAmount > 5) {
            revert InvalidFeeAmount();
        }
        Escrow escrow = new Escrow(
            _seller,
            _arbitrator,
            _feeRecipient,
            _buyer,
            _amount,
            duration,
            _feeAmount
        );
        Escrows[msg.sender].push(address(escrow));
        emit EscrowCreated(
            msg.sender,
            _seller,
            _buyer,
            _arbitrator,
            duration,
            _feeAmount
        );
        emit FeeRecipientSet(_feeRecipient);
    }

    function getUserEscrows(
        address user
    ) external view returns (address[] memory) {
        return Escrows[user];
    }
}
