// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../src/AILendingAggregator.sol";
import "../src/LendingPrompt.sol";
import "../src/interfaces/IPoolDataProvider.sol";
import "../src/interfaces/IComet.sol";

/*

    TODO: 
    - move to optimism sepolia
    - finish prompt
    1. move fetching lending data from smart contract to script - it's cheaper to do it off-chain
    2. from AILendingAggregator remove logic responsible for prompting/calculating prompt 
    3. add logic for supply providing

    we need to optimize gas costs!
    
*/

contract InteractWithAggregator is Script {
    address AAVE_DATA_PROVIDER = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31; // poolDataProvider on sepolia
    address COMET_DATA_PROVIDER = 0x2943ac1216979aD8dB76D9147F64E61adc126e96; // cWETHv3 sepolia

    address aggregatorAddress = 0xFB4FD631C9e4DED88526aD454e5FFBFADe55c3D7;
    address lendingPromptAddress = 0xc1A146358A8c011aC8419Aea7ba6d05966CC1774;
    address USDT_SEPOLIA = 0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0;

    IPoolDataProvider aaveDataProvider;
    IComet comet;

    function formatPercentage(
        uint256 value,
        uint256 scale
    ) internal pure returns (string memory) {
        uint256 percentage = (value * 100) / scale;
        return string(abi.encodePacked(Strings.toString(percentage), "%"));
    }

    function formatLargeNumber(
        uint256 value
    ) internal pure returns (string memory) {
        string memory numberStr = Strings.toString(value);
        bytes memory numberBytes = bytes(numberStr);
        string memory formattedNumber = "";
        uint256 length = numberBytes.length;

        for (uint256 i = 0; i < length; i++) {
            if (i > 0 && (length - i) % 3 == 0) {
                formattedNumber = string(
                    abi.encodePacked(formattedNumber, ",")
                );
            }
            formattedNumber = string(
                abi.encodePacked(formattedNumber, numberBytes[i])
            );
        }
        return formattedNumber;
    }

    function padLeft(
        string memory str,
        uint256 length,
        string memory padChar
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length >= length) return str;

        bytes memory padBytes = bytes(padChar);
        bytes memory result = new bytes(length);

        for (uint256 i = 0; i < length - strBytes.length; i++) {
            result[i] = padBytes[0];
        }
        for (uint256 i = 0; i < strBytes.length; i++) {
            result[length - strBytes.length + i] = strBytes[i];
        }

        return string(result);
    }

    function calculateAPY(
        uint256 ratePerSecond
    ) internal pure returns (uint256) {
        uint256 ratePerYear = ratePerSecond * 365 days;
        return ((1 + ratePerYear / 1e27) ** (1e27 / 1e18) - 1e27) * 1e10;
    }

    function getSupplyAPY(uint256 supplyRate) public view returns (uint256) {
        return calculateAPY(supplyRate);
    }

    function getFormattedSupplyAPY(
        uint256 apy
    ) public view returns (string memory) {
        return formatAPY(apy);
    }

    function formatAPY(uint256 apy) internal pure returns (string memory) {
        uint256 integerPart = apy / 1e18;
        uint256 fractionalPart = (apy % 1e18) / 1e14; // 4 decimal places
        return
            string(
                abi.encodePacked(
                    Strings.toString(integerPart),
                    ".",
                    padLeft(Strings.toString(fractionalPart), 4, "0"),
                    "%"
                )
            );
    }

    function setUp() public {
        aaveDataProvider = IPoolDataProvider(AAVE_DATA_PROVIDER);
        comet = IComet(COMET_DATA_PROVIDER);
    }

    function getPrompt() public view returns (string memory) {
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

        ) = aaveDataProvider.getReserveData(
                0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8 // USDC
            ); // add asset address

        uint256 aTokenTotalSupply = aaveDataProvider.getATokenTotalSupply(
            0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
        );

        uint256 totalDebt = totalStableDebt + totalVariableDebt;
        uint256 totalDeposits = IERC20(
            0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8
        ).balanceOf(address(aaveDataProvider)) + totalDebt;

        uint256 aaveUtilization = (totalDebt * 1e18) / totalDeposits;

        string memory formattedSupplyAPY = getFormattedSupplyAPY(
            getSupplyAPY(liquidityRate)
        );

        // check if compound functions gives correct outputs

        uint256 totalSupply = comet.totalSupply();
        uint256 totalBorrow = comet.totalBorrow();
        uint256 utilization = comet.getUtilization();
        uint256 supplyRate = comet.getSupplyRate(utilization);
        uint256 borrowRate = comet.getBorrowRate(utilization);

        // TODO: add indicators for AAVE and Compound like utilization or supply rate, because now is unequally

        return
            string(
                abi.encodePacked(
                    "I want to forecast the supply rate changes in the Aave and Compound protocol based on the following data. Please provide a prediction for the next 3 days. In both case we compare indicators for USDT token",
                    "AAVE:",
                    " Total Liquidity: ",
                    "AAVE:",
                    " Total Liquidity: ",
                    formatLargeNumber(totalAToken),
                    " Total Supply: ",
                    formatLargeNumber(aTokenTotalSupply),
                    " Supply APY ",
                    formattedSupplyAPY,
                    "Utilization Rate: ",
                    Strings.toString(aaveUtilization), // add proper formatting
                    ", Total Stable Debt: ",
                    formatLargeNumber(totalStableDebt),
                    ", Total Variable Debt: ",
                    formatLargeNumber(totalVariableDebt),
                    ", Liquidity Rate: ",
                    formatPercentage(liquidityRate, 10 ** 27),
                    ", Variable Borrow Rate: ",
                    formatPercentage(variableBorrowRate, 10 ** 27),
                    ", Stable Borrow Rate: ",
                    formatPercentage(stableBorrowRate, 10 ** 27),
                    ", Average Stable Borrow Rate: ",
                    formatPercentage(averageStableBorrowRate, 10 ** 27),
                    "_____________",
                    "COMPOUND: ",
                    "Total Supply: ",
                    formatLargeNumber(totalSupply),
                    ", Total Borrow: ",
                    formatLargeNumber(totalBorrow),
                    ", Utilization: ",
                    formatPercentage(utilization, 10 ** 18),
                    ", Supply Rate: ",
                    formatPercentage(supplyRate, 10 ** 18),
                    ", Borrow Rate: ",
                    formatPercentage(borrowRate, 10 ** 18),
                    "Based on these data, please provide an estimate of the future supply rate over the next 3 days and generate prompt only with result which option is better. Please answer only with name of protocol. I mean AAVE or COMPOUND"
                )
            );
    }

    function firstPart(string memory prompt) public {
        LendingPrompt lendingPrompt = LendingPrompt(lendingPromptAddress);

        uint fee = lendingPrompt.estimateFee(11);

        console.log(prompt);

        lendingPrompt.setCallbackGasLimit(11, 5000000);

        lendingPrompt.calculateAIResult{value: fee}(11, prompt);
    }

    // function secondPart(string memory prompt) public {
    //     AILendingAggregator aggregator = AILendingAggregator(aggregatorAddress);

    //     aggregator.checkResultAndSetPlatform(11, prompt);

    //     console.log("Selected platform");
    //     aggregator.selectedPlatform;
    // }

    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        string memory prompt = getPrompt();

        // LendingPrompt lendingPrompt = LendingPrompt(lendingPromptAddress);

        // (
        //     address sender,
        //     uint256 modelId,
        //     bytes memory input,
        //     bytes memory output
        // ) = lendingPrompt.requests(17263);

        // string memory result = lendingPrompt.getAIResult(11, prompt);

        // console.log("AI Result", string(output));
        // console.log("AI RESULT 2", result);

        firstPart(prompt);

        // vm.sleep(960000);

        // secondPart(prompt);

        vm.stopBroadcast();
    }
}
