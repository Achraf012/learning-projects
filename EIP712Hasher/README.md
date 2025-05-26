# 🧾 EIP-712 Message Hashing & Signature Testing (Foundry)

This is a simple Foundry project that walks through the core steps of EIP-712 structured data hashing and simulates signing and verification using cheatcodes like `vm.sign` and `vm.addr`.

Perfect for learning how off-chain signatures (like voteBySig) are built and verified on-chain.

---

## 🔍 Features

- Create and hash typed structs (EIP-712 style)
- Build a domain separator manually
- Generate the final digest with `getMessageHash`
- Simulate off-chain signatures with `vm.sign`
- Prepare for on-chain recovery with `ECDSA.recover`

---

## 🛠 Tech Stack

- **Solidity**
- **Foundry**
- Cheatcodes: `vm.sign`, `vm.addr`, `console.log`, etc.

---

## 🚀 Getting Started

1. **Install Foundry**

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. **Run Tests**

```bash
forge test -vvvv
```

Use `console.log` outputs to inspect the struct hash, domain separator, and message hash.

---

## 🧠 Why This Matters

EIP-712 is the foundation for off-chain voting, gasless approvals, meta-transactions, and more. This project helps you understand it by building the logic manually, step by step.

---

## 📄 License

MIT
