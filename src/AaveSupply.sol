// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LendingPrompt.sol";
import "./interfaces/IPoolDataProvider.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IComet.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AaveSupply {
    //check slots order
    string public AIResult;
    address public owner;
    LendingPrompt public promptContract;
    IPool public aave;
    IComet public comet;

    event LiquiditySupplied(address asset, uint256 amount);
    event Withdraw(address asset, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _promptContractAddress, address _aave, address _comet) {
        owner = msg.sender;
        promptContract = LendingPrompt(_promptContractAddress);
        aave = IPool(_aave); // 0x501B4c19dd9C2e06E94dA7b6D5Ed4ddA013EC741 poolDataProvider on op sepolia
    }

    /// @notice Supply liquidity to AAVE platform
    /// @param asset The address of the asset being supplied (e.g., USDC)
    /// @param amount The amount of the asset being supplied
    /// @param onBehalfOf The address that will receive the aTokens
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external onlyOwner {
        // Approve the Aave pool to spend the tokens
        IERC20(asset).approve(address(aave), amount);

        // Call the `supply` function from Aave protocol (usually from IPool)
        aave.supply(asset, amount, onBehalfOf, 0); // `0` is the referral code

        // Emit an event
        emit LiquiditySupplied(asset, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external onlyOwner {
        aave.withdraw(asset, amount, to);
        emit Withdraw(asset, amount);
    }

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return aave.getUserAccountData(user);
    }
}
