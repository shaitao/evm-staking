// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ISystem {
    struct ValidatorInfo {
        bytes public_key;
        address addr;
        uint256 power;
    }

    function getValidatorInfoList() external returns (ValidatorInfo[] memory);

    function blockTrigger(address proposer, address[] memory signed) external;

    struct ClaimOps {
        address addr;
        uint256 amount;
    }

    function getClaimOps() external returns (ClaimOps[] memory);
}

