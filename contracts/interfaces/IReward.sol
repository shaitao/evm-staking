// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IBase.sol";

interface IReward is IBase {
    function reward(address proposer, address[] calldata signed) external;

    function punish(
        address[] calldata unsigned,
        address[] calldata byztine,
        ByztineBehavior[] calldata behavior
    ) external;

    function getClaimOps() external returns (ClaimOps[] memory);

    function claim(uint256 amount) external;

    function systemClaim(address delegator, uint256 amount) external;
}
