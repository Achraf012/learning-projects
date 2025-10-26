// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "./Lab2_BridgeMessageVerifier-2-.sol";

contract BridgeCore {
    BridgeMessageVerifier verifier;
    address validator;
    // balances and usedNonces are public just to make tests easier -_0;
    mapping(address => uint256) public balances;
    mapping(address => mapping(uint256 => bool)) public usedNonces;
    error PriceProblem(uint256 value, uint256 amount);
    error NonceAlreadyUsed();
    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 nonce,
        uint256 targetChainId
    );

    constructor(address _validator, BridgeMessageVerifier _verifier) {
        validator = _validator;
        verifier = _verifier;
    }

    function deposit(
        uint256 amount,
        uint256 nonce,
        uint256 targetChainId
    ) external payable {
        if (amount != msg.value) {
            revert PriceProblem(msg.value, amount);
        }
        if (usedNonces[msg.sender][nonce]) revert NonceAlreadyUsed();

        balances[msg.sender] += amount;
        usedNonces[msg.sender][nonce] = true;
        emit Deposit(msg.sender, amount, nonce, targetChainId);
    }
}
