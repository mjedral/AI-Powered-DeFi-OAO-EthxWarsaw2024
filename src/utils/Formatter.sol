// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

library Formatter {
    // Formatowanie liczby do postaci procentowej z dwoma miejscami po przecinku
    function formatPercentage(
        uint256 value,
        uint256 scale
    ) internal pure returns (string memory) {
        uint256 percentageWithDecimals = (value * 10000) / scale;
        uint256 integerPart = percentageWithDecimals / 100;
        uint256 fractionalPart = percentageWithDecimals % 100;

        return
            string(
                abi.encodePacked(
                    Strings.toString(integerPart),
                    ".",
                    fractionalPart < 10 ? "0" : "",
                    Strings.toString(fractionalPart),
                    "%"
                )
            );
    }

    // Formatowanie dużej liczby z separatorami tysięcy
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
}
