# 🔁 Proxy Lab

This repo is a hands-on lab to practice writing and upgrading smart contracts using the **UUPS (Universal Upgradeable Proxy Standard)** pattern with **OpenZeppelin**.

## 🧪 What’s Inside

- `BoxUUPS.sol`: A basic upgradeable storage contract (V1)
- `BoxV2.sol`: Adds a new `add()` function
- `ProxyTest.t.sol`: Full Foundry test to deploy, interact, and upgrade the Box

- `logic1.sol`: ETH Payment Splitter — splits ETH between `owner` and a `partner` (V1)
- `logic2.sol`: Adds ERC20 token support for splitting tokens (V2)

## 🛠️ Tech Stack

- [Solidity 0.8.27](https://docs.soliditylang.org/)
- [OpenZeppelin Upgradeable Contracts](https://docs.openzeppelin.com/contracts-upgradeable)
- [Foundry](https://book.getfoundry.sh/) for testing

## 💡 Learnings

- How `ERC1967Proxy` + UUPS pattern work
- How to initialize upgradeable contracts safely
- How to keep storage layout compatible across upgrades
- How to test upgrades in Foundry

## 🚀 To Try It Yourself
