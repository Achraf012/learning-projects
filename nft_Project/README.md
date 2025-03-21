# NFT Marketplace Project

## 📌 What is this project?

This project is a decentralized NFT marketplace built with Solidity. It allows users to mint NFTs, list them for sale, buy, and cancel listings. The marketplace also includes security features to prevent reentrancy attacks and ensures safe transactions.

## 🤔 Why build this?

Traditional NFT marketplaces often face security vulnerabilities such as reentrancy attacks and improper fund handling. This project aims to provide a secure, transparent, and efficient platform where users can trade NFTs safely while ensuring fair fee deductions and preventing malicious activities.

## 📝 Contracts

### 1. **SimpleNFT.sol**

- ERC721 contract for minting NFTs.
- Includes a refund function for unsuccessful transactions.
- Integrated with **ReentrancyAttack.sol** for testing security vulnerabilities.

### 2. **ReentrancyAttack.sol**

- Designed to simulate reentrancy attacks against the **SimpleNFT.sol** contract.
- Used for testing the security of the refund function.

### 3. **Marketplace.sol**

- A marketplace contract where users can list their NFTs for sale.
- Implements listing, buying, price updates, and listing cancellations.
- Ensures secure transactions with **ReentrancyGuard**.
- Implements marketplace fees.

## ✨ Features

✅ **Mint NFTs**: Users can create unique ERC721 tokens.

✅ **Secure Listings**: Only NFT owners can list their assets.

✅ **Buy & Sell**: Users can securely buy NFTs listed on the marketplace.

✅ **Reentrancy Protection**: The contracts are tested against reentrancy vulnerabilities.

✅ **Refund Mechanism**: A refund function is included for cases where transactions fail.


✅ **Marketplace Fees**: Ensures fair transactions with a small fee deduction.

## 🛠️ Tests

The test suite includes:

- **Unit Tests for SimpleNFT.sol**:
  - ✅ NFT minting
  - ✅ Refund function security
  - ✅ Ownership checks
- **Security Tests using ReentrancyAttack.sol**:
  - ✅ Reentrancy attacks on refund function
- **Unit Tests for Marketplace.sol**:
  - ✅ Listing NFTs
  - ✅ Buying NFTs
  - ✅ Updating prices
  - ✅ Canceling listings
  - ✅ Fee deduction verification

## ⚙️ Installation & Usage

### Prerequisites

- Node.js & npm
- Hardhat
- OpenZeppelin Contracts

### Setup

```sh
npm install
```

### Run Tests

```sh
npx hardhat test
```

### Deploy Contracts

```sh
npx hardhat run scripts/deploy.js --network <network>
```

### Interacting with Contracts

- After deployment, interact with the marketplace using scripts or Hardhat console:

```sh
npx hardhat console --network <network>
```

- Call functions like `mintNFT()`, `listNFT()`, `buyNFT()`, and `cancelListing()`.

## 📜 License

This project is licensed under the MIT License.

