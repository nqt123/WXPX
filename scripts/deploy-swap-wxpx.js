// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  const tokenName = "Wrapped XPX";
  const symbol = "WXPX";
  const decimals = 18;
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  await hre.run('compile');

  // We get WXPX the contract to deploy
  const WXPX = await hre.ethers.getContractFactory("WXPX");

  console.log("Deploying WXPX");

  const wXPX = await WXPX.deploy(tokenName, symbol, decimals);
  await wXPX.deployed();

  console.log("Deployed WXPX at:", wXPX.address);

  // We get Swap XPX the contract to deploy
  const SwapWxpx = await hre.ethers.getContractFactory("SwapWXPX");

  console.log("Deploying Swap WXPX");

  const swapWxpx = await SwapWxpx.deploy(wXPX.address);
  await swapWxpx.deployed();

  console.log("Deployed Swap WXPX at:", swapWxpx.address);

  // Grant minter / burner role
  const bytes32MinterRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes('MINTER_ROLE'));
  const bytes32BurnerRole = hre.ethers.utils.keccak256(hre.ethers.utils.toUtf8Bytes('BURNER_ROLE'));

  await wXPX.grantRole(bytes32MinterRole, swapWxpx.address);
  await wXPX.grantRole(bytes32BurnerRole, swapWxpx.address);

  // Auto-verify after deploy
  const verifyWxpx = await verifyContract(wXPX.address, [tokenName, symbol, decimals]);
  const verifySwapWxpx = await verifyContract(swapWxpx.address, [wXPX.address]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

const verifyContract = async (contractAddress, [...args]) => {
  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: args,
  })
}
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
