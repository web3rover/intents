import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    ethereum: {
      url: process.env.ETHEREUM_MAINNET_URL,
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY || "",
      ],
    },
    optimism: {
      url: process.env.OPTIMISM_MAINNET_URL,
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY || "",
      ],
    },
    ethereum_goreli: {
      url: process.env.ETHEREUM_GOERLI_URL,
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY || "",
      ],
    },
    optimism_goreli: {
      url: process.env.OPTIMISM_GOERLI_URL,
      accounts: [
        process.env.DEPLOYER_PRIVATE_KEY || "",
      ],
    },
  },
};

export default config;
