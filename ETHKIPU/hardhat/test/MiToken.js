const { expect } = require("chai");

describe("MiToken contract", function () {
  it("Deployment should assign the total supply of tokens to the deployer", async function () {
    const [deployer] = await ethers.getSigners();

    const hardhatToken = await ethers.deployContract("MiToken");

    const deployerBalance = await hardhatToken.balanceOf(deployer.address);
    expect(await hardhatToken.totalSupply()).to.equal(deployerBalance);
  });
  it("Transfer 10 token from deployer to other account", async function () {
    const [deployer, otherAccount] = await ethers.getSigners();
    
    const hardhatToken = await ethers.deployContract("MiToken");

    const amount = 10;

    const deployerInitialBalance = await hardhatToken.balanceOf(deployer.address);
    const otherAccountInitialBalance = await hardhatToken.balanceOf(otherAccount.address);

    await hardhatToken.transfer(otherAccount.address, amount);

    const deployerFinalBalance = await hardhatToken.balanceOf(deployer.address);
    const otherAccountFinalBalance = await hardhatToken.balanceOf(otherAccount.address);

    expect(deployerInitialBalance).to.equal(await hardhatToken.totalSupply());
    expect(otherAccountInitialBalance).to.equal(0);

    expect(deployerFinalBalance).to.equal(await hardhatToken.totalSupply() - BigInt(amount));
    expect(otherAccountFinalBalance).to.equal(amount);
  });

  it("Transfer 10 token from deployer to other account and then the other account returns 5 to the deployer", async function () {
    const [deployer, otherAccount] = await ethers.getSigners();
    
    const hardhatToken = await ethers.deployContract("MiToken");

    const amount = 10;
    const returnamount = 5;

    const deployerInitialBalance = await hardhatToken.balanceOf(deployer.address);
    const otherAccountInitialBalance = await hardhatToken.balanceOf(otherAccount.address);

    await hardhatToken.transfer(otherAccount.address, amount);
    await hardhatToken.connect(otherAccount).transfer(deployer.address, returnamount);

    const deployerFinalBalance = await hardhatToken.balanceOf(deployer.address);
    const otherAccountFinalBalance = await hardhatToken.balanceOf(otherAccount.address);

    expect(deployerInitialBalance).to.equal(await hardhatToken.totalSupply());
    expect(otherAccountInitialBalance).to.equal(0);

    expect(deployerFinalBalance).to.equal(await hardhatToken.totalSupply() - BigInt(returnamount));
    expect(otherAccountFinalBalance).to.equal(returnamount);
  });

  it("Should fail to transfer 10 from other account", async function () {
    const [deployer, otherAccount] = await ethers.getSigners();
    const hardhatToken = await ethers.deployContract("MiToken");

    const amount = 10;
    
    await expect(hardhatToken.connect(otherAccount).transfer(deployer.address, amount)).to.be.reverted;

    });
});