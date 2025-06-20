# 🗳️ DAO Project — From Basics to Meta-Voting

This folder contains the full evolution of a DAO smart contract from a basic version to an upgradable one with EIP-712 support.

## 📦 Versions

- **DAO v1** — basic on-chain voting using an ERC20 token for voting power.
- **DAO v2** — adds UUPS upgradability via OpenZeppelin’s `UUPSUpgradeable`.
- **DAO v3** — builds on v2 and adds `voteBySig()` using EIP-712 (gasless voting, off-chain signatures, replay protection).

## 🔐 Features (v3)

- On-chain + off-chain (signature-based) voting
- Nonce & deadline checks for secure EIP-712 flow
- UUPS upgradeable with `_authorizeUpgrade`
- `vote()` and `voteBySig()` both prevent double voting

## 🛠️ Tools

- **Solidity** `^0.8.27`
- **OpenZeppelin Upgradeable Contracts** `v5.3.0`
- **Foundry** for testing and building
- **Slither + Aderyn** for vulnerability scanning

## 🧠 Why This?

Started as a simple DAO, but then I wanted to:

- Learn how upgradability works under the hood
- Add gasless voting using EIP-712
- Think like an attacker (and protect against myself)

## 📌 Next

- Write complete Foundry tests
- Run full audits with Slither/Aderyn
- Try edge-case attack simulations

---

🧪 Built as part of my freelance-ready Solidity journey.  
Follow me on X for updates and experiments 👇
https://x.com/BuildWithAchraf
