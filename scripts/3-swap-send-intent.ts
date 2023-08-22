import { ethers, network } from "hardhat";

async function main() {
  const [
    deployer,
    user
  ] = await ethers.getSigners();

  const intentSenderContractAddress = process.env.INTENT_SENDER_CONTRACT_ADDRESS || "";
  const ethereumWBTCContractAddress = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  const polygonWETHAddress = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  const polygonChainId = 109;
  const intent = await ethers.getContractAt("IntentSender", intentSenderContractAddress, user);

  // mint 
  const wbtcMintAmount = "100000000" //1 WBTC with 8 decimals
  const wbtcReserveHolder = "0x593c427d8C7bf5C555Ed41cd7CB7cCe8C9F15bB5"

  const wbtc = await ethers.getContractAt("IERC20", ethereumWBTCContractAddress, user);
  console.log(`WBTC balance of reserve holder: ${await wbtc.balanceOf(wbtcReserveHolder)}`);
  const provider = ethers.getDefaultProvider(process.env.ETHEREUM_MAINNET_URL || "");
  const data = await wbtc.transfer.populateTransaction(user.address, wbtcMintAmount);
  await provider.send("eth_sendTransaction", [{ from: wbtcReserveHolder, to: ethereumWBTCContractAddress, data: data.data }]);
  console.log(`USDC balance of user: ${await wbtc.balanceOf(user.address)}`);

  // approve USDC
  await wbtc.approve(intentSenderContractAddress, wbtcMintAmount);
  console.log("Approved WBTC for IntentSender")

  const fee = await intent.getCrossChainTransferFee(polygonChainId, user.address);
  console.log(`Cross chain transfer fee: ${fee.toString()}`);

  // send intent
  await intent.sendIntent(
    polygonChainId,
    ethereumWBTCContractAddress,
    wbtcMintAmount,
    polygonWETHAddress,
    0,
    {
      value: (ethers.parseEther("0.1").toString())
    }
  );

  console.log("Intent sent successfully")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
