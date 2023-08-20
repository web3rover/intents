import { ethers } from "hardhat";

async function main() {
  const [
    deployer,
  ] = await ethers.getSigners();

  const maticAmountToDeposit = ethers.parseEther("100").toString()
  const maticChainId = 10109;
  const maticUSDCPoolId = 1;
  const maticUSDCAddress = "0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7";
  const maticRouter = "0x817436a076060D158204d955E5403b6Ed0A5fac0";
  const uniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";

  const intentSender = await ethers.deployContract("IntentSender", [
    maticChainId,
    maticUSDCPoolId,
    maticUSDCAddress,
    maticRouter,
    uniswapRouter
  ], {
    value: maticAmountToDeposit,
    from: deployer.address
  });

  await intentSender.waitForDeployment();

  console.log(`IntentSender deployed to ${intentSender.target}`);

  // set destination chain id
  const arbitrumChainId = 10143;
  const arbitrumUSDCPoolId = 1;
  await intentSender.setDestination(arbitrumChainId, arbitrumUSDCPoolId);

  console.log(`Arbitrum destination chain id set to ${arbitrumChainId}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
