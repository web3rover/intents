# intents

## Set ENV

```
DEPLOYER_PRIVATE_KEY=""
ETHEREUM_MAINNET_URL=""
POLYGON_MAINNET_URL=""
```

## Run Testing Scripts

```
npx hardhat run --network optimism scripts/1-receive-intent.ts
npx hardhat run --network ethereum scripts/2-deploy-intent-sender
```