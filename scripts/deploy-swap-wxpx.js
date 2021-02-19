// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  await hre.run('compile');

  // We get WXPX the contract to deploy
  const WXPX = await hre.ethers.getContractFactory("WXPX");

  console.log("Deploying WXPX");

  const wXPX = await WXPX.deploy("Wrapped XPX", "WXPX", 18);
  await wXPX.deployed();

  console.log("Deployed WXPX at:", wXPX.address);

  // We get Swap XPX the contract to deploy
  const SwapWxpx = await hre.ethers.getContractFactory("SwapWXPX");

  console.log("Deploying Swap WXPX");

  const swapWxpx = await SwapWxpx.deploy(wXPX.address);
  await swapWxpx.deployed();
  
  console.log("Deployed Swap WXPX at:", swapWxpx.address);

  // Grant minter / burner role
  await wXPX.grantRole(hre.ethers.utils.formatBytes32String('MINTER_ROLE'), swapWxpx.address);
  await wXPX.grantRole(hre.ethers.utils.formatBytes32String('BURNER_ROLE'), swapWxpx.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
