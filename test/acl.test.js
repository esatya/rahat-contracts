const Rahat = artifacts.require("Rahat");
const RahatTriggerResponse = artifacts.require("RahatTriggerResponse");
const RahatERC20 = artifacts.require("RahatERC20");
const RahatAdmin = artifacts.require("RahatAdmin");

describe("------ ACL Tests ------", function () {
  let rahatERC20;
  let rahat;
  let rahatTrigger;
  let serverRole;
  let adminRole;
  let vendorRole;
  let mobilizerRole;
  let managerRole;
  let rahatAdmin;

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

  describe("heplers test", function () {
    const phone1 = 1111111111;
    it("should return the sum of array", async function () {
      const sum = await rahat.getArraySum([10, 20, 30]);
      assert.equal(60, sum);
    });

    it("should hash of given string", async function () {
      const hash = await rahat.findHash(phone1.toString());
      const expectedhash = web3.utils.soliditySha3({
        type: "string",
        value: phone1.toString(),
      });
      assert.equal(hash, expectedhash);
    });
  });
});
