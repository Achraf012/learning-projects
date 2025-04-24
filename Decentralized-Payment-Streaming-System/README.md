# 💸 Decentralized Payment Streaming System

A modular and gas-optimized smart contract system for streaming payments. This project allows senders to stream tokens to recipients over time, enabling use cases like salaries, subscriptions, and more — fully decentralized.

## 🔍 Features

### ✅ v1 - Minimal Streaming Contract

- One-to-one payment stream
- Funds unlock over time (block-based)
- Withdraw anytime based on elapsed time
- Simple cancelation logic
- Reentrancy protected
- Fully tested with Foundry

### 🔄 Upcoming: v2 - Enhanced Version (WIP)

- Batch streams & multi-recipient support
- Stream pausing & resuming
- ERC20 flexibility (custom token support)
- Better gas optimization and code modularity

## 📁 Folder Structure

```
contracts/
  ├── v1.sol         # First version of the streaming contract
  └── v2.sol         # Coming soon...

test/
  ├── v1.t.sol       # Full test suite for v1
  └── reentrancyAttack.sol
```

## 🧪 Test Coverage (v1)

- Stream creation & validation
- Time-based balance logic
- Withdraw behavior over time
- Cancel stream functionality
- Reentrancy test

## ⚙️ Tech Stack

- Solidity
- Foundry (Forge)
- Hardhat-compatible structure

## 📜 License

MIT
