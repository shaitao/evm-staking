// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Staking.sol";
import "./interfaces/IReward.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Reward is Initializable, AccessControlEnumerableUpgradeable, IReward {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM");
    uint256 public constant RATE_DECIMAL = 10**8;

    // Staking contract address
    address public stakingAddress;

    // Punish rate
    uint256 public duplicateVotePunishRate;
    uint256 public lightClientAttackPunishRate;
    uint256 public offLinePunishRate;
    uint256 public unknownPunishRate;

    // (reward address => reward amount)
    mapping(address => uint256) public rewards;

    // Claim data
    ClaimOps[] public claimOps;

    uint256 public coinbaseAmount;

    uint256 public globalPreIssueAmount;

    event Punish(
        address punishAddress,
        ByztineBehavior behavior,
        uint256 amount
    );

    event Rewards(address rewardAddress, uint256 amount);

    event Claim(address claimAddress, uint256 amount);

    function initialize(address stakingAddress_, address systemAddress_)
        public
        initializer
    {
        duplicateVotePunishRate = 5 * 10**6;
        lightClientAttackPunishRate = 10**6;
        offLinePunishRate = 1;
        unknownPunishRate = 30 * 10**6;
        stakingAddress = stakingAddress_;

        _setupRole(SYSTEM_ROLE, systemAddress_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function adminSetDuplicateVotePunishRate(uint256 duplicateVotePunishRate_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        duplicateVotePunishRate = duplicateVotePunishRate_;
    }

    function adminSetLightClientAttackPunishRate(
        uint256 lightClientAttackPunishRate_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lightClientAttackPunishRate = lightClientAttackPunishRate_;
    }

    function adminSetOffLinePunishRate(uint256 offLinePunishRate_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        offLinePunishRate = offLinePunishRate_;
    }

    function adminSetUnknownPunishRate(uint256 unknownPunishRate_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unknownPunishRate = unknownPunishRate_;
    }

    function adminSetglobalPreIssueAmount(uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        globalPreIssueAmount = amount;
    }

    // Claim assets
    function claim(uint256 amount) external {
        address delegator = msg.sender;

        require(rewards[delegator] >= amount, "insufficient amount");
        rewards[delegator] -= amount;
        claimOps.push(ClaimOps(delegator, amount));

        emit Claim(msg.sender, amount);
    }

    function adminReward(address delegator, uint256 amount)
        public
        onlyRole(SYSTEM_ROLE)
    {
        rewards[delegator] = amount;
    }

    // Get the data currently claiming
    function getClaimOps()
        external
        override
        onlyRole(SYSTEM_ROLE)
        returns (ClaimOps[] memory)
    {
        ClaimOps[] memory ops = claimOps;

        delete claimOps;

        return ops;
    }

    // ------ Begin reward

    function reward(address proposer, address[] calldata signed)
        public
        onlyRole(SYSTEM_ROLE)
    {
        Staking sc = Staking(stakingAddress);

        uint256 totalPower = sc.totalDelegationAmount();
        uint256 validatorDelegationAmount = getPower(proposer);
        uint256 blockCountPerYear = (365 * 24 * 3600) / sc.blocktime();

        address staker = getStaker(proposer);

        uint256 delegatorsLength = sc.validatorOfDelegatorLength(proposer);
        uint256 commissionRate = getCommissionRate(proposer);

        for (uint256 i = 0; i < delegatorsLength; i++) {
            address delegator = sc.validatorOfDelegatorAt(proposer, i);

            if (delegator == staker) {
                uint256 amount = getDelegateAmountWithReward(
                    delegator,
                    proposer
                );
                uint256 returnRate = getProposerReturnRate(signed);
                uint256 r = computeReward(
                    amount,
                    validatorDelegationAmount,
                    totalPower,
                    returnRate,
                    blockCountPerYear
                );

                rewards[delegator] += r;
            } else {
                uint256 amount = getDelegateAmountWithReward(
                    delegator,
                    proposer
                );
                uint256 returnRate = getDelegatorReturnRate();
                uint256 r = computeReward(
                    amount,
                    validatorDelegationAmount,
                    totalPower,
                    returnRate,
                    blockCountPerYear
                );

                uint256 commission = (r * commissionRate) / sc.FRA_UNITS();
                rewards[staker] += commission;

                uint256 left = r - commission;
                rewards[delegator] += left;
            }
        }
    }

    function getDelegateAmountWithReward(address delegator, address validator)
        public
        view
        returns (uint256)
    {
        uint256 amount = getDelegatorAmountOfValidator(delegator, validator);
        uint256 delegatorsAmount = getDelegatorTotalAmount(delegator);

        return amount + (rewards[delegator] * amount) / delegatorsAmount;
    }

    function computeReward(
        uint256 delegateAmount,
        uint256 validatorDelegationAmount,
        uint256 totalDelegationAmount,
        uint256 returnRate,
        uint256 blockCountPerYear
    ) public pure returns (uint256) {
        // (am / total_amount) * (global_amount * ((return_rate[0] / return_rate[1]) / ((365 * 24 * 3600) / block_itv)))
        uint256 a0 = delegateAmount * totalDelegationAmount * returnRate;
        uint256 a1 = validatorDelegationAmount *
            RATE_DECIMAL *
            blockCountPerYear;

        return a0 / a1;
    }

    function getProposerReturnRate(address[] calldata signed)
        public
        view
        returns (uint256 rate)
    {
        (uint256 signedPower, uint256 totalPower) = lastVotePercent(signed);

        //                        0, 1,      2,      3,      4,      5,       6
        uint24[7] memory rule = [
            0,
            666667,
            750000,
            833333,
            916667,
            1000000,
            1000001
        ];

        for (uint256 i = 0; i <= 5; i++) {
            uint256 low = rule[i];
            uint256 high = rule[i + 1];

            if (
                signedPower * 1000000 < totalPower * high &&
                signedPower * 1000000 >= totalPower * low
            ) {
                return i * (RATE_DECIMAL / 100);
            }
        }

        // Revert
    }

    function getDelegatorReturnRate() public view returns (uint256) {
        Staking sc = Staking(stakingAddress);

        uint256 totalPower = sc.totalDelegationAmount();
        uint256 unlockAmount = globalPreIssueAmount - coinbaseAmount;

        uint256 a0 = totalPower * 536;
        uint256 a1 = unlockAmount * 10000;

        uint256 rate = 0;

        if (a0 * 100 > a1 * 268) {
            rate = (268 * RATE_DECIMAL) / 100;
        } else if (a0 * 1000 < a1 * 54) {
            rate = (54 * RATE_DECIMAL) / 1000;
        }

        return rate;
    }

    function lastVotePercent(address[] calldata signed)
        public
        view
        returns (uint256, uint256)
    {
        Staking sc = Staking(stakingAddress);
        uint256 totalPower = sc.totalDelegationAmount();
        uint256 signedPower;
        for (uint256 i = 0; i < signed.length; i++) {
            if (getStaker(signed[i]) != address(0)) {
                signedPower += getPower(signed[i]);
            }
        }
        return (signedPower, totalPower);
    }

    // ------- End reward

    // Punish validator and delegators
    function punish(
        address[] calldata unsigned,
        address[] calldata byztine,
        ByztineBehavior[] calldata behavior
    ) external override onlyRole(SYSTEM_ROLE) {
        Staking sc = Staking(stakingAddress);

        // punish byztine
        for (uint256 i = 0; i < unsigned.length; i++) {
            address validator = unsigned[i];
            uint256 delegators_length = sc.validatorOfDelegatorLength(
                validator
            );

            for (uint256 j = 0; j < delegators_length; j++) {
                address delegator = sc.validatorOfDelegatorAt(validator, j);

                uint256 amount = getDelegatorAmountOfValidator(
                    delegator,
                    validator
                );

                uint256 punishAmount = (amount * offLinePunishRate) /
                    RATE_DECIMAL;

                doPunish(validator, delegator, punishAmount);
            }
        }

        // punish byztine
        for (uint256 i = 0; i < byztine.length; i++) {
            address validator = byztine[i];

            uint256 delegators_length = sc.validatorOfDelegatorLength(
                validator
            );

            for (uint256 j = 0; j < delegators_length; j++) {
                address delegator = sc.validatorOfDelegatorAt(validator, j);

                uint256 amount = getDelegatorAmountOfValidator(
                    delegator,
                    validator
                );

                uint256 punishAmount = (amount * getPunishRate(behavior[i])) /
                    RATE_DECIMAL;

                doPunish(validator, delegator, punishAmount);
            }
        }
    }

    function doPunish(
        address validator,
        address delegator,
        uint256 punishAmount
    ) internal {
        Staking sc = Staking(stakingAddress);

        uint256 amount = sc.delegatorsBoundAmount(delegator, validator);

        if (amount < punishAmount) {
            uint256 remainingPunishAmount = punishAmount - amount;

            // Set delegate amount to zero

            if (rewards[delegator] > remainingPunishAmount) {
                rewards[delegator] -= remainingPunishAmount;
            } else {
                rewards[delegator] = 0;
            }
        }

        sc.powerDesc(validator, delegator, punishAmount);
    }

    function systemSetRewards(address delegator, uint256 amount) public onlyRole(SYSTEM_ROLE) {
        rewards[delegator] = amount;
    }

    // ..... utils

    function getPower(address validator) public view returns (uint256) {
        Staking sc = Staking(stakingAddress);

        (, , , , , uint256 power, ) = sc.validators(validator);

        return power;
    }

    function getStaker(address validator) public view returns (address) {
        Staking sc = Staking(stakingAddress);

        (, , , , address staker, , ) = sc.validators(validator);

        return staker;
    }

    function getCommissionRate(address validator)
        public
        view
        returns (uint256)
    {
        Staking sc = Staking(stakingAddress);

        (, , , uint256 rate, , , ) = sc.validators(validator);

        return rate;
    }

    function getDelegatorAmountOfValidator(address delegator, address validator)
        public
        view
        returns (uint256)
    {
        Staking sc = Staking(stakingAddress);

        uint256 unbound = sc.delegatorsUnboundAmount(delegator, validator);
        uint256 bound = sc.delegatorsBoundAmount(delegator, validator);

        return unbound + bound;
    }

    function getDelegatorTotalAmount(address delegator)
        public
        view
        returns (uint256)
    {
        Staking sc = Staking(stakingAddress);

        uint256 amount = sc.delegators(delegator);

        return amount;
    }

    function getPunishRate(ByztineBehavior byztine)
        public
        view
        returns (uint256)
    {
        if (byztine == ByztineBehavior.DuplicateVote) {
            return duplicateVotePunishRate;
        } else if (byztine == ByztineBehavior.LightClientAttack) {
            return lightClientAttackPunishRate;
        } else if (byztine == ByztineBehavior.Unknown) {
            return unknownPunishRate;
        } else {
            return 0;
        }
    }

    function getDelegators(address validator)
        public
        view
        returns (address[] memory delegators)
    {
        Staking sc = Staking(stakingAddress);

        uint256 length = sc.validatorOfDelegatorLength(validator);

        address[] memory result = new address[](length);

        for (uint256 i = 0; i <= length; i++) {
            result[i] = sc.validatorOfDelegatorAt(validator, i);
        }

        return result;
    }
}
