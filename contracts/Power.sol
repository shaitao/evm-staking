// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBase.sol";
import "./interfaces/IPower.sol";
import "./Staking.sol";

contract Power is Ownable, IBase, IPower {
    address stakingAddress;

    uint256 limit;

    constructor(address stakingAddress_, uint256 limit_) {
        stakingAddress = stakingAddress_;
        limit = limit_;
    }

    function adminSetStakingAddress(address stakingAddress_) public onlyOwner {
        stakingAddress = stakingAddress_;
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
        Staking staking = Staking(stakingAddress);

        uint256 len = staking.allValidatorsLength();

        ValidatorInfo[] memory vi = new ValidatorInfo[](len);

        for(uint256 i = 0; i <= len; i ++) {
            address validator = staking.allValidatorsAt(i);

            (bytes memory public_key, PublicKeyType ty, , , , uint256 power) = staking.validators(validator);

            vi[i].public_key = public_key;
            vi[i].ty = ty;
            vi[i].addr = validator;
            vi[i].power = power;
        }

        return descSort(vi);
    }
}
