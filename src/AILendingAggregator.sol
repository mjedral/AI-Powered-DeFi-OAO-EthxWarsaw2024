// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LendingPrompt.sol";
import "./interfaces/IPoolDataProvider.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IComet.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AILendingAggregator {
    //check slots order
    string public AIResult;
    address public owner;
    LendingPrompt public promptContract;
    IPool public aave;
    IComet public comet;

    event LiquiditySupplied(string protocol, address asset, uint256 amount);
    event Withdraw(string protocol, address asset, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _promptContractAddress, address _aave, address _comet) {
        owner = msg.sender;
        promptContract = LendingPrompt(_promptContractAddress);
        aave = IPool(_aave); // poolDataProvider on sepolia = 0x3e9708d80f7B3e43118013075F7e95CE3AB31F31
        comet = IComet(_comet); // cWETHv3 = 0x2943ac1216979aD8dB76D9147F64E61adc126e96
    }

    /// @notice Supply liquidity to AAVE platform
    /// @param asset The address of the asset being supplied (e.g., USDC)
    /// @param amount The amount of the asset being supplied
    /// @param onBehalfOf The address that will receive the aTokens
    function supplyToAave(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external onlyOwner {
        // Approve the Aave pool to spend the tokens
        IERC20(asset).approve(address(aave), amount);

        // Call the `supply` function from Aave protocol (usually from IPool)
        aave.supply(asset, amount, onBehalfOf, 0); // `0` is the referral code

        // Emit an event
        emit LiquiditySupplied("AAVE", asset, amount);
    }

    /// @notice Supply liquidity to COMPOUND platform
    /// @param asset The address of the asset being supplied (e.g., USDC)
    /// @param amount The amount of the asset being supplied
    function supplyToCompound(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external onlyOwner {
        // Approve Compound Comet to spend the tokens
        IERC20(asset).approve(address(comet), amount);

        // Supply to Compound using `supply` function in Comet
        comet.supplyFrom(from, dst, asset, amount); // check msg.sender vs msg.sender() + corectness of address(comet)

        // Emit an event
        emit LiquiditySupplied("COMPOUND", asset, amount);
    }

    function checkResultAndSetPlatform(
        uint256 modelId,
        string calldata prompt
    ) external onlyOwner {
        string memory aiResult = promptContract.getAIResult(modelId, prompt);
        require(bytes(aiResult).length > 0, "Result is not ready yet");
        AIResult = aiResult;
    }

    /*
    
       HERE WILL BE LOGIC RESPONSIBLE FOR ADDING SUPPLY TO LENDING PLATFORMS AFTER GETTING RESULT FROM AI MODEL

    */
}
