
# EscrowProject

## Project Description
The **EscrowProject** implements a decentralized escrow and payment system using Solidity. This system ensures secure, conditional transfers of funds between parties, protecting both the buyer and seller during the transaction process.

## Features
- **Escrow**: Holds funds until both the buyer and seller fulfill their agreement.
- **Payment Release**: Funds are only released when specified conditions are met.
- **Security**: Protection against malicious behaviors, including reentrancy attacks.


## Technology Stack
- **Solidity**: Smart contract development.
- **Foundry**: Used for smart contract testing and local development.
- **Ethereum**: Blockchain network used for contract deployment.

## Contracts
### 1️⃣ **Escrow.sol**
- Manages escrow accounts and ensures funds are only released when conditions are met.
- Implements functionality to deposit, release, or refund funds based on transaction status.

### 2️⃣ **EscrowFactory.sol** 
- Manages the creation of multiple escrow contracts.
- Allows users to create new escrow contracts with different conditions for each transaction.

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Achraf012/learning-projects.git
   cd learning-projects/EscrowProject
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

3. Compile contracts:
   ```bash
   forge build
   ```

4. Run tests using Foundry:
   ```bash
   forge test
   ```

## Usage
1. **Create an Escrow Contract**: 
   - Use the **EscrowFactory** contract to create a new escrow contract.
   - Customize the conditions, such as payment amount, buyer and seller addresses, and escrow release conditions.

2. **Make Payments**: 
   - Both buyer and seller can interact with the **Escrow.sol** contract to deposit funds, track transaction progress, and confirm the fulfillment of conditions.

3. **Funds Release**: 
   - Once both parties fulfill their conditions, funds are released to the seller.
   - If the conditions are not met, funds are refunded to the buyer.

## License
This project is licensed under the **MIT License**.

---

For more information or assistance, feel free to reach out to me on [LinkedIn](https://www.linkedin.com/in/achraf-bradji-476157335/).
