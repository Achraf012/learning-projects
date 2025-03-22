const { expect } = require("chai");
const { ethers } = require("hardhat");
describe("NFT MarketPlace tests", function () {
    let nft, marketplace, owner, user1, user2
    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();
        const MarketPlace = await ethers.getContractFactory("nftMarketPlace");
        // console.log("Deploying Marketplace...");
        marketplace = await MarketPlace.connect(owner).deploy(100);
        // console.log("Marketplace deployed at:", marketplace.target);
        await marketplace.waitForDeployment();


        const NFT = await ethers.getContractFactory("MyNFT");
        nft = await NFT.deploy();
        // console.log("NFT Contract deployed at:", nft.target);

        await nft.waitForDeployment();
    })
    async function listNFT(user, tokenId, price, description = "test nft") {
        await marketplace.connect(user).listItem(nft.target, tokenId, ethers.parseEther(price), description);
    }

    async function mintAndApprove(user, URI = "randomURI", tokenId) {
        await nft.connect(user).mintNFT(URI, { value: ethers.parseEther("0.01") });
        await nft.connect(user).approve(marketplace.target, tokenId);


    }
    describe("Listing NFTs Tests", function () {
        it("Should allow the owner of an NFT to list it", async function () {

            await mintAndApprove(user1, "randomURI", 0);
            await marketplace.connect(user1).listItem(nft.target, 0, ethers.parseEther("1"), " test nft");
            const listing = await marketplace.listings(nft.target, 0);
            expect(listing.owner).to.equal(user1.address);
        })
        it(" Should revert if the caller is not the owner of the NFT", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await expect(marketplace.connect(user2).listItem(nft.target, 0, ethers.parseEther("1"), " test nft")).to.be.revertedWithCustomError(marketplace, "NotTheOwner").withArgs(user1.address, user2.address)

        })
        it("Should revert if the NFT is already listed", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await marketplace.connect(user1).listItem(nft.target, 0, ethers.parseEther("1"), " test nft");
            await expect(marketplace.connect(user1).listItem(nft.target, 0, ethers.parseEther("1"), " test nft")).to.be.revertedWithCustomError(marketplace, "duplicateListing").withArgs(user1.address)

        })
        it("Should emit ItemListed event on successful listing", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "1");
            expect(marketplace.listItem()).to.emit(marketplace, "ItemListed").withArgs(user1.address, nft.target, 0, ethers.parseEther("1"));

        })

    })
    describe("Buying NFTs Tests", function () {
        it("Should allow a user to buy a listed NFT by paying the correct amount", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            const owner = await nft.ownerOf(0);
            const nftowner = await marketplace.getListing(nft.target, 0);
            // console.log("Owner of NFT in marketplace:", nftowner);
            // console.log("Owner of NFT:", owner);

            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("0.1") });
            expect(await nft.ownerOf(0)).to.equal(user2.address);
        })
        it(" Should revert if the buyer sends insufficient funds", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.2");
            await expect(marketplace.connect(user2).buyItem(nft.target, 0, {
                value: ethers.parseEther("0.1")

            })).to.be.revertedWithCustomError(marketplace, "InsufficientFunds").withArgs(ethers.parseEther("0.2"), ethers.parseEther("0.1"));

        })
        it("Should revert if the NFT is not listed", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await expect(marketplace.connect(user2).buyItem(nft.target, 0, {
                value: ethers.parseEther("0.1")

            })).to.be.revertedWithCustomError(marketplace, "NFTNotListed").withArgs(nft.target, 0);
        })
        it("Should pay the seller (minus marketplace fee)", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("0.1") })

            await expect(marketplace.connect(user1).withdrawFunds()).to.changeEtherBalance(user1.address, ethers.parseEther("0.099"))

        })
        it("Should increase owner balance by the fee amount", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("0.1") });
            await expect(marketplace.connect(owner).withdrawFees(ethers.parseEther("0.001"))).to.changeEtherBalance(owner.address, ethers.parseEther("0.001"))

        })
        it(" Should remove the listing after a successful purchase", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("0.1") });
            await expect(marketplace.getListing(nft.target, 0)).to.be.revertedWithCustomError(marketplace, "NFTNotListed").withArgs(nft.target, 0)
        })
    })
    describe("Canceling Listings Tests", function () {
        it("Should allow the NFT owner to cancel their listing", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await marketplace.connect(user1).cancelListing(nft.target, 0);
            const listing = await marketplace.listings(nft.target, 0);
            await expect(listing.owner).to.equal(ZERO_ADDRESS);

        })
        it("Should revert if the NFT is not listed", async function () {
            await expect(marketplace.connect(user1).cancelListing(nft.target, 0)).to.revertedWithCustomError(marketplace, "NFTNotListed").withArgs(nft.target, 0);
        })

        it("Should emit ListingCancelled event", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await expect(marketplace.connect(user1).cancelListing(nft.target, 0)).to.emit(marketplace, "ListingCancelled").withArgs(user1.address, nft.target, 0)

        })
    })
    describe("Updating Price Tests", function () {
        it("Should allow the owner to update the price of a listed NFT", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await marketplace.connect(user1).updatePrice(nft.target, 0, ethers.parseEther("0.2"));
            const listing = await marketplace.listings(nft.target, 0);
            expect(listing.price).to.equal(ethers.parseEther("0.2"));
        })
        it("Should revert if someone other than the owner tries to update the price", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "0.1");
            await expect(marketplace.connect(user2).updatePrice(nft.target, 0, ethers.parseEther("0.2"))).to.be.revertedWithCustomError(marketplace, "NotTheOwner").withArgs(user1.address, user2.address);
        })

    })
    describe(" Withdrawing Fees Tests", function () {
        it(" Should allow  the owner to withdraw fees", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "1");
            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("1") });
            await expect(marketplace.connect(owner).withdrawFees(ethers.parseEther("0.01"))).to.changeEtherBalance(owner.address, ethers.parseEther("0.01"));

        })
        it("Should revert if the requested amount exceeds marketplace balance", async function () {
            await mintAndApprove(user1, "randomURI", 0);
            await listNFT(user1, 0, "1");
            await marketplace.connect(user2).buyItem(nft.target, 0, { value: ethers.parseEther("1") });
            await expect(marketplace.connect(user1).withdrawFees(ethers.parseEther("0.01"))).to.be.revertedWithCustomError(marketplace, "OwnableUnauthorizedAccount").withArgs(user1.address);

        })

    })
})
