# 🧪 Foundry Signature Testing Project

This is a simple Foundry-based test project demonstrating how to simulate ECDSA signatures using `vm.addr` and `vm.sign`. It shows how to generate an Ethereum address from a private key and sign a digest for testing signature-based logic.

## 🔍 Features

- Simulate EOA addresses with `vm.addr`
- Sign arbitrary messages or EIP-712 digests with `vm.sign`
- Use signatures (v, r, s) to call smart contract functions
- Test ECDSA-based authorization logic

## 🛠 Tech Stack

- Foundry
- Solidity
- Cheatcodes (`vm.addr`, `vm.sign`, `vm.prank`, etc.)

## 🚀 Getting Started

1. **Install Foundry**

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Install dependencies & test**

```bash
forge install
forge build
forge test
```

## 📄 License

MIT
