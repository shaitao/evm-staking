// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IStaking {
    function stake(address validator, bytes calldata public_key, string calldata memo) external;

    function delegate(address validator) external;

    function undelegate(address validator, uint256 amount) external;

    function claim(address validator, uint256 amount) external;
}

