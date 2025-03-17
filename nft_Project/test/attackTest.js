const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy Attack Test", function () {
    let nftContract, attackerContract, owner, user, attacker;

    beforeEach(async function () {
        const NFT = await ethers.getContractFactory("MyNFT");
        const Attacker = await ethers.getContractFactory("AttackNFT");

        [owner, user, attacker] = await ethers.getSigners();

        nftContract = await NFT.deploy();
        await nftContract.waitForDeployment();

        attackerContract = await Attacker.deploy(nftContract.target);
        await attackerContract.waitForDeployment();
    });

    it.only("Should block the reentrancy attack", async function () {
        await expect(
            attackerContract.connect(attacker).Attack({ value: ethers.parseEther("0.02") })
        ).to.be.revertedWith("Refund failed")
    });
});
