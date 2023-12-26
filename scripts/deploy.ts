// We require the Hardhat Runtime Environment explicitly here. This is optional but useful for running the
// script in a standalone fashion through `node <script>`. When running the script with `hardhat run <script>`,
// you'll find the Hardhat Runtime Environment's members available in the global scope.
import hre from "hardhat";
import { ethers } from "hardhat";

import { A51LiquidityLocker, A51LiquidityLocker__factory } from "../typechain";

async function main(): Promise<void> {
  const LiquidityLocker: A51LiquidityLocker__factory = await ethers.getContractFactory("A51LiquidityLocker");

  const liquidityLocker: A51LiquidityLocker = await LiquidityLocker.deploy();
  await liquidityLocker.deployed();

  console.log("Quickswap liquidity locker deployed to: ", liquidityLocker.address);

  delay(60000);

  await hre.run("verify:verify", {
    address: liquidityLocker.address,
    constructorArguments: [],
  });
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// We recommend this pattern to be able to use async/await everywhere and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
