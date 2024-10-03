// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComet {
    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint amount
    ) external virtual;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint amount
    ) external virtual;

    function totalSupply() external view returns (uint256);

    function totalBorrow() external view returns (uint256);

    // get supply rate (per second, scaled by 1e18)
    function getSupplyRate(uint256 utilization) external view returns (uint256);

    // get borrow rate (per second, scaled by 1e18)
    function getBorrowRate(uint256 utilization) external view returns (uint256);

    function getUtilization() external view returns (uint256);

    function baseToken() external view returns (address);
}
