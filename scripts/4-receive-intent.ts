import { ethers, network } from "hardhat";

async function main() {
  const [
    deployer,
    user
  ] = await ethers.getSigners();

  const polygonUSDCContractAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174";
  const polygonWETHContractAddress = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  const polygonUniswapRouter = "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45";
  
  const intentReceiver = await ethers.deployContract("IntentReceiver", [
    polygonUSDCContractAddress,
    polygonUniswapRouter
  ], {
    from: deployer.address
  });

  await intentReceiver.waitForDeployment();

  // mint 
  const usdcMintAmount = "100000000" //100 USDC
  const usdcReserveHolder = "0x075e72a5eDf65F0A5f44699c7654C1a76941Ddc8"

  const usdc = await ethers.getContractAt("IERC20", polygonUSDCContractAddress, deployer);
  console.log(`USDC balance of reserve holder: ${await usdc.balanceOf(usdcReserveHolder)}`);
  const provider = ethers.getDefaultProvider(process.env.POLYGON_MAINNET_URL || "");
  const data = await usdc.transfer.populateTransaction(deployer.address, usdcMintAmount);
  await provider.send("eth_sendTransaction", [{ from: usdcReserveHolder, to: polygonUSDCContractAddress, data: data.data }]);
  console.log(`USDC balance of deployer: ${await usdc.balanceOf(deployer.address)}`);

  // approve USDC
  await usdc.transfer(intentReceiver.target, usdcMintAmount);
  console.log("Transfered USDC for IntentReceiver. Balance is: ", await usdc.balanceOf(intentReceiver.target))

  // send intent
  const weth = await ethers.getContractAt("IERC20", polygonWETHContractAddress, deployer);
  console.log(await intentReceiver.sourceTokenAddress(), polygonWETHContractAddress)
  console.log("Previous WETH balance of user: ", await weth.balanceOf(user.address))
  console.log("Previous MATIC balance of user: ", await provider.getBalance(user.address))
  await intentReceiver.receiveIntent(
    polygonWETHContractAddress,
    user.address,
    usdcMintAmount,
    {
      value: (ethers.parseEther("0.1").toString())
    }
  )

  console.log("Intent executed successfully")
  console.log("Current WETH balance of user: ", (await weth.balanceOf(user.address)).toString())
  console.log("Current MATIC balance of user: ", await provider.getBalance(user.address))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
