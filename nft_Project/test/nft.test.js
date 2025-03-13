const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("tests for my NFT contract", function () {
    let Contract, contract, owner, user1, user2;
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
    beforeEach(async function () {
        Contract = await ethers.getContractFactory("MyNFT");
        [owner, user1, user2] = await ethers.getSigners();
        contract = await Contract.connect(owner).deploy();
        await contract.waitForDeployment();

    })
    it("Check ownerOf(tokenId) return the correct owner", async function () {
        const mintingfee = ethers.parseEther("0.01")
        await contract.connect(user1).mintNFT("randomURI", { value: mintingfee });
        expect(await contract.ownerOf(0)).to.equal(user1.address);
        const owner = await contract.ownerOf(0);
        console.log("the owner address is:", owner);

    })
    it("Check  transfering NFT by the owner", async function () {
        const mintingfee = ethers.parseEther("0.01")
        await contract.connect(user1).mintNFT("randomURI", { value: mintingfee });
        await contract.connect(user1).safeTransferFrom(user1.address, user2.address, 0);
        expect(await contract.ownerOf(0)).to.equal(user2.address);

    })
    it("Should fail to mint if the user sends less ETH than the required minting fee.", async function () {
        await expect(contract.connect(user1).mintNFT("randomURI")).to.be.revertedWith("Not enough ETH to mint")

    })
    it("Should store the correct token URI after minting.", async function () {
        const mintingfee = ethers.parseEther("0.01")
        await contract.connect(user1).mintNFT("randomURI", { value: mintingfee });
        expect(await contract.tokenURI(0)).to.equal("randomURI");

    })
    it("Should allow only the owner to withdraw funds.", async function () {
        const mintingfee = ethers.parseEther("0.01")
        await contract.connect(user1).mintNFT("randomURI", { value: mintingfee });

        await expect(contract.connect(owner).withdraw()).to.changeEtherBalances(
            [contract, owner], [-mintingfee, mintingfee])
        await expect(contract.connect(user2).withdraw()).to.be.revertedWithCustomError(contract, "OwnableUnauthorizedAccount").withArgs(user2.address);
    })
    it.only("Should emit the Minted event with the correct parameters when an NFT is minted.", async function () {
        const mintingfee = ethers.parseEther("0.01")
        await expect(contract.connect(user1).mintNFT("randomURI", { value: mintingfee })).to.emit(contract, "Minted").withArgs("randomURI", 0)
    })



})