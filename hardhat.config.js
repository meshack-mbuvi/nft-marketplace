require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config({ path: ".env" });

/**
 * contract addresses:
 * NFT deployed to: 0x30c87E128F8d383bDdbD30099848d39f8934c430
NFT Marketplace deployed to: 0x2624669febf68Ee2Ec687960e7462E52eB79202a
 */
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    sepolia: {
      url: process.env.RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 11155111, // chain ID for sepolia test network
    },
  },
};
