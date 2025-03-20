// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract nftMarketPlace is Ownable, ReentrancyGuard {
    uint256 private marketPlaceBalance;
    uint256 public marketPlaceFee = 100;
    error NFTNotListed(address nftAddress, uint theID);
    error InsufficientFunds(uint price, uint amount);
    error NotTheOwner(address owner, address user);
    error ZeroAdrress(address listing);
    error PriceProblem(uint price);
    error duplicateListing(address listing);
    error InvalidWithdrawal(uint requested, uint available);
    event ItemListed(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 price
    );
    event ItemSold(
        address indexed buyer,
        address indexed nft,
        uint256 tokenId,
        uint256 price
    );
    event ListingCancelled(
        address indexed owner,
        address indexed nft,
        uint256 tokenId
    );
    event PriceUpdated(
        address indexed owner,
        address indexed nft,
        uint256 tokenId,
        uint256 newPrice
    );
    event Received(address sender, uint256 amount);

    struct Listing {
        string name;
        address owner;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    constructor(uint256 _marketPlaceFee) Ownable(msg.sender) {
        marketPlaceFee = _marketPlaceFee;
    }

    function listItem(
        address nftAdrress,
        uint256 tokenId,
        uint256 price,
        string memory name
    ) external {
        Listing storage nftlisting = listings[nftAdrress][tokenId];
        IERC721 nft = IERC721(nftAdrress);
        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NotTheOwner({owner: nft.ownerOf(tokenId), user: msg.sender});
        }
        if (nftlisting.owner != address(0)) {
            revert duplicateListing({listing: nftlisting.owner});
        }
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert("Marketplace not approved to transfer this NFT");
        }
        listings[nftAdrress][tokenId] = Listing({
            name: name,
            owner: msg.sender,
            price: price
        });
        emit ItemListed(msg.sender, nftAdrress, tokenId, price);
    }

    function getListing(
        address nft,
        uint tokenId
    ) external view returns (Listing memory) {
        Listing storage nftlisting = listings[nft][tokenId];
        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, theID: tokenId});
        }
        return listings[nft][tokenId];
    }

    function buyItem(
        address nft,
        uint256 tokenId
    ) external payable nonReentrant {
        Listing storage nftlisting = listings[nft][tokenId];
        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, theID: tokenId});
        }
        if (msg.value < nftlisting.price) {
            revert InsufficientFunds({
                price: nftlisting.price,
                amount: msg.value
            });
        }
        uint256 feeAmount = (nftlisting.price * marketPlaceFee) / 10_000;

        IERC721(nft).safeTransferFrom(
            nftlisting.owner,
            msg.sender,
            tokenId,
            bytes("")
        );
        delete listings[nft][tokenId];
        (bool success, ) = payable(nftlisting.owner).call{
            value: msg.value - feeAmount
        }("");
        require(success, "transfer failed");
        (bool feeSuccess, ) = payable(address(this)).call{value: feeAmount}("");
        require(feeSuccess, "Fee transfer failed");

        emit ItemSold(msg.sender, nft, tokenId, msg.value - feeAmount);
        marketPlaceBalance += feeAmount;
    }

    function cancelListing(address nft, uint256 tokenId) external {
        Listing storage nftlisting = listings[nft][tokenId];

        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, theID: tokenId});
        }

        if (nftlisting.owner != msg.sender) {
            revert NotTheOwner({owner: nftlisting.owner, user: msg.sender});
        }
        emit ListingCancelled(msg.sender, nft, tokenId);
        delete listings[nft][tokenId];
    }

    function updatePrice(
        address nft,
        uint256 tokenId,
        uint256 newPrice
    ) external {
        Listing storage nftlisting = listings[nft][tokenId];

        if (newPrice <= 0) {
            revert PriceProblem({price: newPrice});
        }
        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, theID: tokenId});
        }

        if (nftlisting.owner != msg.sender) {
            revert NotTheOwner({owner: nftlisting.owner, user: msg.sender});
        }

        nftlisting.price = newPrice;
        emit PriceUpdated(msg.sender, nft, tokenId, newPrice);
    }

    function withdrawFees(uint amount) external onlyOwner {
        if (amount > marketPlaceBalance || amount <= 0) {
            revert InvalidWithdrawal({
                available: marketPlaceBalance,
                requested: amount
            });
        }
        marketPlaceBalance -= amount;
        (bool transfer, ) = payable(owner()).call{value: amount}("");
        require(transfer, "Withdrawal failed");
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
