/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-truffle5");
require("solidity-coverage")

module.exports = {
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 50,
      },
    },
  },
  paths: {
    sources: "./src/contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};