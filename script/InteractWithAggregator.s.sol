// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/AaveSupply.sol";
import "../src/LendingPrompt.sol";
import "../src/interfaces/IPoolDataProvider.sol";
import "../src/interfaces/IComet.sol";
import {Formatter} from "../src/utils/Formatter.sol";

/*

    TODO: 
    - move to optimism sepolia | disclaimer: I'd love to, but there is no contract for comet on optimism sepolia :/
    - finish prompt | done
    1. move fetching lending data from smart contract to script - it's cheaper to do it off-chain | done
    2. from AILendingAggregator remove logic responsible for prompting/calculating prompt | 
    3. add logic for supply providing
    4. change logic for checking selected platform - getAIResult() doesn't work properly

    we need to optimize gas costs!

    POMYŚLEĆ NAD ZROBIENIEM LENDINGU POD MEMECOINY ALBO INNE RYZYKOWNE ASSETY Z UŻYCIEM ORA PROTOCOL!
    
*/

contract InteractWithAggregator is Script {
    address AAVE_DATA_PROVIDER = 0x501B4c19dd9C2e06E94dA7b6D5Ed4ddA013EC741; // poolDataProvider on op sepolia
    // address COMET_DATA_PROVIDER = 0xAec1F48e02Cfb822Be958B68C7957156EB3F0b6e; // cUSDCv3 sepolia

    address aggregatorAddress = 0xFB4FD631C9e4DED88526aD454e5FFBFADe55c3D7;
    address lendingPromptAddress = 0xe4DC4aFe063491eFB3b5930118f8937bd1c8Ef59; // op sepolia
    address USDC_OP_SEPOLIA = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;

    IPoolDataProvider aaveDataProvider;
    // IComet comet;

    using Formatter for *;

    function setUp() public {
        aaveDataProvider = IPoolDataProvider(AAVE_DATA_PROVIDER);
        // comet = IComet(COMET_DATA_PROVIDER);
    }

    function getPrompt() public view returns (string memory) {
        // ----- Aave

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

        ) = aaveDataProvider.getReserveData(USDC_OP_SEPOLIA);

        uint256 totalDebt = totalStableDebt + totalVariableDebt;

        uint256 availableLiquidity;

        if (totalAToken >= totalDebt) {
            availableLiquidity = totalAToken - totalDebt;
        } else {
            availableLiquidity = totalDebt - totalAToken;
        }

        uint256 aaveUtilization = (totalDebt * 1e18) /
            (availableLiquidity + totalDebt);

        return
            string(
                abi.encodePacked(
                    "IMPORTANT: Please answer only with one word - name of asset USDC, USDT or WETH using capital letters. I want to forecast the supply rate changes in the Aave protocol for these 3 assets based on the following data. Please provide a prediction for the next 7 days.",
                    "USDC:",
                    " Total Liquidity / Total Supply: ",
                    Formatter.formatLargeNumber(totalAToken),
                    "Utilization Rate: ",
                    Formatter.formatPercentage(aaveUtilization, 1e18),
                    ", Total Stable Debt: ",
                    Formatter.formatLargeNumber(totalStableDebt),
                    ", Total Variable Debt: ",
                    Formatter.formatLargeNumber(totalVariableDebt),
                    ", Supply Rate: ",
                    Formatter.formatPercentage(liquidityRate, 10 ** 27),
                    ", Variable Borrow Rate: ",
                    Formatter.formatPercentage(variableBorrowRate, 10 ** 27),
                    ", Stable Borrow Rate: ",
                    Formatter.formatPercentage(stableBorrowRate, 10 ** 27),
                    ", Average Stable Borrow Rate: ",
                    Formatter.formatPercentage(
                        averageStableBorrowRate,
                        10 ** 27
                    ),
                    "Based on these data, please provide an estimate of the future supply rate over the next 3 days and generate prompt only with result which option is better."
                )
            );
    }

    function firstPart(string memory prompt) public {
        LendingPrompt lendingPrompt = LendingPrompt(lendingPromptAddress);

        uint fee = lendingPrompt.estimateFee(11);

        console.log(prompt);

        lendingPrompt.setCallbackGasLimit(11, 5000000);

        lendingPrompt.calculateAIResult{value: 100000000000000000}(11, prompt);
    }

    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        string memory prompt = getPrompt();

        LendingPrompt lendingPrompt = LendingPrompt(lendingPromptAddress);

        // (
        //     address sender,
        //     uint256 modelId,
        //     bytes memory input,
        //     bytes memory output
        // ) = lendingPrompt.requests(17829);

        string memory result = lendingPrompt.getAIResult(11, prompt);

        // console.log("AI Result", string(output));
        console.log("AI RESULT 2", result);

        // firstPart(prompt);

        // vm.sleep(960000);

        // secondPart(prompt);

        vm.stopBroadcast();
    }
}
