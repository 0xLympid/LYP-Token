# $LYP

- Foundry project for the $LYP token and token vesting Solidity contracts

## Wiki

### Get Started

**Test**

1. Run tests

```bash
make test
```

**Deploy**

- The deploy script uses OZ Defender to deploy the contracts using the CREATE2 pattern with a Safe Multisig. When you run the script you must submit the transaction in OZ Defender.

1. Set ENVs in the .env file

```bash
MAINNET_RPC_URL=
MAINNET_CHAIN_ID=
BSC_RPC_URL=
BSC_CHAIN_ID=
SEPOLIA_RPC_URL=
SEPOLIA_CHAIN_ID=11155111
ETHERSCAN_API_KEY=
BSCSCAN_API_KEY=
DEFENDER_KEY=
DEFENDER_SECRET=
```

2. Run deploy script for the target environment

```bash
make testnet
make mainnet
```

### Vendors

- [OpenZeppelin v5.0.2](https://github.com/OpenZeppelin/openzeppelin-contracts/releases/tag/v5.0.2)

## Contract Addresses

### Testnets

``BurnMintERC677``

|  Network    |  Address  |
|:-----------:|-----------|
| Sepolia     | [0x2cd1887dfDef58B58d5A860256e3e8f2e6046920](https://sepolia.etherscan.io/address/0x2cd1887dfDef58B58d5A860256e3e8f2e6046920) |

``TokenVesting``

|  Network    |  Address  |
|:-----------:|-----------|
| Sepolia     | [0x7aDe95abfA3B0B684bB143f06403094d72709F4C](https://sepolia.etherscan.io/address/0x7aDe95abfA3B0B684bB143f06403094d72709F4C) |
