const Rahat = artifacts.require("Rahat");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatERC1155 = artifacts.require("RahatERC1155");
const RahatAdmin = artifacts.require("RahatAdmin");


describe("Rahat contract", function() {
  let rahatERC20;
  let rahatERC1155;
  let rahat;
  let serverRole;
  let adminRole;
  let vendorRole;
  let mobilizerRole;
  let managerRole;
  let rahatAdmin;
  const phone1 = 1111111111;
  const phone2 = 2222222222;
  const phone3 = 3333333333;
  const otp = '9670'
  const otpHash = web3.utils.soliditySha3({type: 'string', value: otp});


  before(async function() {
    [deployer,admin,server,vendor,manager,mobilizer] = await web3.eth.getAccounts();
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
        await rahat.addMobilizer(mobilizer,'project1',{from:deployer});
        assert.equal(await rahat.hasRole(mobilizerRole,mobilizer),true);
     //   const mobilizer = projectMobilizers
    })

  })

  describe("heplers test", function(){
    it("should return the sum of array", async function(){
        const sum = await rahat.getArraySum([10,20,30]);
        assert.equal(60,sum);
    })

     it("should hash of given string", async function(){
        const hash = await rahat.findHash(phone1.toString());
        const expectedhash = web3.utils.soliditySha3({type: 'string', value:phone1.toString() });
        assert.equal(hash,expectedhash);
    })

  })

  describe("checks balances of beneficiary", function(){
    it("should return the ERC20 balance of beneficiary", async function(){
        const balance = await rahat.erc20Balance(9670);
        assert.equal(balance,0);
    })

    it("should return the ERC1155 balance of beneficiary", async function(){
        const balance = await rahat.erc1155Balance(9670,1);
        assert.equal(balance,0);
    })

  })

  describe("add project with budget" , function() {
    it("should add project with given project ID",async function() {
      const projectId_1 = web3.utils.soliditySha3({type: 'string', value: 'rahatProject_1'});
      await rahat.addProject(projectId_1,10000);
      const projectBalance_token = await rahat.getProjectBalance(projectId_1);
      const projectBalance_nft = await rahat.getProjectBalance(projectId_1,1);

      assert.equal(projectBalance_token,10000);
      assert.equal(projectBalance_nft,0);

    })
  })

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



});
