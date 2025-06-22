# 🧠 learning-projects

Welcome to my Solidity learning lab.  
This repo is a structured collection of smart contract projects I’ve built while studying advanced concepts in decentralized development, smart contract security, and gas optimization.

Each folder is a standalone project focused on a specific domain: DEX, DAO, Upgradability, Payments, and more.

## 📁 Projects Overview

| Project                                    | Description                                                                                     |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------- |
| **DAO_Project**                            | A governance system with EIP-712 signatures and upgradable proxies.                             |
| **Decentralized-Payment-Streaming-System** | ETH and ERC20 streaming payments with V2 upgrade                                                |
| **Dex_Project**                            | A Uniswap-style AMM with ETH wrapping support, LP tokens, and a factory/router system.          |
| **EIP712Hasher**                           | Minimal project to isolate and test EIP-712 hashing/signing logic.                              |
| **EscrowProject**                          | A simple escrow system for secure ETH payments, including factory deployment.                   |
| **TokenLaunchpad**                         | Token sale with whit LaunchPadFactory, vesting, and safety checks (Overflow, Reentrancy, etc.). |
| **nft_Project**                            | Basic ERC721 NFT with a marketplace contract.                                                   |
| **proxy-lab**                              | Hands-on upgradability lab: v1 (basic), v2 (UUPS proxy), v3 (UUPS + EIP-712).                   |

## 🛠️ Stack & Tools

- **Language:** Solidity (0.8.x)
- **Framework:** [Foundry](https://book.getfoundry.sh/)
- **Security:** OpenZeppelin libraries, manual audits, unit + invariant testing
- **Design:** EIP-712, Proxy Patterns (UUPS), Factory pattern, Access control

## 🧪 Tests

most projects include tests written in Foundry (Forge).  
To run them:

```bash
forge install
forge test -vvvv
```

🧭 Learning Goals
This repository helps me:

\_Build a strong foundation in smart contract development

\_Practice gas optimization and safe patterns

\_Learn exploit prevention through real-world patterns

\_Prepare for audits, contests (Code4rena, Sherlock), and freelance work

                Feel free to explore any folder, fork the code, or reach out if you're working on something cool. Let's build secure protocols. 🔐
