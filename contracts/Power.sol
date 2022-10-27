// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBase.sol";
import "./interfaces/IPower.sol";
import "./Staking.sol";

contract Power is Ownable, IBase, IPower {
    address public stakingAddress;

    uint256 public limit;

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

    function getValidatorsList() external override view returns(ValidatorInfo[] memory) {
        Staking staking = Staking(stakingAddress);

        uint256 len = staking.allValidatorsLength();

        uint256 length = len;

        if (len < limit) {
            length = len;
        } else {
            length = limit;
        }

        ValidatorInfo[] memory vi = new ValidatorInfo[](length);

        uint256 minValue = staking.totalDelegationAmount();
        uint256 minIndex = 0;

        for(uint256 i = 0; i < len; i ++) {
            address validator = staking.allValidatorsAt(i);

            (bytes memory public_key, PublicKeyType ty, , , , uint256 power) = staking.validators(validator);

            if (i < limit) {
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
                    for(uint256 j = 0; j < limit; j ++) {
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
