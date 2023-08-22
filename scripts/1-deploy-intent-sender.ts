import { ethers, hardhat } from "hardhat";

async function main() {
  const [
    deployer,
  ] = await ethers.getSigners();

  const ethereumAmountToDeposit = ethers.parseEther("100").toString()
  const ethereumChainId = 101;
  const ethereumUSDCPoolId = 1;
  const ethereumUSDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const ethereumStgRouter = "0x8731d54E9D02c286767d56ac03e8037C07e01e98";
  const ethereumUniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";

  const intentSender = await ethers.deployContract("IntentSender", [
    ethereumChainId,
    ethereumUSDCPoolId,
    ethereumUSDCAddress,
    ethereumStgRouter,
    ethereumUniswapRouter
  ], {
    value: ethereumAmountToDeposit,
    from: deployer.address
  });

  await intentSender.waitForDeployment();

  const provider = ethers.getDefaultProvider(process.env.ETHEREUM_MAINNET_URL || "");
  console.log("Balance of intent sender contract: ", await provider.getBalance(intentSender.target));

  console.log(`IntentSender deployed to ${intentSender.target}`);

  // set destination chain id
  const polygonChainId = 109;
  const polygonUSDCPoolId = 1;
  await intentSender.setDestination(polygonChainId, polygonUSDCPoolId);

  console.log(`Arbitrum destination chain id set to ${polygonChainId}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
