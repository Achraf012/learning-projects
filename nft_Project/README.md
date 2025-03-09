# MyNFT Project

## 📌 Overview
This is a simple **NFT (Non-Fungible Token) smart contract** built with Solidity. The contract allows users to **mint, approve, and transfer NFTs**. The project includes full **unit tests** written in Hardhat to ensure functionality.

## 🛠️ Features
- **Mint NFTs** with a unique `TokenURI`
- **Approve another address** to transfer NFTs
- **Transfer NFTs** between users
- **Retrieve NFT owner and metadata**

## 🚀 Technologies Used
- **Solidity** (Smart Contract Language)
- **Hardhat** (Development & Testing Framework)
- **JavaScript** (For Writing Tests)
- **Ethers.js** (Interacting with the Blockchain)

## 📂 Project Structure
```
nft_Project/
│── contracts/
│   ├── MyNFT.sol        # NFT Smart Contract
│── test/
│   ├── MyNFT.test.js    # Unit Tests
│── hardhat.config.js    # Hardhat Configuration
│── package.json        # Project Dependencies
│── README.md           # Project Documentation
```

## 🔧 Installation & Setup
1. **Clone the repository:**
   ```sh
   git clone https://github.com/Achraf012/learning-projects.git
   cd learning-projects/nft_Project
   ```
2. **Install dependencies:**
   ```sh
   npm install
   ```
3. **Compile the smart contract:**
   ```sh
   npx hardhat compile
   ```
4. **Run the tests:**
   ```sh
   npx hardhat test
   ```

## 📜 Smart Contract Functions
### 🖼️ Mint NFT
```solidity
function Mint(string memory _TokenURI) public returns (uint);
```
- **Mints** a new NFT with a unique `TokenURI`
- **Increments** the TokenCounter

### ✅ Approve NFT
```solidity
function approve(address to, uint256 tokenID) external;
```
- **Allows** another address to transfer the NFT
- **Owner only** can approve

### 🔄 Transfer NFT
```solidity
function transferNFT(address to, uint tokenID) external;
```
- **Transfers** an NFT to another address
- Can be done by **owner or approved user**

### 🔍 Get Owner of NFT
```solidity
function OwnerOf(uint TokenID) public view returns (address);
```
- **Returns** the owner's address of a specific NFT

### 🔗 Get Token URI
```solidity
function TokenURI(uint TokenID) public view returns (string memory);
```
- **Returns** the metadata URI of an NFT

## 📌 Future Improvements
- Add a **marketplace** for buying and selling NFTs
- Implement **staking** for rewards
- Improve **security** and gas optimization

## 🏆 Author
- **Achraf** - Solidity Developer

## 📜 License
This project is licensed under the **MIT License**.

