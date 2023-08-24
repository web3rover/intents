import { ethers, hardhat } from "hardhat";

async function main() {
  const [
    deployer,
  ] = await ethers.getSigners();

  const ethereumChainId = 10121;
  const ethereumUSDCPoolId = 1;
  const ethereumUSDCAddress = "0xDf0360Ad8C5ccf25095Aa97ee5F2785c8d848620";
  const ethereumStgRouter = "0x7612aE2a34E5A363E137De748801FB4c86499152";
  const ethereumUniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  const optimismIntentReceiver = "0xac4c1D5eEC117c983dDF6D96893065f5C0b949aF"; //fill from previous script

  const intentSender = await ethers.deployContract("IntentSender", [
    ethereumChainId,
    ethereumUSDCPoolId,
    ethereumUSDCAddress,
    ethereumStgRouter,
    ethereumUniswapRouter
  ], {
    from: deployer.address
  });

  await intentSender.waitForDeployment();

  console.log(`IntentSender deployed to ${intentSender.target}`);

  // set destination chain id
  const optimismChainId = 10132;
  const optimismUSDCPoolId = 1;
  await intentSender.setDestination(optimismChainId, optimismUSDCPoolId, optimismIntentReceiver);

  console.log(`Optimism destination chain id config set`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
