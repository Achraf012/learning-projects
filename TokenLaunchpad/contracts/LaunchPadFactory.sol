// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenSale.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LaunchpadFactory is Ownable(msg.sender) {
    // Store all deployed token sale contracts
    address[] public tokenSales;

    event TokenSaleCreated(address indexed tokenSaleAddress);

    // Function to create a new token sale
    function createTokenSale(
        vesting _vestingContract,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        IERC20 _tokenAddress,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _softCap,
        uint256 _hardCap,
        tokenSale.SaleType _saleType,
        uint256 _totalTokensForSale
    ) external onlyOwner {
        // Deploy the new TokenSale contract
        tokenSale newSale = new tokenSale(
            _vestingContract,
            _cliffDuration,
            _vestingDuration,
            _tokenAddress,
            _price,
            _startTime,
            _endTime,
            _softCap,
            _hardCap,
            _saleType,
            _totalTokensForSale
        );

        // Track the deployed sale
        tokenSales.push(address(newSale));

        emit TokenSaleCreated(address(newSale));
    }

    function getAllTokenSales() external view returns (address[] memory) {
        return tokenSales;
    }
}
