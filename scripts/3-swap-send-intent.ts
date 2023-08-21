import { ethers } from "hardhat";

async function main() {
  const [
    deployer,
    user
  ] = await ethers.getSigners();

  // update this variable
  const intentSenderContractAddress = process.env.INTENT_SENDER_CONTRACT_ADDRESS || "";

  const maticUSDCContractAddress = "0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7";
  const wmaticContractAddress = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
  const wmaticMintAmount = ethers.parseEther("100").toString()
  const arbitrumChainId = 10143;

  const intent = await ethers.getContractAt("IntentSender", intentSenderContractAddress, user);

  const wmatic = await ethers.getContractAt("IWETH", wmaticContractAddress, user);
  await wmatic.deposit({ value: wmaticMintAmount });

  console.log(`WMATIC balance of user: ${await wmatic.balanceOf(user.address)}`);

  // approve wmatic
  await wmatic.approve(intentSenderContractAddress, wmaticMintAmount);
  console.log("Approved WMatic for IntentSender")

  // send intent
  // await intent.sendIntent(
  //   arbitrumChainId,
  //   wmaticContractAddress,
  //   wmaticMintAmount,
  // );

  const uniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  const router = await ethers.getContractAt("IUniswapV2Router01", uniswapRouter, user);
  await wmatic.approve(uniswapRouter, wmaticMintAmount);
  await router.swapExactTokensForTokens(
    wmaticMintAmount,
    0,
    [wmaticContractAddress, maticUSDCContractAddress],
    user.address,
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
