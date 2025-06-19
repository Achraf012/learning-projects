// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;
import "../src/logic1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

using SafeERC20 for IERC20;

contract Logic2 is Logic1 {
    function depositTokens(uint256 amount, IERC20 token) external {
        require(amount > 0);
        require(address(token) != address(0));
        token.safeTransferFrom(msg.sender, address(this), amount);
        splitTokens(amount, token);
    }

    function splitTokens(uint256 amount, IERC20 token) internal {
        uint256 half1 = amount / 2;
        uint256 half2 = amount - half1;
        token.safeTransfer(owner(), half2);
        token.safeTransfer(partner, half1);
        ownerBalance += half2;
        partnerBalance += half1;
    }
}
