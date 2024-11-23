const hre = require("hardhat");

async function main() {
  try {
    const [deployer] = await hre.ethers.getSigners();

    console.log("Deploying Croakmarket...");
    console.log("Deployer address:", deployer.address);

    const Croakmarket = await hre.ethers.getContractFactory("Croakmarket");

    const croakmarket = await Croakmarket.deploy();

    await croakmarket.waitForDeployment();

    const contractAddress = await croakmarket.getAddress();

    console.log("Croakmarket deployed to:", contractAddress);
  } catch (error) {
    console.error("Error during deployment:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Unexpected error:", error);
    process.exit(1);
  });