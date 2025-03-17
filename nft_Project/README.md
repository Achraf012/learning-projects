# MyNFT Project

## 📌 Overview
This is a simple NFT (Non-Fungible Token) smart contract built with Solidity. The contract allows users to mint, approve, and transfer NFTs. The project includes full unit tests written in Hardhat to ensure functionality.

## 🛠️ Features
- Mint NFTs with a unique TokenURI
- Approve another address to transfer NFTs
- Transfer NFTs between users
- Retrieve NFT owner and metadata
- Prevents reentrancy attacks

## 🚀 Technologies Used
- Solidity (Smart Contract Language)
- Hardhat (Development & Testing Framework)
- JavaScript (For Writing Tests)
- Ethers.js (Interacting with the Blockchain)
- OpenZeppelin (Security & Standards)

## 📂 Project Structure
```
nft_Project/
│── contracts/
│   ├── MyNFT.sol          # NFT Smart Contract
│   ├── ReentrancyAttack.sol  # Attack Contract for testing security
│── test/
│   ├── nft.test.js        # Unit Tests for NFT contract
│   ├── attackTest.js      # Tests for reentrancy attack
│── hardhat.config.js      # Hardhat Configuration
│── package.json          # Project Dependencies
│── README.md             # Project Documentation
```

## 🔧 Installation & Setup

### Clone the repository:
```sh
git clone https://github.com/Achraf012/learning-projects.git
cd learning-projects/nft_Project
```

### Install dependencies:
```sh
npm install
```

### Compile the smart contract:
```sh
npx hardhat compile
```

### Run the tests:
```sh
npx hardhat test
```

## 📜 Smart Contract Functions

### 🖼️ Mint NFT
```solidity
function mintNFT(string memory _tokenURI) public payable returns (uint256);
```
- Mints a new NFT with a unique TokenURI.
- Requires a minting fee of **0.01 ETH**.
- Refunds excess ETH.

### ✅ Approve NFT
```solidity
function approve(address to, uint256 tokenID) external;
```
- Allows another address to transfer the NFT.
- Can only be called by the NFT owner.

### 🔄 Transfer NFT
```solidity
function transferFrom(address from, address to, uint tokenID) external;
```
- Transfers an NFT to another address.
- Can be done by the owner or an approved user.

### 🔍 Get Owner of NFT
```solidity
function ownerOf(uint TokenID) public view returns (address);
```
- Returns the owner's address of a specific NFT.

### 🔗 Get Token URI
```solidity
function tokenURI(uint TokenID) public view returns (string memory);
```
- Returns the metadata URI of an NFT.

### 💰 Withdraw Contract Balance
```solidity
function withdraw() external onlyOwner;
```
- Sends all contract funds to the owner.
- Uses **nonReentrant** modifier for security.

## 🔒 Security Features
- **ReentrancyGuard**: Prevents reentrancy attacks on minting and withdrawal.
- **Refund Handling**: Ensures users receive excess ETH back securely.
- **OnlyOwner Protection**: Restricted access to critical functions.

## 📌 Future Improvements
- Add a marketplace for buying and selling NFTs.
- Implement staking for rewards.
- Improve gas optimization and reduce transaction costs.

## 🏆 Author
**Achraf** - Solidity Developer

## 📜 License
This project is licensed under the MIT License.
