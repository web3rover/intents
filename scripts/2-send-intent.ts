import { ethers } from "hardhat";

async function main() {
  const [
    deployer,
    user
  ] = await ethers.getSigners();

  // update this variable
  const intentSenderContractAddress = "0xaF7a8d953D2556ad3D779b0AA9E8dae0E7EaD965";

  const maticUSDCContractAddress = "0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7";
  const usdcMintAmount = "100000000" //100 USDC with 6 decimals
  const arbitrumChainId = 10143;

  const intent = await ethers.getContractAt("IntentSender", intentSenderContractAddress, user);

  // mint USDC
  const usdc = await ethers.getContractAt("IERC20", maticUSDCContractAddress, user);
  await usdc.mint(user.address, usdcMintAmount);
  console.log(`USDC balance of user: ${await usdc.balanceOf(user.address)}`);

  // approve USDC
  await usdc.approve(intentSenderContractAddress, usdcMintAmount);
  console.log("Approved USDC for IntentSender")

  const fee = await intent.getCrossChainTransferFee(arbitrumChainId, user.address);
  console.log("Fee required: ", fee.toString());

  // send intent
  await intent.sendIntent(
    arbitrumChainId,
    maticUSDCContractAddress,
    usdcMintAmount,
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
