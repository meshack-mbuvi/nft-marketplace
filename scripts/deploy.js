const hre = require("hardhat");

async function main() {
  // Load the NFT contract artifacts
  const nftContract = await hre.ethers.deployContract("NFT");

  // Wait and Deploy the contract
  await nftContract.waitForDeployment();

  // Print the address of the NFT contract
  console.log("NFT deployed to:", nftContract.target);

  // Load the marketplace contract artifacts
  const NFTMarketplace = await hre.ethers.deployContract("NFTMarketplace");

  // Wait and Deploy the contract
  await NFTMarketplace.waitForDeployment();

  // Log the address of the new contract
  console.log("NFT Marketplace deployed to:", NFTMarketplace.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
