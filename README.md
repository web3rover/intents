# intents

## Run Ganache

```
ganache --fork <ethereum-mainnet-rpc-url> --port 8545 -h=0.0.0.0 -m="rifle cloud amused end pyramid swarm anxiety kitchen ceiling cotton rib gain"  --wallet.unlockedAccounts="0x51eDF02152EBfb338e03E30d65C15fBf06cc9ECC" --gasPrice 19933918981 --fork.blockNumber=17963377

 ganache --fork <ethereum-mainnet-rpc-url> --port 8545 -h=0.0.0.0 -m="rifle cloud amused end pyramid swarm anxiety kitchen ceiling cotton rib gain"  --wallet.unlockedAccounts="0x593c427d8C7bf5C555Ed41cd7CB7cCe8C9F15bB5" --gasPrice 19933918981 --fork.blockNumber=17963377
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