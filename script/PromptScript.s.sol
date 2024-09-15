// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LendingPrompt} from "../src/LendingPrompt.sol";
import {IAIOracle} from "../OAO/contracts/interfaces/IAIOracle.sol";

contract PromptScript is Script {
    address OAO_PROXY;

    function setUp() public {
        OAO_PROXY = 0x0A0f4321214BB6C7811dD8a71cF587bdaF03f0A0;
    }

    function run() public {
        uint privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        LendingPrompt lendingPrompt = new LendingPrompt(IAIOracle(OAO_PROXY));
        console.log("LendingPrompt deployed at: ", address(lendingPrompt));
        vm.stopBroadcast();
    }
}
