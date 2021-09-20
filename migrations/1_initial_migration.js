const RahatERC20 = artifacts.require('RahatERC20');
const RahatERC1155 = artifacts.require('RahatERC1155');
const Rahat = artifacts.require('Rahat');
const RahatAdmin = artifacts.require('RahatAdmin');

module.exports = async function(deployer) {
  await deployer.deploy(
    RahatERC20,
    'Rahat',
    'RHT',
    '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06'
  );
  const RahatERC20Deployed = await RahatERC20.deployed();
  console.log(RahatERC20Deployed.address);

  await deployer.deploy(
    RahatERC1155,
    '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06'
  );
  const RahatERC1155Deployed = await RahatERC1155.deployed();
  console.log(RahatERC1155Deployed.address);

  await deployer.deploy(
    Rahat,
    RahatERC20Deployed.address,
    RahatERC1155Deployed.address,
    '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06'
  );

  const RahatDeployed = await Rahat.deployed();

  const RahatAdminDeployed = await deployer.deploy(
    RahatAdmin,
    RahatERC20Deployed.address,
    RahatERC1155Deployed.address,
    RahatDeployed.address,
    '10000000000000000000',
    '0xcDEe632FB1Ba1B3156b36cc0bDabBfd821305e06'
  );

  //===============MAINNET=============
  // const swapper = await deployer.deploy(
  //   Swapper,
  //   '0x96e322f2a4f151cd898f86ea5626cc6e10090c76',
  //   '0x40eb746dee876ac1e78697b7ca85142d178a1fc8',
  //   '0x96e322f2a4f151cd898f86ea5626cc6e10090c76',
  //   1661856263
  // );
  //================MAINNET==============

  // console.log(swapper.address);
  // deployer.deploy(IAGON, 'Iagon', 'Iag').then(function(IAGON_OLD) {
  //   deployer.deploy(IAGON, 'Iagon2', 'Iag2').then(function(IAGON_NEW) {
  //     console.log(IAGON_NEW.address);

  //     return deployer.deploy(
  //       SWAPPER,
  //       IAGON_OLD.address,
  //       IAGON_NEW.address,
  //       IAGON_OLD.address,
  //       1667008355
  //     );
  //   });
  // deployer.link(IndexKeyGenerator, Lottery);
  //});
};

// module.exports = function(deployer) {
//   //console.log(deployer);
//   //deployer.deploy(IndexKeyGenerator);
//   deployer.deploy(LotteryNFT).then(function() {
//     console.log(LotteryNFT.address);
//     return deployer.deploy(
//       Lottery,
//       '0x9eAB0a93b0cd5d904493694F041BdCedb97b88C6',
//       LotteryNFT.address,
//       '1000000000000000000',
//       14,
//       '0xD2B904b1cbA5436FE504Da9afB721AD41BE251b7',
//       '0xD2B904b1cbA5436FE504Da9afB721AD41BE251b7'
//     );
//   });
// };
