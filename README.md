# AI Lending Aggregator

## Deployed Contracts (Ethereum Sepolia)

**LendingPrompt.sol**: 0xc1A146358A8c011aC8419Aea7ba6d05966CC1774

**AILendingAggregator.sol**: 0x3d49D97A7575a554C8206a04DC497365dDf2f294

--------------

## Project Overview

This project implements an AI-driven lending platform aggregator that uses data from the Aave and Compound protocols. 
By leveraging an AI Oracle, the platform dynamically selects the optimal lending platform based on market data provided by both protocols.

--------------

## Key Contracts

**LendingPrompt.sol**

This contract is responsible for interacting with an AI Oracle. 
It generates a prompt containing data from the Aave and Compound lending protocols and sends it to the AI Oracle. 
The oracle returns a recommendation on which platform (Aave or Compound) is the most optimal for lending.

**AILendingAggregator.sol**

This contract aggregates the data from Aave and Compound, generates the prompt, and interacts with the LendingPrompt contract to get AI recommendations.
It holds instances of the Aave and Compound contracts (aaveDataProvider and comet) to fetch live data from these platforms.

--------------

## Running Tests

Install dependencies:

```forge install```

Compile the contracts:

```forge build```

Run tests:

```forge test```

--------------

## Deployment

To deploy the contracts on a network like Sepolia, follow these steps:

Set up environment variables for deployment(DONT USE PASTE YOUR PRODUCTION KEY HERE! USE INTERACTIVE CONSOLE INSTEAD!):

```export PRIVATE_KEY=your_private_key```

```export RPC_URL=YOUR_RPC_URL```

Deploy the contracts:

```forge script script/PromptScript.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast```

Verify the contract on Etherscan:

```forge verify-contract --chain-id 11155111 --compiler-version <solidity_version> --watch --etherscan-api-key <YOUR_ETHERSCAN_KEY>```

