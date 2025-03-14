require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-chai-matchers");
require("dotenv").config(); // ✅ Import dotenv

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    celo_alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [process.env.PRIVATE_KEY], // ✅ Securely loads the private 
      timeout: 200000,
    },
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 30,
    outputFile: "gas-report.txt",
    noColors: true
  }
};
