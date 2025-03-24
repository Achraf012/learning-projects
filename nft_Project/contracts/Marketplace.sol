// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title NFT Marketplace
/// @notice A simple marketplace for listing, buying, and managing NFT sales.
/// @author Achraf
/// @custom:security-contact bradjiachraf01@gmail.com
contract nftMarketPlace is Ownable, ReentrancyGuard {
    uint256 private marketPlaceBalance;
    uint256 public marketPlaceFee;

    /// @notice Errors for handling various failures in marketplace operations.
    error NFTNotListed(address nftAddress, uint tokenId);
    error InsufficientFunds(uint price, uint amount);
    error NotTheOwner(address owner, address user);

    error PriceProblem(uint price);
    error DuplicateListing(address listing);
    error InvalidWithdrawal(uint requested, uint available);
    error NoFundsToWithdraw(uint balance);

    /// @notice Events for tracking marketplace actions.
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
    event FeesWithdrawn(address indexed owner, uint256 amount);
    event Received(address sender, uint256 amount);

    /// @notice Stores NFT listing details.
    struct Listing {
        string name;
        address owner;
        uint256 price;
    }

    /// @dev Keeps track of listed NFTs.
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// @dev Stores pending withdrawals for sellers.
    mapping(address => uint256) public pendingWithdrawals;

    /// @param _marketPlaceFee Initial marketplace fee in basis points (100 = 1%)
    constructor(uint256 _marketPlaceFee) Ownable(msg.sender) {
        marketPlaceFee = _marketPlaceFee;
    }

    /// @notice Lists an NFT for sale on the marketplace.
    /// @param nftAddress The address of the NFT contract.
    /// @param tokenId The unique token ID of the NFT.
    /// @param price The listing price.
    /// @param name A custom name for the NFT.
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        string memory name
    ) external {
        Listing storage nftlisting = listings[nftAddress][tokenId];
        IERC721 nft = IERC721(nftAddress);

        if (nft.ownerOf(tokenId) != msg.sender) {
            revert NotTheOwner({owner: nft.ownerOf(tokenId), user: msg.sender});
        }
        if (nftlisting.owner != address(0)) {
            revert DuplicateListing({listing: nftlisting.owner});
        }
        if (
            nft.getApproved(tokenId) != address(this) &&
            !nft.isApprovedForAll(msg.sender, address(this))
        ) {
            revert("Marketplace not approved to transfer this NFT");
        }

        listings[nftAddress][tokenId] = Listing({
            name: name,
            owner: msg.sender,
            price: price
        });
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

    /// @notice Fetches the details of a listed NFT.
    /// @param nft The address of the NFT contract.
    /// @param tokenId The unique token ID.
    /// @return Listing details of the specified NFT.
    function getListing(
        address nft,
        uint tokenId
    ) external view returns (Listing memory) {
        Listing storage nftlisting = listings[nft][tokenId];
        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, tokenId: tokenId});
        }
        return listings[nft][tokenId];
    }

    /// @notice Purchases a listed NFT.
    /// @dev Ensures sufficient payment, transfers ownership, and updates balances.
    /// @param nft The address of the NFT contract.
    /// @param tokenId The unique token ID.
    function buyItem(
        address nft,
        uint256 tokenId
    ) external payable nonReentrant {
        Listing storage nftlisting = listings[nft][tokenId];

        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, tokenId: tokenId});
        }
        if (msg.value < nftlisting.price) {
            revert InsufficientFunds({
                price: nftlisting.price,
                amount: msg.value
            });
        }

        uint256 feeAmount = (nftlisting.price * marketPlaceFee) / 10_000;
        uint256 sellerAmount = msg.value - feeAmount;
        pendingWithdrawals[nftlisting.owner] += sellerAmount;
        marketPlaceBalance += feeAmount;

        IERC721(nft).safeTransferFrom(
            nftlisting.owner,
            msg.sender,
            tokenId,
            ""
        );
        delete listings[nft][tokenId];

        emit ItemSold(msg.sender, nft, tokenId, sellerAmount);
    }

    /// @notice Cancels an NFT listing.
    /// @dev Only the listing owner can cancel.
    /// @param nft The address of the NFT contract.
    /// @param tokenId The unique token ID.
    function cancelListing(address nft, uint256 tokenId) external {
        Listing storage nftlisting = listings[nft][tokenId];

        if (nftlisting.owner == address(0)) {
            revert NFTNotListed({nftAddress: nft, tokenId: tokenId});
        }
        if (nftlisting.owner != msg.sender) {
            revert NotTheOwner({owner: nftlisting.owner, user: msg.sender});
        }

        emit ListingCancelled(msg.sender, nft, tokenId);
        delete listings[nft][tokenId];
    }

    /// @notice Updates the price of a listed NFT.
    /// @dev Only the owner can update the price.
    /// @param nft The address of the NFT contract.
    /// @param tokenId The unique token ID.
    /// @param newPrice The new listing price.
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
            revert NFTNotListed({nftAddress: nft, tokenId: tokenId});
        }
        if (nftlisting.owner != msg.sender) {
            revert NotTheOwner({owner: nftlisting.owner, user: msg.sender});
        }

        nftlisting.price = newPrice;
        emit PriceUpdated(msg.sender, nft, tokenId, newPrice);
    }

    /// @notice Withdraws the seller's earnings from NFT sales.
    function withdrawFunds() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        if (amount == 0) {
            revert NoFundsToWithdraw({balance: amount});
        }

        pendingWithdrawals[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    /// @notice Withdraws accumulated marketplace fees (only for owner).
    /// @param amount The amount to withdraw.
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
        emit FeesWithdrawn(owner(), amount);
    }

    /// @notice Fallback function to receive payments.
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
