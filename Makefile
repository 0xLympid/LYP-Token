# Load environment variables from .env file
include .env
export $(shell sed 's/=.*//' .env)

test:
	forge test

# Extract deployed contract addresses from log
extract-addresses:
	@grep "Deployed contract to address" deploy.log | awk '{print $$NF}' > addresses.txt

# General deploy script for any chain
deploy:
	forge script script/Defender.s.sol:DefenderScript --force --rpc-url $(RPC_URL) --broadcast | tee deploy.log

# General verify script for any chain
verify:
	@address1=$$(sed -n '1p' addresses.txt); \
	address2=$$(sed -n '2p' addresses.txt); \
	forge verify-contract --chain-id $(CHAIN_ID) --num-of-optimizations 10000 --watch \
	--constructor-args $$(cast abi-encode "constructor(string,string,uint256,uint256)" "Lympid" "LYP" 18 100000000000000000000000000) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version v0.8.25 \
	$$address1 src/token/ERC677/BurnMintERC677.sol:BurnMintERC677; \
	forge verify-contract --chain-id $(CHAIN_ID) --num-of-optimizations 10000 --watch \
	--constructor-args $$(cast abi-encode "constructor(address)" $$address1) \
	--etherscan-api-key $(ETHERSCAN_API_KEY) --compiler-version v0.8.25 \
	$$address2 src/vesting/TokenVesting.sol:TokenVesting

# Sepolia specific targets
deploy-sepolia:
	$(MAKE) deploy RPC_URL=$(SEPOLIA_RPC_URL)

verify-sepolia:
	$(MAKE) verify CHAIN_ID=$(SEPOLIA_CHAIN_ID) ETHERSCAN_API_KEY=$(ETHERSCAN_API_KEY)

# Mainnet specific targets
deploy-mainnet:
	$(MAKE) deploy RPC_URL=$(MAINNET_RPC_URL)

verify-mainnet:
	$(MAKE) verify CHAIN_ID=$(MAINNET_CHAIN_ID) ETHERSCAN_API_KEY=$(ETHERSCAN_API_KEY)

# BSC specific targets
deploy-bsc:
	$(MAKE) deploy RPC_URL=$(BSC_RPC_URL)

verify-bsc:
	$(MAKE) verify CHAIN_ID=$(BSC_CHAIN_ID) ETHERSCAN_API_KEY=$(BSCSCAN_API_KEY)

# target for testnet deployment and verification
testnet: deploy-sepolia extract-addresses verify-sepolia

# target for mainnet deployment and verification
mainnet: deploy-mainnet extract-addresses verify-mainnet deploy-bsc extract-addresses verify-bsc

.PHONY: test deploy extract-addresses verify testnet mainnet deploy-sepolia verify-sepolia deploy-mainnet verify-mainnet deploy-bsc verify-bsc
