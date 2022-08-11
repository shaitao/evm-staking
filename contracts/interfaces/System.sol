// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface System {
    struct ValidatorInfo {
        bytes public_key;
        address addr;
        uint256 power;
    }

    function getValidatorInfoList() external returns (ValidatorInfo[] memory);
}

