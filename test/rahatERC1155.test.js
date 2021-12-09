const { assembleTargets } = require("solidity-coverage/plugins/resources/plugin.utils");

const RahatERC1155 = artifacts.require("RahatERC1155");

describe("RahatERC1155 contract", function() {
  let accounts;
  let rahatERC1155

  before(async function() {
    [deployer,addr1,addr2] = await web3.eth.getAccounts();
    rahatERC1155 = await RahatERC1155.new(deployer);
  });

  describe("Deployment", function() {
    it("Should deploy the Rahat ERC1155 with given admin and baseURI", async function() {   
      assert.equal(await rahatERC1155.owner(deployer), true);
      assert.equal(await rahatERC1155.getTokenData(1),'https://ipfs.rumsan.com/ipfs/1.json')
    });
  });

  describe("Mint ERC1155 Token", function() {
    it("Should Mint token to given address and increase supply", async function() {
      await rahatERC1155.mintERC1155('Test NFT','TNFT',1000,{from:addr1});
      const totalSupply = await rahatERC1155.totalSupply(1);
      const balanceOf = await rahatERC1155.balanceOf(addr1,1);
      assert.equal(totalSupply.toNumber(),1000);
      assert.equal(balanceOf.toNumber(),1000);
      assert.equal(await rahatERC1155.exists(1),true);
   
    });
    it("Should set base URI through owner only", async function() { 
      await rahatERC1155.setBaseURI('https://rumsanipfs.com/ipfs',{from:deployer});
      assert.equal(await rahatERC1155.getTokenData(1),'https://rumsanipfs.com/ipfs/1.json')

    });

    it("Should mint the ERC1155 tokens of given tokenID", async function() { 
     const initialTotalSupply = await rahatERC1155.totalSupply(1);
     console.log(initialTotalSupply)
      await rahatERC1155.mintExistingERC1155(1,1000,{from:deployer});

      const finalTotalSupply = await rahatERC1155.totalSupply(1);
     console.log({finalTotalSupply})

      assert.equal(finalTotalSupply.toNumber(),initialTotalSupply.toNumber()+1000)


    });
  });
});
