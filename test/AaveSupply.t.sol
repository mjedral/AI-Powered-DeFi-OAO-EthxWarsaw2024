// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/AaveSupply.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract AaveSupplyTest is Test {
    AaveSupply public aaveSupply;
    address constant AAVE_POOL = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
    address constant WETH = 0x1BDD24840e119DC2602dCC587Dd182812427A5Cc;
    address constant USDC = 0x5fd84259d66Cd46123540766Be93DFE6D43130D7;
    address constant USDT = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58;

    address owner = address(1);
    address user = address(2);

    function setUp() public {
        vm.startPrank(owner);
        aaveSupply = new AaveSupply(AAVE_POOL);
        vm.stopPrank();
    }

    function testSupply() public {
        uint256 amount = 1000 * 1e6; // 1000 USDC
        deal(USDC, owner, amount);

        vm.startPrank(owner);
        IERC20(USDC).approve(address(aaveSupply), amount);
        aaveSupply.supply(USDC, amount, owner);
        vm.stopPrank();

        assertEq(
            aaveSupply.userDeposits(owner, USDC),
            amount,
            "Deposit amount should match"
        );
    }

    function testWithdraw() public {
        uint256 amount = 1000 * 1e6; // 1000 USDC
        deal(USDC, owner, amount);

        vm.startPrank(owner);
        IERC20(USDC).approve(address(aaveSupply), amount);
        aaveSupply.supply(USDC, amount, owner);
        aaveSupply.withdraw(USDC, amount);
        vm.stopPrank();

        assertEq(
            aaveSupply.userDeposits(owner, USDC),
            0,
            "Deposit should be zero after withdrawal"
        );
    }

    function testFailSupplyUnsupportedAsset() public {
        address unsupportedAsset = address(3);
        uint256 amount = 1000;

        vm.prank(owner);
        aaveSupply.supply(unsupportedAsset, amount, owner);
    }

    function testFailWithdrawInsufficientBalance() public {
        uint256 amount = 1000 * 1e6; // 1000 USDC
        deal(USDC, owner, amount);

        vm.startPrank(owner);
        IERC20(USDC).approve(address(aaveSupply), amount);
        aaveSupply.supply(USDC, amount, owner);
        aaveSupply.withdraw(USDC, amount + 1);
        vm.stopPrank();
    }
}
