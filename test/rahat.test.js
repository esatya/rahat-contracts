const Rahat = artifacts.require("Rahat");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatERC1155 = artifacts.require("RahatERC1155");

describe("Rahat contract", function() {
  let rahatERC20;
  let rahatERC1155;
  let rahat;
  let serverRole;
  let adminRole;
  let vendorRole;
  let mobilizerRole;
  let managerRole;

  before(async function() {
    [deployer,admin,server,vendor,manager,mobilizer] = await web3.eth.getAccounts();
    rahatERC20 = await RahatERC20.new("Rahat","RHT",deployer);
    rahatERC1155 = await RahatERC1155.new(deployer);
    rahat = await Rahat.new(rahatERC20.address,rahatERC1155.address,deployer)
    serverRole = await rahat.SERVER_ROLE();
    adminRole = await rahat.DEFAULT_ADMIN_ROLE();
    serverRole = await rahat.SERVER_ROLE();
    managerRole = await rahat.MANAGER_ROLE();
    mobilizerRole = await rahat.MOBILIZER_ROLE();
    vendorRole = await rahat.VENDOR_ROLE();
  });

  describe("Deployment", function() {
    it("Should deploy the Rahat contract with rahatERC20 and RahatERC1155 contract", async function() {   
      assert.equal(await rahat.erc20(), rahatERC20.address);
      assert.equal(await rahat.erc1155(), rahatERC1155.address);
    });
  });

  describe("Roles management ", function(){
    it("should add admin role to new account via admin account", async function(){
        await rahat.addAdmin(admin,{from:deployer});
        assert.equal(await rahat.hasRole(adminRole,admin),true);
    })
    it("should add server role to new account via admin account", async function(){
        await rahat.addServer(server,{from:deployer});
        assert.equal(await rahat.hasRole(serverRole,server),true);
    })
    it("should add vendor role to new account via admin account", async function(){
        await rahat.addVendor(vendor,{from:deployer});
        assert.equal(await rahat.hasRole(vendorRole,vendor),true);
    })
    it("should add mobilizer role to new account via admin account", async function(){
        await rahat.addMobilizer(mobilizer,{from:deployer});
        assert.equal(await rahat.hasRole(mobilizerRole,mobilizer),true);
    })

  })

  describe("heplers test", function(){
    it("should return the sum of array", async function(){
        const sum = await rahat.getArraySum([10,20,30]);
        assert.equal(60,sum);
    })
   

  })

//   describe("Mint Token", function() {
//     it("Should Mint token to given address", async function() {
//       await rahatERC20.mintERC20(addr1,1000);
//       const addr1Balance = await rahatERC20.balanceOf(addr1);
//       assert.equal(addr1Balance.toNumber(), 1000);
//     });
//     it("Should increase the supply of token", async function() { 
//       const initialSupply = await rahatERC20.totalSupply();
//       await rahatERC20.mintERC20(addr1,1000);
//       const finalSupply = await rahatERC20.totalSupply();
//       assert.equal(finalSupply.toNumber(), initialSupply.toNumber() + 1000);
//     });
//   });
});
