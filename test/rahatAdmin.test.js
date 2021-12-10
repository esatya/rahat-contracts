const RahatAdmin = artifacts.require("RahatAdmin");
const Rahat = artifacts.require("Rahat");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatERC1155 = artifacts.require("RahatERC1155");

describe("Rahat contract", function() {
  let rahatERC20;
  let rahatERC1155;
  let rahat;
  let rahatAdmin;
  let serverRole;
  let adminRole;
  let vendorRole;
  let mobilizerRole;
  let managerRole;

  before(async function() {
    [deployer,admin,server,vendor,manager,mobilizer,addr1,addr2] = await web3.eth.getAccounts();
    rahatERC20 = await RahatERC20.new("Rahat","RHT",deployer);
    rahatERC1155 = await RahatERC1155.new(deployer);
    rahat = await Rahat.new(rahatERC20.address,rahatERC1155.address,deployer)
    rahatAdmin = await RahatAdmin.new(rahatERC20.address,rahatERC1155.address,rahat.address,10000000,deployer)
    serverRole = await rahat.SERVER_ROLE();
    adminRole = await rahat.DEFAULT_ADMIN_ROLE();
    serverRole = await rahat.SERVER_ROLE();
    managerRole = await rahat.MANAGER_ROLE();
    mobilizerRole = await rahat.MOBILIZER_ROLE();
    vendorRole = await rahat.VENDOR_ROLE();

  });




  describe("Deployment", function() {
    it("Should deploy the RahatAdmin with rahatERC20, rahatERC1155 and rahat contract", async function() {   
      assert.equal(await rahatAdmin.erc20(), rahatERC20.address);
      assert.equal(await rahatAdmin.erc1155(), rahatERC1155.address);
      assert.equal(await rahatAdmin.rahatContract(), rahat.address);
      assert.equal(await rahatAdmin.owner(deployer), true);
    });
  });

  describe("Sets the Project Budget", function() {
    it("Should set the project ERC20 budget", async function() {   
        await rahatAdmin.setProjectBudget_ERC20('project1',10000);
        let projec1_erc20Balance = await rahatAdmin.getProjecERC20Balance('project1');
        assert.equal(projec1_erc20Balance.toNumber(),10000)
    });


    it("Should set the project budget with new ERC1155 token", async function() {   
        await rahatAdmin.createAndsetProjectBudget_ERC1155('Project1Token','P1T','project1',10000);
        let projec1_erc1155Balance = await rahatAdmin.getProjectERC1155Balance('project1',1);
        assert.equal(projec1_erc1155Balance.toNumber(),10000)
        let projec1_erc1155Balances = await rahatAdmin.getProjectERC1155Balances('project1');
        assert.equal(projec1_erc1155Balances.tokenIds[0].toNumber(),1)
        assert.equal(projec1_erc1155Balances.balances[0].toNumber(),10000)
     });

     

     it("Should set the project ERC1155 budget with existing ERC1155 token", async function() {   
         const tokenids = await rahatAdmin.getAllTokenIdsOfProject('project1');
         assert.equal(tokenids[0].toNumber(),1);
         let initialProjec1_erc1155Balance = await rahatAdmin.getProjectERC1155Balance('project1',1);
         await rahatAdmin.setProjectBudget_ERC1155('project1',10000,1);
         let finalProjec1_erc1155Balance = await rahatAdmin.getProjectERC1155Balance('project1',1);
        assert.equal(finalProjec1_erc1155Balance.toNumber() ,initialProjec1_erc1155Balance.toNumber()+10000)

     });


  });


  describe("Mint Tokens",function() {
      it('should mint erc20 tokens',async function(){
        await rahatAdmin.mintERC20(addr2,1000);
        const addr1Balance = await rahatERC20.balanceOf(addr2);
        assert.equal(addr1Balance.toNumber(), 1000);
      })

      it('should mint erc1155 tokens',async function(){
        await rahatAdmin.mintERC1155('Test NFT','TNFT',1000,{from:deployer});
        const totalSupply = await rahatERC1155.totalSupply(2);
        const balanceOf = await rahatERC1155.balanceOf(rahatAdmin.address,2);
        assert.equal(totalSupply.toNumber(),1000);
        assert.equal(balanceOf.toNumber(),1000);
        assert.equal(await rahatERC1155.exists(2),true);
    })
  })



});