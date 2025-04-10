# Token Launchpad (Solidity Project)

A portfolio project that showcases a complete Token Sale and Vesting system built with Solidity. It allows token creators to launch sales for their ERC20 tokens and investors to participate with transparent rules. Vesting logic is used only for sale types that require it, such as presales.

## 🛠️ Contracts

### 1. TokenSale.sol

- Allows a token owner to launch a sale with soft cap, hard cap, start/end times, and token price.
- Investors can contribute ETH and receive tokens in return.
- Supports investor refunds if the soft cap is not reached.
- Can optionally use a Vesting contract to lock tokens for each investor (depending on the sale type).

### 2. Vesting.sol

- Locks tokens for a specific investor until a set release time.
- After the release time, investors can claim **all their tokens at once**.
- Simple one-time vesting logic, used only in sale types like Presale.

### 3. LaunchpadFactory.sol

- Deploys new TokenSale contracts on demand.
- Allows token owners to easily launch a new token sale without writing Solidity code.

## 🚀 Features

- Supports three sale types: **Presale**, **Fair Launch**, and **IDO**.
  - **Presale**: Investors get tokens with a delay (vesting applies).
  - **Fair Launch**: Investors get tokens immediately after the sale ends.
  - **IDO**: follow delayed token delivery settings.
- Soft cap and hard cap logic.
- Refunds if soft cap isn't reached.
- Optional vesting depending on the sale type.
- Factory contract allows creating multiple independent token sales.

## 🧪 Testing

Tests are written using Hardhat and Chai, covering:

- Token purchase flows
- Cap logic
- Refunds
- Vesting behavior

## 🧰 Tech Stack

- Solidity
- Hardhat
- Chai / Mocha
- VS Code

## 📂 Structure

```
contracts/
  ├─ TokenSale.sol
  ├─ Vesting.sol
  └─ LaunchpadFactory.sol
```

## 🧠 Author

Achraf — Solidity Developer focused on security, gas optimization, and clean architecture.

## 📜 License

MIT

