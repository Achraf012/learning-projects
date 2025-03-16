// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MyNFT - A Simple ERC721 NFT Contract
/// @author Achraf
/// @notice This contract allows users to mint NFTs by paying a minting fee.
/// @dev Uses OpenZeppelin's ERC721URIStorage for metadata management.

contract MyNFT is ERC721URIStorage, Ownable, ReentrancyGuard {
    /// @dev This value is immutable and set to `0.01 ether` at deployment.
    uint256 public immutable mintingFee = 0.01 ether;
    /// @dev This value increments with each mint operation.
    uint256 public tokenCounter;

    event Minted(string tokenURI, uint256 tokenID);
    event Withdrawn(address owner, uint amount);

    constructor() ERC721("Aylas", "MAL") Ownable(msg.sender) {
        tokenCounter = 0;
    }

    function mintNFT(string memory _tokenURI) public payable returns (uint256) {
        require(msg.value >= mintingFee, "Not enough ETH to mint");

        uint256 tokenId = tokenCounter;
        unchecked {
            tokenCounter++;
        }
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        /// @dev Refunds any excess ETH sent by the caller.
        /// @notice Ensures that users do not overpay unintentionally.
        uint256 excessAmount = msg.value - mintingFee;
        if (excessAmount > 0) {
            (bool refund, ) = payable(msg.sender).call{value: excessAmount}("");
            require(refund, "Refund failed");
        }

        emit Minted(_tokenURI, tokenId);

        return tokenId;
    }

    function withdraw() external nonReentrant onlyOwner {
        /// @notice Withdraws all ETH from the contract to the owner.
        /// @dev Uses `call` instead of `transfer` to prevent gas-related issues.
        uint256 amount = address(this).balance;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "ETH transfer failed");
        emit Withdrawn(owner(), amount);
    }
}
