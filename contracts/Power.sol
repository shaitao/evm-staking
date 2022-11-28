// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBase.sol";
import "./interfaces/IPower.sol";
import "./Staking.sol";

contract Power is Ownable, IBase, IPower {
    address public stakingAddress;

    uint256 public maxLimit;

    uint256 public minLimit;

    constructor(address stakingAddress_, uint256 min, uint256 max) {
        stakingAddress = stakingAddress_;
        maxLimit = max;
        minLimit = min;
    }

    function adminSetStakingAddress(address stakingAddress_) public onlyOwner {
        stakingAddress = stakingAddress_;
    }

    function adminSetMaxLimit(uint256 limit) public onlyOwner {
        maxLimit = limit;
    }

    function adminSetMinLimit(uint256 limit) public onlyOwner {
        minLimit = limit;
    }

    function getValidatorsList()
        external
        view
        override
        returns (ValidatorInfo[] memory)
    {
        Staking staking = Staking(stakingAddress);

        uint256 len = staking.allValidatorsLength();

        if (len < minLimit) {
            return new ValidatorInfo[](0);
        }

        uint256 length = len;

        if (len < maxLimit) {
            length = len;
        } else {
            length = maxLimit;
        }

        ValidatorInfo[] memory vi = new ValidatorInfo[](length);

        uint256 minValue = staking.totalDelegationAmount();
        uint256 minIndex = 0;

        for (uint256 i = 0; i < len; i++) {
            address validator = staking.allValidatorsAt(i);

            (
                bytes memory public_key,
                PublicKeyType ty,
                ,
                ,
                ,
                uint256 power,

            ) = staking.validators(validator);

            if (i < maxLimit) {
                vi[i].public_key = public_key;
                vi[i].ty = ty;
                vi[i].addr = validator;
                vi[i].power = power;

                if (power < minValue) {
                    minValue = power;
                    minIndex = i;
                }
            } else {
                if (power > minValue) {
                    vi[minIndex].public_key = public_key;
                    vi[minIndex].ty = ty;
                    vi[minIndex].addr = validator;
                    vi[minIndex].power = power;

                    // Find min value
                    for (uint256 j = 0; j < maxLimit; j++) {
                        if (power < minValue) {
                            minValue = power;
                            minIndex = j;
                        }
                    }
                }
            }
        }

        return vi;
    }
}
