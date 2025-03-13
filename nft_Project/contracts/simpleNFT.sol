// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract MyNFT is ERC721URIStorage, Ownable {
    uint256 public mintingFee = 0.01 ether;
    uint256 public tokenCounter;

    event Minted(string tokenURI, uint256 tokenID);

    constructor() ERC721("Aylas", "MAL") Ownable(msg.sender) {
        tokenCounter = 0;
    }

    function mintNFT(string memory _tokenURI) public payable returns (uint256) {
        require(msg.value >= mintingFee, "Not enough ETH to mint");

        uint256 tokenId = tokenCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        tokenCounter++;

        emit Minted(_tokenURI, tokenId); 

        return tokenId;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
