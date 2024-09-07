// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Prompt.sol";

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

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _promptContractAddress) {
        owner = msg.sender;
        promptContract = Prompt(_promptContractAddress);
    }

    // function to get AI result from the Prompt contract
    function fetchAIResult(
        uint256 modelId,
        string calldata prompt
    ) external onlyOwner {
        AIResult = promptContract.getAIResult(modelId, prompt);
    }

    // function converts string to enum value and change selectedPlatform value
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
}
