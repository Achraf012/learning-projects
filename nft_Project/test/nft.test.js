const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("tests for my NFT contract", function () {
    let Contract, contract, user1, user2, user3;
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
    beforeEach(async function () {
        Contract = await ethers.getContractFactory("MyNFT");
        [user1, user2, user3] = await ethers.getSigners();
        contract = await Contract.deploy();
        await contract.waitForDeployment();

    })
    it("Should increase the TokenCounter after minting.", async function () {
        await contract.connect(user1).Mint("URI");
        expect(await contract.TokenCounter()).to.equal(1);


    })
    it("Should assign the correct owner after minting.", async function () {
        await contract.connect(user1).Mint("URI");
        expect(await contract.ownerOf(0)).to.equal(user1.address);
    })
    it("Should store the correct TokenURI for the minted NFT.", async function () {
        await contract.connect(user1).Mint("URI");
        expect(await contract.TokenURI(0)).to.equal("URI");

    })
    it("Should emit a minted event with the correct details.", async function () {
        expect(await contract.connect(user1).Mint("URI")).to.emit(contract, "minted").withArgs("URI", 0)


    })
    it("Should allow the owner to approve another address.", async function () {
        await contract.connect(user1).Mint("URI");
        await contract.connect(user1).approve(user2.address, 0);
        expect(await contract.approvedUsers(0)).to.equal(user2.address);

    })
    it("Should fail if a non-owner tries to approve", async function () {
        await contract.connect(user1).Mint("URI");
        await expect(contract.connect(user2).approve(user3.address, 0)).to.be.revertedWith("Not the owner")

    })
    it("Should fail if approving the zero address (address(0)).", async function () {
        await contract.connect(user1).Mint("URI");
        await expect(contract.connect(user1).approve(ZERO_ADDRESS, 0)).to.be.revertedWith("Invalid address")
    })
    it("Should allow the owner to transfer the NFT.", async function () {
        await contract.connect(user1).Mint("URI");
        await contract.connect(user1).transferNFT(user2.address, 0);
        expect(await contract.ownerOf(0)).to.equal(user2.address);

    })
    it("Should fail if a non-owner or non-approved address tries to transfer.", async function () {
        await contract.connect(user1).Mint("URI");
        await expect(contract.connect(user2).transferNFT(user3.address, 0)).to.be.revertedWith("Not owner or approved")
    })
    it("Should reset the approved address after a transfer.", async function () {
        await contract.connect(user1).Mint("URI");
        await contract.connect(user1).approve(user2.address, 0);
        await contract.connect(user2).transferNFT(user3.address, 0);
        expect(await contract.approved(0)).to.equal(ZERO_ADDRESS);
    })



})