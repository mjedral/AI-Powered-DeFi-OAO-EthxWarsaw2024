// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Prompt.sol";
import "./interfaces/IPoolDataProvider.sol";
import "./interfaces/IComet.sol";

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
    IComet public comet;
    address constant WETH_SEPOLIA = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;

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
        promptContract = Prompt(_promptContractAddress);
        aaveDataProvider = IPoolDataProvider(_aaveDataProvider); // poolDataProvider on sepolia = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31
        comet = IComet(_comet); // cWETHv3 = 0x2943ac1216979aD8dB76D9147F64E61adc126e96
    }

    // function to get AI result from the Prompt contract
    function fetchAIResult(
        uint256 modelId,
        string calldata prompt
    ) external onlyOwner {
        AIResult = promptContract.getAIResult(modelId, prompt);
    }

    function generatePrompt() private returns (string memory) {
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

        ) = aaveDataProvider.getReserveData(WETH_SEPOLIA); // add asset address

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
                    totalAToken,
                    ", Total Stable Debt: ",
                    totalStableDebt,
                    ", Total Variable Debt: ",
                    totalVariableDebt,
                    ", Liquidity Rate: ",
                    liquidityRate,
                    ", Variable Borrow Rate: ",
                    variableBorrowRate,
                    ", Stable Borrow Rate: ",
                    stableBorrowRate,
                    ", Average Stable Borrow Rate: ",
                    averageStableBorrowRate,
                    "_____________",
                    ". COMPOUND: ",
                    "Total Supply: ",
                    totalSupply,
                    ", Total Borrow: ",
                    totalBorrow,
                    ", Utilization: ",
                    utilization,
                    ", Supply Rate: ",
                    supplyRate,
                    ", Borrow Rate: ",
                    borrowRate,
                    "Based on these data, please provide an estimate of the future supply rate over the next 3 days and generate prompt only with result which option is better. Please answer only with name of protocol. I mean AAVE or COMPOUND"
                )
            );
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
