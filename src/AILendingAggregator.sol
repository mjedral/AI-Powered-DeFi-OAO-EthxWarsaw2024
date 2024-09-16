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
    address constant USDT_SEPOLIA = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

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

    function generatePrompt() public view returns (string memory) {
        (
            ,
            ,
            uint256 totalAToken,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            ,
            ,

        ) = aaveDataProvider.getReserveData(USDT_SEPOLIA); // add asset address

        uint256 totalSupply = comet.totalSupply();
        uint256 totalBorrow = comet.totalBorrow();
        uint256 utilization = comet.getUtilization();
        uint256 supplyRate = comet.getSupplyRate(utilization);
        uint256 borrowRate = comet.getBorrowRate(utilization);

        return
            string(
                abi.encodePacked(
                    "I want to forecast the supply rate changes in the Aave and Compound protocol based on the following data. Please provide a prediction for the next 3 days. In both case we compare indicators for WETH token",
                    "AAVE:",
                    " Total Liquidity: ",
                    Strings.toString(totalAToken),
                    ", Total Stable Debt: ",
                    Strings.toString(totalStableDebt),
                    ", Total Variable Debt: ",
                    Strings.toString(totalVariableDebt),
                    ", Liquidity Rate: ",
                    Strings.toString(liquidityRate),
                    ", Variable Borrow Rate: ",
                    Strings.toString(variableBorrowRate),
                    ", Stable Borrow Rate: ",
                    Strings.toString(stableBorrowRate),
                    ", Average Stable Borrow Rate: ",
                    Strings.toString(averageStableBorrowRate),
                    "_____________",
                    ". COMPOUND: ",
                    "Total Supply: ",
                    Strings.toString(totalSupply),
                    ", Total Borrow: ",
                    Strings.toString(totalBorrow),
                    ", Utilization: ",
                    Strings.toString(utilization),
                    ", Supply Rate: ",
                    Strings.toString(supplyRate),
                    ", Borrow Rate: ",
                    Strings.toString(borrowRate),
                    "Based on these data, please provide an estimate of the future supply rate over the next 3 days and generate prompt only with result which option is better. Please answer only with name of protocol. I mean AAVE or COMPOUND"
                )
            );
    }

    // promptContract.calculateAIResult(modelId, prompt) where modelId is llama3 for us(id number 11) and prompt is text message
    // TOREFACTOR
    function calculateAIResult(uint8 modelId) external payable onlyOwner {
        uint256 fee = promptContract.estimateFee(modelId);
        string memory generatedPrompt = generatePrompt();
        promptContract.calculateAIResult{value: fee}(modelId, generatedPrompt);
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
    
        aave and compound rates fetching logic

        AAVE: https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate

        we need getReserveData() from here: https://github.com/aave/aave-v3-core/blob/master/contracts/misc/AaveProtocolDataProvider.sol#L164

        and after that we have to count supplyRate using this: https://docs.aave.com/risk/liquidity-risk/borrow-interest-rate

        Compound: https://docs.compound.finance/interest-rates/#get-utilization

    */
}
