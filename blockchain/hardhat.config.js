const { HardhatUserConfig } = require("hardhat/config");
require("@nomicfoundation/hardhat-toolbox");
require("dotenv/config");

const config = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    "linea-sepolia": {
      url: `https://linea-sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [process.env.ACCOUNT_PRIVATE_KEY].filter(Boolean),
    },
  },
};

module.exports = config;