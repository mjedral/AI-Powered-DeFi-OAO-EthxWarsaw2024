// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TokenA.sol";
import "./TokenB.sol";
import "./Prompt.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ComparisonContract is Ownable {
    TokenA public tokenA;
    TokenB public tokenB;
    Prompt public prompt;

    event MissionCompared(string tokenChosen, string mission);
    event TokenPurchased(address tokenAddress, uint256 amount);

    constructor(address _tokenAAddress, address _tokenBAddress, address _promptAddress) {
        tokenA = TokenA(_tokenAAddress);
        tokenB = TokenB(_tokenBAddress);
        prompt = Prompt(_promptAddress);
    }

    // Function to generate prompt dynamically by extracting missions from TokenA and TokenB
    function generateComparisonPrompt() public view returns (string memory) {
        string memory missionA = tokenA.mission();
        string memory missionB = tokenB.mission();

        // Create a prompt string comparing TokenA and TokenB
        return string(
            abi.encodePacked(
                "Compare TokenA mission: '", 
                missionA,
                "' with TokenB mission: '",
                missionB,
                "'. Which one has a better impact for the world? Return the token name with better impact: TokenA or TokenB."
            )
        );
    }

    // Compare missions using the AI Prompt and buy the better token
    function compareMissionsAndBuy(uint256 modelId) external payable onlyOwner {
        // Dynamically generate the comparison prompt
        string memory comparisonPrompt = generateComparisonPrompt();

        // Call the prompt contract with the dynamically generated prompt
        prompt.calculateAIResult{value: msg.value}(modelId, comparisonPrompt);
    }

    // Function to buy the token after comparison
    function buyToken(address tokenAddress, uint256 amount) internal {
        // Logic to interact with a DEX or other means to purchase the token
        emit TokenPurchased(tokenAddress, amount);
    }

    // Callback function to act based on AI result
    function finalizeDecision(string memory aiResult) external onlyOwner {
        if (keccak256(abi.encodePacked(aiResult)) == keccak256(abi.encodePacked("TokenA"))) {
            buyToken(address(tokenA), 10 ether); // Example of buying TokenA
            emit MissionCompared("TokenA", tokenA.mission());
        } else {
            buyToken(address(tokenB), 10 ether); // Example of buying TokenB
            emit MissionCompared("TokenB", tokenB.mission());
        }
    }
}
