import { ethers, network } from "hardhat";

async function main() {
  const [
    deployer,
    user
  ] = await ethers.getSigners();

  const intentSenderContractAddress = process.env.INTENT_SENDER_CONTRACT_ADDRESS || "";
  const ethereumUSDCContractAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
  const polygonChainId = 109;
  const intent = await ethers.getContractAt("IntentSender", intentSenderContractAddress, user);

  // mint 
  const usdcMintAmount = "100000000" //100 USDC with 6 decimals
  const usdcReserveHolder = "0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC"

  const usdc = await ethers.getContractAt("IERC20", ethereumUSDCContractAddress, user);
  console.log(`USDC balance of reserve holder: ${await usdc.balanceOf(usdcReserveHolder)}`);
  const provider = ethers.getDefaultProvider(process.env.ETHEREUM_MAINNET_URL || "");
  const data = await usdc.transfer.populateTransaction(user.address, usdcMintAmount);
  await provider.send("eth_sendTransaction", [{ from: usdcReserveHolder, to: ethereumUSDCContractAddress, data: data.data }]);
  console.log(`USDC balance of user: ${await usdc.balanceOf(user.address)}`);

  // approve USDC
  await usdc.approve(intentSenderContractAddress, usdcMintAmount);
  console.log("Approved USDC for IntentSender")

  const fee = await intent.getCrossChainTransferFee(polygonChainId, user.address);
  console.log(`Cross chain transfer fee: ${fee.toString()}`);

  // send intent
  await intent.sendIntent(
    polygonChainId,
    ethereumUSDCContractAddress,
    usdcMintAmount,
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
