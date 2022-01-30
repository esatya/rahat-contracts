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

  describe('Issue Tokens',function() {

    it("should issue ERC20 token to beneficiary", async function() {
      await rahat.issueERC20ToBeneficiary('project1',phone1,1000,{from:mobilizer});
      const erc20BalanceOfPhone1 = await rahat.erc20Balance(phone1);
      assert.equal(erc20BalanceOfPhone1,1000);
    })

    it("should issue ERC1155 token to beneficiary", async function() {
      const project1TokenId = 1
      await rahat.issueERC1155ToBeneficiary('project1',phone1,[1],[project1TokenId],{from:mobilizer});
      const erc1155BalanceOfPhone1 = await rahat.erc1155Balance(phone1,project1TokenId);
      assert.equal(erc1155BalanceOfPhone1,1);
    })

    it("should issue ERC20 token to beneficiary in bulk", async function(){

      await rahat.issueBulkERC20('project1',[phone2,phone3],[1000,1000]);
      const erc20BalanceOfPhone2 = await rahat.erc20Balance(phone2);
      const erc20BalanceOfPhone3 = await rahat.erc20Balance(phone3);
      const erc20IssuedToPhone2 = await rahat.erc20Issued(phone2);
      const erc20IssuedToPhone3 = await rahat.erc20Issued(phone3);
      assert.equal(erc20BalanceOfPhone2,1000); 
      assert.equal(erc20BalanceOfPhone3,1000);
      assert.equal(erc20IssuedToPhone2,1000); 
      assert.equal(erc20IssuedToPhone3,1000); 
 
    })

    it("should issue ERC1155 token to beneficiary in bulk", async function(){

      const project1TokenId = 1
      await rahat.issueBulkERC1155('project1',[phone2,phone3],[1,1],project1TokenId);
      const erc1155BalanceOfPhone2 = await rahat.erc1155Balance(phone2,project1TokenId);
      const erc1155BalanceOfPhone3 = await rahat.erc1155Balance(phone3,project1TokenId);
      const totalERC1155Issued = await rahat.getTotalERC1155Issued(phone2)
      assert.equal(erc1155BalanceOfPhone2,1);
      assert.equal(erc1155BalanceOfPhone3,1);
      assert.equal(totalERC1155Issued.tokenIds[0],1)
      assert.equal(totalERC1155Issued.balances[0],1)

    })

    it("should check all issued ERC1155 balances", async function(){
      const erc1155BalanceOfPhone2 = await rahat.getTotalERC1155Balance(phone2);
      const tokenIdsOfBeneficiary = await rahat.getTokenIdsOfBeneficiary(phone2)
      console.log({tokenIdsOfBeneficiary})
      assert.equal(erc1155BalanceOfPhone2.tokenIds[0],1)
      assert.equal(erc1155BalanceOfPhone2.balances[0],1)
      assert.equal(tokenIdsOfBeneficiary[0],1)

    })

  });


  describe('check the tokens issued by mobilizer', function() {

    it('should get total erc1155 issued by given address', async function() {
      const erc1155Issued = await rahat.getTotalERC1155IssuedBy(mobilizer);
      const tokenIdsIssuedByMobilizer = await rahat.getTokenIdsIssuedBy(mobilizer);
      console.log({tokenIdsIssuedByMobilizer});
      assert.equal(erc1155Issued.tokenIds[0],1)
      assert.equal(erc1155Issued.balances[0],1)
      assert.equal(tokenIdsIssuedByMobilizer[0],1)

    })
  })


  describe('request tokens from vendor to beneficiary', function() {

    it('should create erc20 token claim from vendor to beneficiary',async function() {
      await rahat.createERC20Claim(phone1,1000,{from:vendor});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC20Claims(vendor,phone1Hash);
      assert.equal(claim.amount,1000);
      assert.equal(claim.isReleased,false);
    })

    it('should create erc1155 token claim from vendor to beneficiary',async function() {
      await rahat.createERC1155Claim(phone1,1,1,{from:vendor});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC1155Claims(vendor,phone1Hash,1);
      assert.equal(claim.amount,1);
      assert.equal(claim.isReleased,false);
    })
  })

  describe('Approve requested claims by setting OTP from server account', function() {

    it('should approve erc20 token claim from server account',async function() {
      await rahat.approveERC20Claim(vendor,phone1,otpHash,2000,{from:server});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC20Claims(vendor,phone1Hash);
      assert.equal(claim.amount,1000);
      assert.equal(claim.isReleased,true);
      
    })

    it('should create erc1155 token claim from vendor to beneficiary',async function() {
      await rahat.approveERC1155Claim(vendor,phone1,otpHash,2000,1,{from:server});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC1155Claims(vendor,phone1Hash,1);
      assert.equal(claim.amount,1);
      assert.equal(claim.isReleased,true);
    })
  })

  describe('Should get tokens after entering correct OTP', function() {

    it('should get erc20 tokens from claim made after entering otp set by server',async function() {

      await rahat.getERC20FromClaim(phone1,otp,{from:vendor});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC20Claims(vendor,phone1Hash);
      assert.equal(claim.amount,0);
      assert.equal(claim.isReleased,false);

    })


    it('should get erc1155 tokens from claim made after entering otp set by server',async function() {

      await rahat.getERC1155FromClaim(phone1,otp,1,{from:vendor});
      const phone1Hash = web3.utils.soliditySha3({type: 'string', value: phone1.toString()});
      console.log(phone1Hash)
      const claim = await rahat.recentERC1155Claims(vendor,phone1Hash,1);
      assert.equal(claim.amount,0);
      assert.equal(claim.isReleased,false);

    })

  })


});
