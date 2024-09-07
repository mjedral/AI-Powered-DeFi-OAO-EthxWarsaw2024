// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Prompt.sol";
import "./interfaces/IPoolDataProvider.sol";

contract AILendingAggregator {
    enum LendingPlatform {
        AAVE,
        COMPOUND,
        UNKNOWN
    }
    //check slots order
    LendingPlatform public selectedPlatform;
    string public AIResult;
    address public owner;
    Prompt public promptContract;
    IPoolDataProvider public aaveDataProvider;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _promptContractAddress, address _aaveDataProvider) {
        owner = msg.sender;
        promptContract = Prompt(_promptContractAddress);
        aaveDataProvider = IPoolDataProvider(_aaveDataProvider);
    }

    // function to get AI result from the Prompt contract
    function fetchAIResult(
        uint256 modelId,
        string calldata prompt
    ) external onlyOwner {
        AIResult = promptContract.getAIResult(modelId, prompt);
    }

    // use calculateAIResult to generate prompt like:
    // promptContract.calculateAIResult(modelId, prompt) where modelId is llama3 for us(id number 11) and prompt is text message

    // function set selectedPlatform up depends on prompt result
    function setLendingPlatform() public {
        if (
            keccak256(abi.encodePacked(AIResult)) ==
            keccak256(abi.encodePacked("AAVE"))
        ) {
            selectedPlatform = LendingPlatform.AAVE;
        } else if (
            keccak256(abi.encodePacked(AIResult)) ==
            keccak256(abi.encodePacked("COMPOUND"))
        ) {
            selectedPlatform = LendingPlatform.COMPOUND;
        } else {
            selectedPlatform = LendingPlatform.UNKNOWN;
        }
    }

    /*
    
        aave and compound rates fetching logic

        AAVE: https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate

        we need getReserveData() from here: https://github.com/aave/aave-v3-core/blob/master/contracts/misc/AaveProtocolDataProvider.sol#L164

        and after that we have to count supplyRate using this: https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate

        Compound: https://docs.compound.finance/interest-rates/#get-utilization

    */
}
