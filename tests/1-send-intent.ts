import { ethers, network } from "hardhat";

async function main() {
  const [
    deployer
  ] = await ethers.getSigners();

  const ethereumChainId = 101;
  const ethereumUSDCPoolId = 1;
  const ethereumUSDCAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
  const ethereumStgRouter = "0x8731d54E9D02c286767d56ac03e8037C07e01e98";

  const intentSender = await ethers.deployContract("IntentSender", [
    ethereumChainId,
    ethereumUSDCPoolId,
    ethereumUSDCAddress,
    ethereumStgRouter,
  ], {
    from: deployer.address
  });

  await intentSender.waitForDeployment();

  console.log(`IntentSender deployed on Ethereum: ${intentSender.target}`);

  const optimismChainId = 111;
  const optimismUSDCPoolId = 1;

  await intentSender.setDestination(optimismChainId, optimismUSDCPoolId, "0x0000000000000000000000000000000000000001");

  console.log(`Optimism destination configured`);

  const ethereumWBTCContractAddress = "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599";
  const optimismWETHAddress = "0x4200000000000000000000000000000000000006";
  const optimismUSDCAddress = "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85";

  // // mint 
  const wbtcMintAmount = "100000000" //1 WBTC with 8 decimals
  const wbtcReserveHolder = "0x593c427d8C7bf5C555Ed41cd7CB7cCe8C9F15bB5"

  const wbtc = await ethers.getContractAt("IERC20", ethereumWBTCContractAddress, deployer);
  console.log(`WBTC balance of reserve holder: ${await wbtc.balanceOf(wbtcReserveHolder)}`);
  const provider = ethers.getDefaultProvider(process.env.ETHEREUM_MAINNET_URL || "");
  const data = await wbtc.transfer.populateTransaction(deployer.address, wbtcMintAmount);
  await provider.send("eth_sendTransaction", [{ from: wbtcReserveHolder, to: ethereumWBTCContractAddress, data: data.data }]);
  console.log(`USDC balance of user: ${await wbtc.balanceOf(deployer.address)}`);

  // approve USDC
  await wbtc.approve(intentSender.target, wbtcMintAmount);
  console.log("Approved WBTC for IntentSender")

  //https://api.0x.org/swap/v1/quote?buyToken=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48&sellToken=0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599&sellAmount=100000000
  const ethereumSwapper = "0xdef1c0ded9bec7f1a1670819833240f027b25eff"
  const ethereumSwapperData = "0x415565b00000000000000000000000002260fac5e5542a773aa44fbcfedf7c193bc2c599000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb480000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000005e9b1ad3800000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000004400000000000000000000000000000000000000000000000000000000000000540000000000000000000000000000000000000000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000380000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002260fac5e5542a773aa44fbcfedf7c193bc2c599000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000340000000000000000000000000000000000000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000005f5e100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000012556e69737761705633000000000000000000000000000000000000000000000000000000000000000000000005f5e10000000000000000000000000000000000000000000000000000000005ebf7ceef000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000e592427a0aece92de3edee1f18e0157c058615640000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000422260fac5e5542a773aa44fbcfedf7c193bc2c5990001f4c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20001f4a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001b000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4800000000000000000000000000000000000000000000000000000000024621b7000000000000000000000000ad01c20d5886137e056775af56915de824c8fce5000000000000000000000000000000000000000000000000000000000000001c000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000020000000000000000000000002260fac5e5542a773aa44fbcfedf7c193bc2c599000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000869584cd0000000000000000000000001000000000000000000000000000000000000011000000000000000000000000000000000d4d7f80e0cc122e7f32f65f05a3e933"

  //buy amount is 25652.478313 USDC from 1inch API. So 99.94% sould be the swap input amount for destionation swap i.e., 25637.086830 USDC
  //https://optimism.api.0x.org/swap/v1/quote?buyToken=0x4200000000000000000000000000000000000006&sellToken=0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85&sellAmount=25637086830
  const optimismSwapper = "0xdef1abe32c034e558cdd535791643c58a13acc10";
  const optimismSwapperData = "0x415565b00000000000000000000000000b2c639c533813f4aa9d7837caf62653d097ff85000000000000000000000000420000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000005f816e66e000000000000000000000000000000000000000000000000d9d1adc85c87b0e000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000044000000000000000000000000000000000000000000000000000000000000007600000000000000000000000000000000000000000000000000000000000000860000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000360000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b2c639c533813f4aa9d7837caf62653d097ff850000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000000000000000000000000000000000000000001400000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000002e000000000000000000000000000000000000000000000000000000005f816e66e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000012556e697377617056330000000000000000000000000000000000000000000000000000000000000000000005f816e66e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000e592427a0aece92de3edee1f18e0157c0586156400000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b0b2c639c533813f4aa9d7837caf62653d097ff850001f47f5c764cbc14f9669b88837ca1490cca17c316070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000002c0000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c3160700000000000000000000000042000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000028000000000000000000000000000000000000000000000000000000000000002800000000000000000000000000000000000000000000000000000000000000240ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000001f574f4f46690000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000da25726f2f29291f00000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000020000000000000000000000000eaf1ac8e89ea0ae13e0f03634a4ff23502527024000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000042000000000000000000000000000000000000060000000000000000000000000000000000000000000000000053c4a6d2a17840000000000000000000000000ad01c20d5886137e056775af56915de824c8fce5000000000000000000000000000000000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000c000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000b2c639c533813f4aa9d7837caf62653d097ff850000000000000000000000007f5c764cbc14f9669b88837ca1490cca17c31607000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000869584cd000000000000000000000000100000000000000000000000000000000000001100000000000000000000000000000000cebb1358da399dcec71051e5ef06cfac";

  const destinationNativeAmount = "10000000000000000";

  const fee = await intentSender.getCrossChainTransferFee(
    optimismChainId, destinationNativeAmount, optimismSwapper, optimismSwapperData
  );

  console.log(`Cross chain transfer fee: ${fee.toString()}`);

  // send intent
  await intentSender.sendIntent(
    {
      destinationChainId: optimismChainId,
      sourceToken: ethereumWBTCContractAddress,
      amount: wbtcMintAmount,
      destinationToken: optimismWETHAddress,
      destinationNativeAmount: destinationNativeAmount,
      sourceSwapper: ethereumSwapper,
      destinationSwapper: optimismSwapper,
      sourceSwapData: ethereumSwapperData,
      destinationSwapData: optimismSwapperData,
    },
    {
      value: fee
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