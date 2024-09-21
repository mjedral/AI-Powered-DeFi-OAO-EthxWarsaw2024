// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LendingPrompt.sol";
import "./interfaces/IPoolDataProvider.sol";
import "./interfaces/IComet.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

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
    LendingPrompt public promptContract;
    IPoolDataProvider public aaveDataProvider;
    IComet public comet;

    event AIResultUpdated(string AIResult);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(
        address _promptContractAddress,
        address _aaveDataProvider,
        address _comet
    ) {
        owner = msg.sender;
        promptContract = LendingPrompt(_promptContractAddress);
        aaveDataProvider = IPoolDataProvider(_aaveDataProvider); // poolDataProvider on sepolia = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31
        comet = IComet(_comet); // cWETHv3 = 0x2943ac1216979aD8dB76D9147F64E61adc126e96
    }

    // function set selectedPlatform up depends on prompt result
    function setLendingPlatform() private {
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

    function checkResultAndSetPlatform(
        uint256 modelId,
        string calldata prompt
    ) external onlyOwner {
        string memory aiResult = promptContract.getAIResult(modelId, prompt);
        require(bytes(aiResult).length > 0, "Result is not ready yet");
        AIResult = aiResult;
        setLendingPlatform();
    }

    /*
    
       HERE WILL BE LOGIC RESPONSIBLE FOR ADDING SUPPLY TO LENDING PLATFORMS AFTER GETTING RESULT FROM AI MODEL

    */
}
