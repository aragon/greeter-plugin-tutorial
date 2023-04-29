/** 
 * Run this contract deployment script using: 
 * ``npx hardhat run --network goerli scripts/deploy-plugin.ts``
 */ 
import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const getGreeterSetup = await ethers.getContractFactory("GreeterPluginSetup");
  const GreeterSetup = await getGreeterSetup.deploy();

  await GreeterSetup.deployed();

  console.log("GreeterPluginSetup deployed to:", GreeterSetup.address);
}

// Pattern enabling to use async/await everywhere and report any errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
