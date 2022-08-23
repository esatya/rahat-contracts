const AgencyToken = artifacts.require("RahatAgencyToken");

const tryCatch = require("./exceptions.js").tryCatch;
const errTypes = require("./exceptions.js").errTypes;

describe("RahatERC20 contract", function () {
  let accounts;
  let rahatERC20;

  before(async function () {
    [deployer, addr1, addr2] = await web3.eth.getAccounts();
    rahatERC20 = await AgencyToken.new("Rahat", "RHT", { from: deployer });
    console.log(rahatERC20.address);
  });

  describe("Deployment", function () {
    it("Should deploy the Rahat ERC20 with given name, symbol and owner", async function () {
      assert.equal(await rahatERC20.name(), "Rahat");
      assert.equal(await rahatERC20.symbol(), "RHT");
      assert.equal(await rahatERC20.owner(), deployer);
    });
  });

  describe("ownership management", function () {
    it("should not be able to transfer ownership by non-owner account", async function () {
      await tryCatch(
        rahatERC20.transferOwnership(addr1, { from: addr2 }),
        errTypes.revert
      );
      //await expect(rahatERC20.transferOwnership(addr1, { from: addr2 })).to.be.reverted;
    });

    it("should transfer ownership to given address", async function () {
      await rahatERC20.transferOwnership(addr1, { from: deployer });
      assert.equal(await rahatERC20.owner(), addr1);
    });
  });

  describe("Mint Token", function () {
    it("Should Mint token to given address", async function () {
      await rahatERC20.mintToken(addr1, 1000, { from: addr1 });
      const addr1Balance = await rahatERC20.balanceOf(addr1);
      assert.equal(addr1Balance.toNumber(), 1000);
    });
    it("Only owner can mint the token", async function () {
      await tryCatch(
        rahatERC20.mintToken(addr1, 1000, { from: addr2 }),
        errTypes.revert
      );
    });
    it("Should increase the supply of token", async function () {
      const initialSupply = await rahatERC20.totalSupply();
      await rahatERC20.mintToken(addr1, 1000, { from: addr1 });
      const finalSupply = await rahatERC20.totalSupply();
      assert.equal(finalSupply.toNumber(), initialSupply.toNumber() + 1000);
    });
  });

  describe("burn Token", function () {
    it("Should burn token from callers address and reduce the supply", async function () {
      const prevAddr1Balance = await rahatERC20.balanceOf(addr1);
      const initialSupply = await rahatERC20.totalSupply();
      await rahatERC20.burn(1000, { from: addr1 });
      const finaladdr1Balance = await rahatERC20.balanceOf(addr1);
      const finalSupply = await rahatERC20.totalSupply();
      assert.equal(
        finaladdr1Balance.toNumber(),
        prevAddr1Balance.toNumber() - 1000
      );
      assert.equal(finalSupply.toNumber(), initialSupply.toNumber() - 1000);
    });
  });
});
