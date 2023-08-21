# intents

## Run Ganache

```
ganache --fork <ethereum-mainnet-url> --port 8545 -h=0.0.0.0 -m="rifle cloud amused end pyramid swarm anxiety kitchen ceiling cotton rib gain" --wallet.unlockedAccounts="0xcEe284F754E854890e311e3280b767F80797180d"
```

## Set ENV

```
DEPLOYER_PRIVATE_KEY="0x54ae3b70c6c1a496e10ef9ccd118eafc37fb588f5a7c68fc8bf9780d06218ba0"
USER_PRIVATE_KEY="0x3eec730f3e26489d4a3392f0a25ed3602cd312b484ddc37beef31c2571d5e2bb"
ETHEREUM_MAINNET_URL="http://localhost:8545"
INTENT_SENDER_CONTRACT_ADDRESS="0xaF7a8d953D2556ad3D779b0AA9E8dae0E7EaD965"
```

## Run Testing Scripts

```
npx hardhat run --network ethereum scripts/1-deploy-intent-sender.ts
npx hardhat run --network ethereum scripts/2-send-intent.ts
npx hardhat run --network ethereum scripts/3-swap-send-intent.ts 
```