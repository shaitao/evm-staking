// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBase.sol";
import "./interfaces/IPower.sol";

contract Power is Ownable, IBase, IPower {
    address staking;

    uint256 limit;

    constructor(address staking_, uint256 limit_) {
        staking = staking_;
        limit = limit_;
    }

    function adminSetStakingAddress(address staking_) public onlyOwner {
        staking = staking_;
    }

    function adminSetLimit(uint256 limit_) public onlyOwner {
        limit = limit_;
    }

    function descSort(ValidatorInfo[] memory validators)
        internal
        pure
        returns (ValidatorInfo[] memory)
    {
        for (uint256 i = 0; i < validators.length - 1; i++) {
            for (uint256 j = 0; j < validators.length - 1 - i; j++) {
                if (validators[j].power < validators[j + 1].power) {
                    ValidatorInfo memory temp = validators[j];
                    validators[j] = validators[j + 1];
                    validators[j + 1] = temp;
                }
            }
        }
        return validators;
    }

    function getValidatorsList() external override view returns(ValidatorInfo[] memory) {

    }
}
