const hre = require("hardhat");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CleanToken", function () {
  let owner;
  let Token;
  let token;
  let addresses;

  beforeEach(async () => {
    addresses = await hre.ethers.getSigners();
    owner = addresses[0];
    Token = await ethers.getContractFactory("CleanToken");
    token = await Token.deploy();
    await token.deployed();
  });

  it("Should set the right owner", async function () {
    // This test expects the owner variable stored in the contract to be equal
    // to our Signer's owner.
    expect(await token.owner()).to.equal(owner.address);
  });

  it("Should mint 100000000000 tokens to contract deployer upon creation", async function () {
    const ownerBalance = await token.balanceOf(owner.address);

    expect(ownerBalance).to.equal(ethers.utils.parseUnits("100000000000", 18));

    expect(await token.totalSupply()).to.equal(ownerBalance);
  });

  it("Should not mint to other non-owner addresses upon contract creation", async function () {
    expect(await token.balanceOf(addresses[1].address)).to.equal("0");
  });

  it("Should allow owner to call addMinter", async function () {
    await token.addMinter(addresses[1].address, true);
    expect(await token.isValidMinter(addresses[1].address)).to.equal(true);
  });

  it("Should allow holder to burn tokens", async function () {
    await token.burn(ethers.utils.parseUnits("50", 18));
    expect(await token.balanceOf(owner.address)).to.equal(
      ethers.utils.parseUnits((100000000000 - 50).toString(), 18)
    );
  });

  it("Should not allow non-owner to call addMinter", async function () {
    await expect(
      token.connect(addresses[1]).addMinter(addresses[2].address, true)
    ).to.be.revertedWith("Ownable: caller is not the owner");
  });

  it("Should transfer tokens between accounts", async function () {
    // Transfer 50 tokens from owner to addr1
    await token.transfer(addresses[1].address, 50);
    const addr1Balance = await token.balanceOf(addresses[1].address);
    expect(addr1Balance).to.equal(50);

    // Transfer 50 tokens from addr1 to addr2
    // We use .connect(signer) to send a transaction from another account
    await token.connect(addresses[1]).transfer(addresses[2].address, 50);
    const addr2Balance = await token.balanceOf(addresses[2].address);
    expect(addr2Balance).to.equal(50);
  });
});
