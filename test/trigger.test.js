const exceptions = require("./exceptions");
const Rahat = artifacts.require("Rahat");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatTriggerResponse = artifacts.require("RahatTriggerResponse");
const RahatAdmin = artifacts.require("RahatAdmin");

describe("------ Multisig Trigger Tests ------", function () {
  let rahatERC20;
  let rahat;
  let rahatTrigger;
  let rahatAdmin;
  const projectId = "project1";

  before(async function () {
    [deployer, admin1, admin2, admin3, vendor, server] =
      await web3.eth.getAccounts();
    rahatERC20 = await RahatERC20.new("Rahat", "RHT", admin1);
    rahatTrigger = await RahatTriggerResponse.new(admin1, 2);
    rahat = await Rahat.new(rahatERC20.address, rahatTrigger.address, admin1);
    rahatAdmin = await RahatAdmin.new(
      rahatERC20.address,
      rahat.address,
      10000000,
      admin1
    );
  });

  describe("Deployment", function () {
    it("Should deploy the Rahat contract with rahatERC20 contract", async function () {
      assert.equal(await rahat.triggerResponse(), rahatTrigger.address);
      console.log("rahatTrigger:", rahatTrigger.address);
    });
  });

  describe("Manage Admins", function () {
    it("should add admin role to new account via admin account", async function () {
      assert.equal(await rahatTrigger.isAdmin(admin2), false);
      await rahatTrigger.addAdmin(admin2, { from: admin1 });
      await rahatTrigger.addAdmin(admin3, { from: admin1 });
      assert.equal(await rahatTrigger.isAdmin(admin2), true);
      assert.equal(await rahatTrigger.isAdmin(admin3), true);
    });
  });

  describe("Activate Response: 1st Signature", function () {
    it("should add 1st admin confirmation", async function () {
      assert.equal(await rahatTrigger.isLive(), false);
      await rahatTrigger.activateResponse(projectId, { from: admin1 });
      assert.equal(await rahatTrigger.isLive(), false);
    });
  });

  //--------------------------------------------------------
  //      Test token redemption
  //--------------------------------------------------------

  describe("Token activity", function () {
    const phone1 = "111111111";
    const phone1Hash = web3.utils.soliditySha3({
      type: "string",
      value: phone1.toString(),
    });
    const otp = "9670";
    const otpHash = web3.utils.soliditySha3({ type: "string", value: otp });

    it("should asssign budget for project", async function () {
      await rahatAdmin.setProjectBudget_ERC20(projectId, 10000, {
        from: admin1,
      });
      let projecBalance = await rahatAdmin.getProjecERC20Balance(projectId);
      assert.equal(projecBalance.toNumber(), 10000);
    });

    it("should issue token to beneficiary", async function () {
      await rahat.issueERC20ToBeneficiary(projectId, phone1, 1000, {
        from: admin1,
      });
      const erc20BalanceOfPhone1 = await rahat.erc20Balance(phone1);
      assert.equal(erc20BalanceOfPhone1, 1000);
    });

    it("should add vendor and server roles", async function () {
      await rahat.addVendor(vendor, { from: admin1 });
      await rahat.addServer(server, { from: admin1 });
    });

    it("should fail since response is not live yet", async function () {
      exceptions.tryCatch(
        rahat.createERC20Claim(phone1, 1000, { from: vendor })
      );
    });

    it("should add 2nd admin confirmation and activate response", async function () {
      await rahatTrigger.activateResponse(projectId, { from: admin2 });
      assert.equal(await rahatTrigger.isLive(), true);
    });

    it("should create erc20 token claim from vendor to beneficiary", async function () {
      await rahat.createERC20Claim(phone1, 1000, { from: vendor });
      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 1000);
      assert.equal(claim.isReleased, false);
    });

    it("should approve erc20 token claim by server account", async function () {
      await rahat.approveERC20Claim(vendor, phone1, otpHash, 2000, {
        from: server,
      });

      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 1000);
      assert.equal(claim.isReleased, true);
    });

    it("should get erc20 tokens from claim made after entering otp set by server", async function () {
      await rahat.getERC20FromClaim(phone1, otp, { from: vendor });

      const claim = await rahat.recentERC20Claims(vendor, phone1Hash);
      assert.equal(claim.amount, 0);
      assert.equal(claim.isReleased, false);
      const vendorBalance = await rahatERC20.balanceOf(vendor);
      assert.equal(vendorBalance.toNumber(), 1000);
    });
  });
  //--------------------------------------------------------
  describe("Deactivate Response", function () {
    it("should deactive response by admin", async function () {
      await rahatTrigger.deactivateResponse({ from: admin2 });
      assert.equal(await rahatTrigger.isLive(), false);
    });
  });
});
