# 🌉 Cross-Chain Bridge Labs

This repository is a step-by-step journey into building a **secure cross-chain bridge** from first principles — starting with raw ECDSA verification and ending with a multi-validator, EIP-712–secured bridge system.

Each lab focuses on one key security or architectural concept used in real-world bridge protocols.

---

## 🧩 Labs Overview

### **Lab 1 – Signature Verifier**

Learned how to verify ECDSA signatures manually using `ecrecover`.

- Built a basic verifier from scratch.
- Understood how `v`, `r`, `s` map to Ethereum signatures.

### **Lab 2 – Bridge Message Verifier**

Introduced structured messages and replay protection.

- Added `user`, `amount`, and `nonce` to the signed message.
- Learned how hashing impacts bridge message uniqueness.

### **Lab 3 – Bridge Core**

Simulated the **source chain** side of a bridge.

- Users deposit funds to be sent cross-chain.
- Emits a message that validators will later sign.

### **Lab 4 – Bridge Target**

Simulated the **destination chain**.

- Verified validator signatures before releasing funds.
- Prevented double-claims using nonces.

### **Lab 5 – Bridge Combine**

Connected everything into one flow.

done in the tests — this lab was mainly for integration visualization.

### **Lab 6 – Bridge Multi-Validator**

Added a **multi-signature validation** layer (threshold model).

- Required M-of-N validators to approve each bridge transfer.
- Simulated real-world bridge validator consensus.

### **Lab 7 – Bridge + EIP-712**

Upgraded the bridge to use **EIP-712 typed data signatures**.

- Ensured clear message structure and replay safety.
- Moved closer to production-grade bridge signing like LayerZero, Axelar, or Wormhole.

---

## 🧠 Key Concepts Covered

✅ ECDSA verification  
✅ Hashing structured data  
✅ Nonce and replay protection  
✅ Cross-chain message flow  
✅ Multi-validator consensus  
✅ EIP-712 typed data signing  
✅ Secure message digesting

---

## 🧪 Testing

All labs are tested using **Foundry**.  
Run all tests with:

```bash
forge test -vvv
```

🧑‍💻 Built by Achraf — a Solidity builder & Web3 security learner focused on understanding systems by rebuilding them from scratch.
