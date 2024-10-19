// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AaveSupply.sol";
import "../src/LendingPrompt.sol";

contract DeployAILendingAggregator is Script {
    function run() external {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        // Adresy contractow na Ethereum Sepolia
        address aaveDataProvider = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31;
        address cometAddress = 0x2943ac1216979aD8dB76D9147F64E61adc126e96;
        address promptContract = 0xc1A146358A8c011aC8419Aea7ba6d05966CC1774;

        // Deploy kontraktu AILendingAggregator
        AaveSupply aaveSupply = new AaveSupply(aaveDataProvider);

        console.log("AaveSupply contract deployed at:", address(aaveSupply));

        vm.stopBroadcast();
    }
}
