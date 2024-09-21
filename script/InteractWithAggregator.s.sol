// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/AILendingAggregator.sol";
import "../src/LendingPrompt.sol";
import "../src/interfaces/IPoolDataProvider.sol";
import "../src/interfaces/IComet.sol";

/*

    TODO: 
    1. move fetching lending data from smart contract to script - it's cheaper to do it off-chain
    2. from AILendingAggregator remove logic responsible for prompting/calculating prompt 
    3. add logic for supply providing
    
*/

contract InteractWithAggregator is Script {
    address AAVE_DATA_PROVIDER = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31; // poolDataProvider on sepolia
    address COMET_DATA_PROVIDER = 0x2943ac1216979aD8dB76D9147F64E61adc126e96; // cWETHv3 sepolia

    address aggregatorAddress = 0xFB4FD631C9e4DED88526aD454e5FFBFADe55c3D7;
    address lendingPromptAddress = 0xc1A146358A8c011aC8419Aea7ba6d05966CC1774;
    address USDT_SEPOLIA = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

    IPoolDataProvider aaveDataProvider;
    IComet comet;

    function setUp() public {
        aaveDataProvider = IPoolDataProvider(AAVE_DATA_PROVIDER);
        comet = IComet(COMET_DATA_PROVIDER);
    }

    function run() external {
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

        string memory prompt = string(
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

        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        AILendingAggregator aggregator = AILendingAggregator(aggregatorAddress);
        LendingPrompt lendingPrompt = LendingPrompt(lendingPromptAddress);

        uint fee = lendingPrompt.estimateFee(11);

        console.log(prompt);

        lendingPrompt.setCallbackGasLimit(11, 5000000);

        lendingPrompt.calculateAIResult{value: 100000000000000000}(11, prompt);

        vm.warp(block.timestamp + 2 minutes);

        aggregator.checkResultAndSetPlatform(11, prompt);

        console.log("Selected platform");
        aggregator.selectedPlatform;

        vm.stopBroadcast();
    }
}
