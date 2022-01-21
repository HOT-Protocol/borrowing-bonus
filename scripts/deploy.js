// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const hott = "0x4D17cD00b9767D20DEf3c05302BaB555fcD6238F";
  const proxyRegistry = "0x0cA1604Ac27Ec5e6107c872fBC7Fe9fF0013A447";
  
  const BorrowingBonus = await hre.ethers.getContractFactory("BorrowingBonus");
  const borrowingBonus = await BorrowingBonus.deploy(hott, proxyRegistry);

  await borrowingBonus.deployed();

  console.log("BorrowingBonus deployed to:", borrowingBonus.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
