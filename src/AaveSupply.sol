// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Pausable.sol";
import "./interfaces/IPool.sol";

/// @title AaveSupply
/// @notice This contract allows for supplying liquidity to Aave v3
/// @dev Implements basic supply functionality for WETH, USDC, and USDT
contract AaveSupply is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice The Aave v3 Pool contract
    IPool public immutable aave;

    address public constant WETH = 0x1BDD24840e119DC2602dCC587Dd182812427A5Cc;
    address public constant USDC = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
    address public constant USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;

    /// @notice Mapping to track user deposits for each asset
    /// @dev user address => asset address => amount
    mapping(address => mapping(address => uint256)) public userDeposits;

    /// @notice Emitted when liquidity is supplied to Aave
    /// @param asset The address of the supplied asset
    /// @param amount The amount of the asset supplied
    event LiquiditySupplied(address indexed asset, uint256 amount);

    /// @notice Emitted when a user withdraws assets from the contract
    /// @param user The address of the user who initiated the withdrawal
    /// @param asset The address of the asset being withdrawn
    /// @param amount The amount of the asset withdrawn
    event Withdrawal(
        address indexed user,
        address indexed asset,
        uint256 amount
    );

    /// @notice Emitted when an error occurs during supply
    /// @param reason The error message
    event SupplyError(string reason);

    /// @param _aave The address of the Aave v3 Pool contract
    constructor(address _aave) Ownable(msg.sender) {
        aave = IPool(_aave);
    }

    /// @notice Supplies liquidity to Aave v3
    /// @dev Only the contract owner can call this function
    /// @param asset The address of the asset to supply
    /// @param amount The amount of the asset to supply
    /// @param onBehalfOf The address that will receive the aTokens
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external onlyOwner {
        require(
            asset == WETH || asset == USDC || asset == USDT,
            "Unsupported asset"
        );

        // Use SafeERC20 for secure approval
        IERC20(asset).approve(address(aave), amount);

        // Call supply with error handling
        try aave.supply(asset, amount, onBehalfOf, 0) {
            userDeposits[onBehalfOf][asset] += amount;
            emit LiquiditySupplied(asset, amount);
        } catch Error(string memory reason) {
            // Handle error with message
            emit SupplyError(reason);
            revert(string(abi.encodePacked("Supply failed: ", reason)));
        } catch {
            // Handle error without message
            emit SupplyError("Unknown error");
            revert("Supply failed: Unknown error");
        }
    }

    /// @notice Withdraws assets from Aave v3
    /// @dev This function can only be called when the contract is not paused
    /// @param asset The address of the asset to withdraw
    /// @param amount The amount of the asset to withdraw
    /// @custom:throws Reverts if the asset is not supported or if the user has insufficient balance
    function withdraw(address asset, uint256 amount) external whenNotPaused {
        require(
            asset == WETH || asset == USDC || asset == USDT,
            "Unsupported asset"
        );
        require(
            userDeposits[msg.sender][asset] >= amount,
            "Insufficient balance"
        );

        aave.withdraw(asset, amount, msg.sender);
        userDeposits[msg.sender][asset] -= amount;

        emit Withdrawal(msg.sender, asset, amount);
    }

    /// @notice Pauses the contract
    /// @dev This function can only be called by the contract owner
    /// @dev When paused, certain functions like withdraw will be disabled
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev This function can only be called by the contract owner
    /// @dev When unpaused, all functions will be enabled again
    function unpause() external onlyOwner {
        _unpause();
    }

    // Additional functions like withdraw can be added here
}
