# intents

## Set ENV

```
DEPLOYER_PRIVATE_KEY=""
ETHEREUM_MAINNET_URL=""
OPTIMISM_MAINNET_URL=""
ETHEREUM_GOERLI_URL=""
OPTIMISM_GOERLI_URL=""
```

## Run Testnet Deployment

```
npx hardhat run --network optimism_goreli scripts/1-deploy-intent-receiver.ts
npx hardhat run --network ethereum_goreli scripts/2-deploy-intent-sender.ts
```

## Run Intent Sender Tests

```
ganache --fork <url> --port 8545 -h=0.0.0.0 -m="rifle cloud amused end pyramid swarm anxiety kitchen ceiling cotton rib gain"  --wallet.unlockedAccounts="0x593c427d8C7bf5C555Ed41cd7CB7cCe8C9F15bB5" --gasPrice 19933918981 --fork.blockNumber=18107948


```