const hre = require("hardhat");

async function main() {
    console.log("Deploying MyNFT contract...");

    // ✅ Get the contract factory
    const NFTContract = await hre.ethers.getContractFactory("MyNFT");

    // ✅ Deploy the contract
    const nft = await NFTContract.deploy();

    // ✅ Wait for deployment
    await nft.waitForDeployment();

    console.log(`✅ MyNFT Contract deployed to: ${nft.address}`);
}

// ✅ Execute the deployment script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
