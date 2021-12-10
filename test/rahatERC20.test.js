const RahatERC20 = artifacts.require("RahatERC20");

describe("RahatERC20 contract", function() {
  let accounts;
  let rahatERC20

  before(async function() {
    [deployer,addr1,addr2] = await web3.eth.getAccounts();
    rahatERC20 = await RahatERC20.new("Rahat","RHT",deployer);
  });

  describe("Deployment", function() {
    it("Should deploy the Rahat ERC20 with given name, symbol and admin", async function() {   
      assert.equal(await rahatERC20.name(), "Rahat");
      assert.equal(await rahatERC20.symbol(), "RHT");
      assert.equal(await rahatERC20.owner(deployer), true);
    });
  });

  describe("ownership management",function() {

    it('should add owner to the rahatERC20 contract',async function(){
      await rahatERC20.addOwner(addr1,{from:deployer});

      assert.equal(await rahatERC20.owner(addr1),true);
    })
  })

  describe("Mint Token", function() {
    it("Should Mint token to given address", async function() {
      await rahatERC20.mintERC20(addr1,1000);
      const addr1Balance = await rahatERC20.balanceOf(addr1);
      assert.equal(addr1Balance.toNumber(), 1000);
    });
    it("Should increase the supply of token", async function() { 
      const initialSupply = await rahatERC20.totalSupply();
      await rahatERC20.mintERC20(addr1,1000);
      const finalSupply = await rahatERC20.totalSupply();
      assert.equal(finalSupply.toNumber(), initialSupply.toNumber() + 1000);
    });

    it("Only owner can mint the token", async function() { 
      const initialSupply = await rahatERC20.totalSupply();
      await rahatERC20.mintERC20(addr1,1000);
      const finalSupply = await rahatERC20.totalSupply();
      assert.equal(finalSupply.toNumber(), initialSupply.toNumber() + 1000);
    });
  });
});
