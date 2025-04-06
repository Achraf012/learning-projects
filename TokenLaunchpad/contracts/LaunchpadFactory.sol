// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import ./TokenSale.sol;
contract LuanchpadFactory is Ownable(msg.sender), ReentrancyGuard {
  
    address[] public allTokenSales;
    function createTokenSale(address _token,uint256 _price) onlyOwner{
        TokenSale newSale = new TokenSale(_token,_price);
    }

}
