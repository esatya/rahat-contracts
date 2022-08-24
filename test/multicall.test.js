const Rahat = artifacts.require("Rahat");
const RahatTriggerResponse = artifacts.require("RahatTriggerResponse");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatAdmin = artifacts.require("RahatAdmin");

const getInterface = (contractName, functionName) => {
  const {
    abi,
  } = require(`../artifacts/src/contracts/${contractName}.sol/${contractName}`);
  if (!abi) throw Error("Contract Not Found");
  const interface = abi.find((el) => el.name === functionName);
  return interface;
};

describe("------ Multicall Tests ------", function () {
  let rahatERC20;
  let rahat;
  let rahatTrigger;
  let serverRole;
  let adminRole;
  let vendorRole;
  let mobilizerRole;
  let managerRole;
  let rahatAdmin;
  const phone1 = 1111111111;
  const phone2 = 2222222222;
  const phone3 = 3333333333;
  const otp = "9670";
  const otpHash = web3.utils.soliditySha3({ type: "string", value: otp });

  before(async function () {
    [deployer, admin, server, vendor, manager, mobilizer, addr1] =
      await web3.eth.getAccounts();
    rahatERC20 = await RahatERC20.new("Rahat", "RHT", deployer);
    rahatTrigger = await RahatTriggerResponse.new(deployer, 2);
    rahat = await Rahat.new(rahatERC20.address, rahatTrigger.address, deployer);
    rahatAdmin = await RahatAdmin.new(
      rahatERC20.address,
      rahat.address,
      10000000,
      deployer
    );
    serverRole = await rahat.SERVER_ROLE();
    adminRole = await rahat.DEFAULT_ADMIN_ROLE();
    serverRole = await rahat.SERVER_ROLE();
    managerRole = await rahat.MANAGER_ROLE();
    mobilizerRole = await rahat.MOBILIZER_ROLE();
    vendorRole = await rahat.VENDOR_ROLE();
  });

  describe("Deployment", function () {
    it("Should deploy the Rahat contract with rahatERC20 contract", async function () {
      assert.equal(await rahat.triggerResponse(), rahatTrigger.address);
      assert.equal(await rahat.erc20(), rahatERC20.address);
      console.log("rahatERC20:", rahatERC20.address);
      console.log("rahatTrigger:", rahatTrigger.address);
    });
  });

  describe("Roles management ", function () {
    it("should add admin role to new account via admin account", async function () {
      await rahat.addAdmin(admin, { from: deployer });
      assert.equal(await rahat.hasRole(adminRole, admin), true);
    });
    it("should add server role to new account via admin account", async function () {
      await rahat.addServer(server, { from: deployer });
      assert.equal(await rahat.hasRole(serverRole, server), true);
    });
    it("should add vendor role to new account via admin account", async function () {
      await rahat.addVendor(vendor, { from: deployer });
      assert.equal(await rahat.hasRole(vendorRole, vendor), true);
    });
    it("should add mobilizer role to new account via admin account", async function () {
      await rahat.addMobilizer(mobilizer, "project1", { from: deployer });
      assert.equal(await rahat.hasRole(mobilizerRole, mobilizer), true);
    });
  });

  describe("Activate Response", function () {
    it("should add admin confirmations and activate response", async function () {
      await rahatTrigger.addAdmin(admin, { from: deployer });
      assert.equal(await rahatTrigger.isLive(), false);
      await rahatTrigger.activateResponse("project1", { from: deployer });
      await rahatTrigger.activateResponse("project1", { from: admin });
      assert.equal(await rahatTrigger.isLive(), true);
    });
  });

  describe("checks balances of beneficiary", function () {
    it("should return the ERC20 balance of beneficiary", async function () {
      const balance = await rahat.erc20Balance(9670);
      assert.equal(balance, 0);
    });
  });

  describe("Sets the Project Budget", function () {
    it("Should set the project ERC20 budget", async function () {
      await rahatAdmin.setProjectBudget_ERC20("project1", 10000);
      let projec1_erc20Balance = await rahatAdmin.getProjecERC20Balance(
        "project1"
      );
      assert.equal(projec1_erc20Balance.toNumber(), 10000);
    });
  });

  describe("Issue Tokens", function () {
    it("should issue ERC20 token to beneficiary", async function () {
      await rahat.issueERC20ToBeneficiary("project1", phone1, 1000, {
        from: mobilizer,
      });
      const erc20BalanceOfPhone1 = await rahat.erc20Balance(phone1);
      assert.equal(erc20BalanceOfPhone1, 1000);
    });

    it("should issue ERC20 token to beneficiary in bulk", async function () {
      const callData2 = web3.eth.abi.encodeFunctionCall(
        getInterface("Rahat", "issueERC20ToBeneficiary"),
        ["project1", phone2, 1000]
      );
      const callData3 = web3.eth.abi.encodeFunctionCall(
        getInterface("Rahat", "issueERC20ToBeneficiary"),
        ["project1", phone3, 1000]
      );
      await rahat.multicall([callData2, callData3]);
      const erc20BalanceOfPhone2 = await rahat.erc20Balance(phone2);
      const erc20BalanceOfPhone3 = await rahat.erc20Balance(phone3);
      const erc20IssuedToPhone2 = await rahat.erc20Issued(phone2);
      const erc20IssuedToPhone3 = await rahat.erc20Issued(phone3);
      assert.equal(erc20BalanceOfPhone2, 1000);
      assert.equal(erc20BalanceOfPhone3, 1000);
      assert.equal(erc20IssuedToPhone2, 1000);
      assert.equal(erc20IssuedToPhone3, 1000);
    });

    it("should check balance through multicall", async function () {
      const callData1 = web3.eth.abi.encodeFunctionCall(
        getInterface("Rahat", "erc20Balance"),
        [phone1]
      );
      const callData2 = web3.eth.abi.encodeFunctionCall(
        getInterface("Rahat", "erc20Balance"),
        [phone2]
      );
      const callData3 = web3.eth.abi.encodeFunctionCall(
        getInterface("Rahat", "erc20Balance"),
        [phone3]
      );
      const results = await rahat.multicall.call([
        callData1,
        callData2,
        callData3,
      ]);
      const balances = results.map((el) => {
        const d = web3.eth.abi.decodeParameter("uint256", el);
        return d;
      });
      balances.map((el) => {
        assert.equal(el, 1000);
      });
    });
  });

  describe("request tokens from vendor to beneficiary", function () {
    it("should create erc20 token claim from vendor to beneficiary", async function () {
      await rahat.createERC20Claim(phone1, 1000, { from: vendor });
      const phone1Hash = web3.utils.soliditySha3({
        type: "string",
        value: phone1.toString(),
      });
      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 1000);
      assert.equal(claim.isReleased, false);
    });
  });

  describe("Approve requested claims by setting OTP from server account", function () {
    it("should approve erc20 token claim from server account", async function () {
      await rahat.approveERC20Claim(vendor, phone1, otpHash, 2000, {
        from: server,
      });
      const phone1Hash = web3.utils.soliditySha3({
        type: "string",
        value: phone1.toString(),
      });
      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 1000);
      assert.equal(claim.isReleased, true);
    });
  });

  describe("Should get tokens after entering correct OTP", function () {
    it("should get erc20 tokens from claim made after entering otp set by server", async function () {
      await rahat.getERC20FromClaim(phone1, otp, { from: vendor });
      const phone1Hash = web3.utils.soliditySha3({
        type: "string",
        value: phone1.toString(),
      });
      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 0);
      assert.equal(claim.isReleased, false);
    });
  });
});
