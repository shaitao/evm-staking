// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Staking.sol";
import "./interfaces/IReward.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Reward is Initializable, AccessControlEnumerable, IReward {
    using EnumerableSet for EnumerableSet.AddressSet;

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
        onlyRole(SYSTEM_ROLE)
        override
        returns (ClaimOps[] memory)
    {
        ClaimOps[] memory ops = claimOps;

        delete claimOps;

        return ops;
    }

    //     // Distribute rewards
    // function reward(
    //     address validator,
    //     address[] memory signed,
    //     uint256 circulationAmount
    // ) public onlyRole(SYSTEM_ROLE) {
    //     uint256[2] memory returnRateProposer;
    //     returnRateProposer = lastVotePercent(signed);
    //
    //     Staking sc = Staking(stakingAddress);
    //     uint256 totalDelegationAmount = sc.totalDelegationAmount();
    //
    //     // APY：delegator return_rate
    //     uint256[2] memory delegatorReturnRate;
    //     delegatorReturnRate = getBlockReturnRate(
    //         totalDelegationAmount,
    //         circulationAmount
    //     );
    //
    //     // 质押金额global_amount：所有用户质押金额
    //     // 质押金额total_amount（当前validator相关）：validator质押金额 + 其旗下delegator质押金额
    //     // 质押金额am：当前delegator的质押金额
    //     // return_rate 分为两种，分别在上面已经计算
    //     // 计算公式：(am / total_amount) * (global_amount * ((return_rate[0] / return_rate[1]) / ((365 * 24 * 3600) / block_itv)))
    //
    //     // 当前validator及旗下所有delegator质押金额
    //     uint256 validatorDelegationAmount = getPower(validator);
    //     // 出块周期
    //     uint256 blocktime = scpunishInfoRes.blocktime();
    //
    //     // 给proposer所有的delegator发放奖励,并返回所有delegator的总佣金
    //     uint256 totalCommission;
    //     totalCommission = rewardDelegator(
    //         validator,
    //         delegators,
    //         total_amount,
    //         global_amount,
    //         delegatorReturnRate,
    //         blockInterval
    //     );
    //
    //     // 给proposer发放奖
    //
    //     uint256 am = sc.getStakerDelegateAmount(validatorCopy);
    //     // 当前validator的staker地址
    //     address stakerAddress = sc.getStakerByValidator(validatorCopy);
    //     am +=
    //         (rewords[validatorCopy] * am) /
    //         sc.getDelegateTotalAmount(stakerAddress);
    //
    //     uint256 proposerRewards = (am / total_amount) *
    //         (global_amount *
    //             ((returnRateProposer[0] / returnRateProposer[1]) /
    //                 ((365 * 24 * 3600) / blockInterval)));
    //
    //     // proposer奖励 = 公式计算结果+旗下所有delegator的佣金
    //     rewords[validatorCopy] += proposerRewards + totalCommission;
    //
    //     emit Rewards(validatorCopy, proposerRewards);
    // }

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

    // Get last vote percent
    function lastVotePercent(address[] memory signed)
        public
        view
        returns (uint256[2] memory)
    {
        Staking sc = Staking(stakingAddress);
        uint256 totalPower = sc.totalDelegationAmount();
        uint256 signedPower;
        for (uint256 i = 0; i < signed.length; i++) {
            if (isValidator(signed[i])) {
                signedPower += getPower(signed[i]);
            }
        }
        uint256[2] memory votePercent = [signedPower, totalPower];
        return votePercent;
    }

    // Get block rewards-rate,计算APY,传入 全局质押比
    function getBlockReturnRate(
        uint256 delegationPercent0,
        uint256 delegationPercent1
    ) public pure returns (uint256[2] memory) {
        uint256 a0 = delegationPercent0 * 536;
        uint256 a1 = delegationPercent1 * 10000;
        if (a0 * 100 > a1 * 268) {
            a0 = 268;
            a1 = 100;
        } else if (a0 * 1000 < a1 * 54) {
            a0 = 54;
            a1 = 1000;
        }
        uint256[2] memory rewardsRate = [a0, a1];
        return rewardsRate;
    }

    // 给proposer所有的delegator发放奖励
    function rewardDelegator(
        address proposer,
        address[] calldata delegators,
        uint256 total_amount,
        uint256 global_amount,
        uint256[2] calldata returnRate,
        uint256 blockInterval
    ) internal returns (uint256) {
        // 佣金比例
        uint256 commissionRate = getRate(proposer);
        //
        uint256 am;
        // 佣金
        uint256 commission;
        // 按照质押比例给某个delegator发放的奖励金额
        uint256 delegatorReward;
        // 按照质押比例给某个delegator，减去佣金后实际发放的奖励金额
        uint256 delegatorRealReward;
        // 为了解决栈太深，重新赋值新变量
        address validator = proposer;
        // 所有delegator的总佣金
        uint256 totalCommission;

        for (uint256 i = 0; i < delegators.length; i++) {
            am = getDelegatorAmountOfValidator(validator, delegators[i]);
            // (d.reward * am)/d.amount(delegator所有的质押金额)
            am +=
                (rewards[delegators[i]] * am) /
                getDelegatorTotalAmount(delegators[i]);
            // 带佣金的奖励
            delegatorReward =
                (am / total_amount) *
                (global_amount *
                    ((returnRate[0] / returnRate[1]) /
                        ((365 * 24 * 3600) / blockInterval)));
            // 佣金，佣金给到这个validator的self-delegator的delegation之中
            commission = delegatorReward * commissionRate;
            totalCommission += commission;
            // 实际分配给delegator的奖励， 奖励需要按佣金比例扣除佣金,最后剩下的才是奖励
            delegatorRealReward = delegatorReward - commission;
            // 增加delegator reward金额
            rewards[delegators[i]] += delegatorRealReward;
        }
        return totalCommission;
    }

    function getPower(address validator) public view returns (uint256) {
        Staking sc = Staking(stakingAddress);

        (, , , , , uint256 power, ) = sc.validators(validator);

        return power;
    }

    function isValidator(address validator) public view returns (bool) {
        Staking sc = Staking(stakingAddress);

        (, , , , address staker, , ) = sc.validators(validator);

        return staker == address(0);
    }

    function getRate(address validator) public view returns (uint256) {
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
}
