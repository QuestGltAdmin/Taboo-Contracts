require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomiclabs/hardhat-waffle");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: 
  {
    compilers: [
    {
      version: "0.8.0",
      settings: {
          optimizer: {
            enabled: true,
            runs: 200,  
          }
        },
    },
    {
      version: "0.6.12",
      settings: {
          optimizer: {
            enabled: true,
            runs: 200,  
          }
        },
    },
    {
      version: "0.8.4",
      settings: {
          optimizer: {
            enabled: true,
            runs: 200,  
          }
        },
    },
    {
      version: "0.8.13",
      settings: {
          optimizer: {
            enabled: true,
            runs: 200,  
          }
        },
    },
    ]
  },
  networks: {
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/" || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.ROPSTEN_ID}` || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    matic: {
      url: "https://rpc-mumbai.matic.today" || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY,
  },
};
