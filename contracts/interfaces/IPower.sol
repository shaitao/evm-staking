// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IBase.sol";

interface IPower is IBase {
    function getValidatorsList() external view returns (ValidatorInfo[] memory);
}
