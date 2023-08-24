import { ethers, network } from "hardhat";

async function main() {
  const [
    deployer,
  ] = await ethers.getSigners();

  const optimismUSDCContractAddress = "0x0CEDBAF2D0bFF895C861c5422544090EEdC653Bf";
  const optimismUniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  
  const intentReceiver = await ethers.deployContract("IntentReceiver", [
    optimismUSDCContractAddress,
    optimismUniswapRouter
  ], {
    from: deployer.address
  });

  await intentReceiver.waitForDeployment();

  console.log("IntentReceiver deployed to:", intentReceiver.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
