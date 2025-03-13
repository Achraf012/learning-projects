require("@nomicfoundation/hardhat-toolbox");
require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-chai-matchers"); // ✅ Add this line

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,  // ✅ Turns on optimizer (reduces gas)
        runs: 200       // ✅ Adjust for better efficiency
      }
    }
  },
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 30,
    outputFile: "gas-report.txt",
    noColors: true
  }
};
