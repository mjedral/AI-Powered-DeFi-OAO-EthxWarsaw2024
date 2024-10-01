// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

library AaveV3RateUtils {
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
}
