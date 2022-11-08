// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IBase.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IPower.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract System is Ownable, IBase {
    address private __self = address(this);

    // address of proxy contract
    address public proxy_contract;

    // Staking contract address
    address public stakingAddress;

    // Reword contract address
    address public rewardAddress;

    address public powerAddress;

    /**
     * @dev constructor function, for init proxy_contract.
     * @param _proxy_contract address of proxy contract.
     */
    constructor(address _proxy_contract) {
        proxy_contract = _proxy_contract;
    }

    modifier onlyProxy() {
        require(
            msg.sender == proxy_contract,
            "Only proxy can call this function"
        );
        _;
    }

    function adminSetStakingAddress(address stakingAddress_) public onlyOwner {
        stakingAddress = stakingAddress_;
    }

    function adminSetRewardAddress(address rewardAddress_) public onlyOwner {
        rewardAddress = rewardAddress_;
    }

    function adminSetPowerAddress(address powerAddress_) public onlyOwner {
        powerAddress = powerAddress_;
    }

    function trigger(
        address proposer,
        address[] memory signed,
        uint256 circulationAmount,
        address[] memory byztine,
        ByztineBehavior[] memory behavior
    ) external {
        // Return unDelegate assets
        IStaking staking = IStaking(stakingAddress);
        staking.trigger();

        // // Reward
        // Reward reward = Reward(rewardAddress);
        // reward.reward(proposer, signed, circulationAmount);

        // // Punish
        // reward.punish(signed, byztine, behavior, validatorSetMaximum);
    }

    // Get data currently claiming
    function getClaimOps() external returns (ClaimOps[] memory) {
        // ClaimOps[] memory claimOps;
        // Reward reward = Reward(rewardAddress);
        // claimOps = reward.GetClaimOps();
        // reward.clearClaimOps();
        // return claimOps;
    }

    function getValidatorsList() external returns (ValidatorInfo[] memory) {
        IPower power = IPower(powerAddress);

        return power.getValidatorsList();
    }
}
