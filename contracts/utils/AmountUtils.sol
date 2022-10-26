// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library AmountUtils {
    // Convert amount
    function convertAmount(uint256 amount, uint8 decimal)
        public
        pure
        returns (uint256)
    {
        uint256 pow = 10**decimal;
        uint256 res = amount / pow;
        return res * pow;
    }

    function dropAmount(uint256 amount, uint8 decimal)
        public
        pure
        returns (uint256)
    {
        uint256 pow = 10**decimal;
        uint256 res = amount / pow;
        return res;
    }
}
