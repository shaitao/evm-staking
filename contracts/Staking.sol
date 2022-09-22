// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Power.sol";
import "./utils/utils.sol";
import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Staking is Initializable, AccessControlEnumerable, IStaking {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AmountUtils for uint256;

    /// --- contract config for Staking ---

    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD");

    address public powerAddress;

    /// --- End contract config for staking ---

    /// --- Configure

    // Mininum staking value; Default: 10000 FRA
    uint256 public stakeMininum;

    // Mininum delegate value; Default 1 unit
    uint256 public delegateMininum;

    // rate of power. decimal is 6
    uint256 public powerRateMaximum;

    // blocktime; Default 16.
    uint256 public blocktime;

    // unbound block count; Default 21 day. (21 * 24 * 60 * 60 / 16)
    uint256 public unboundBlock;

    /// --- End Configure

    /// --- State of validator

    enum PublicKeyType {
        Unknown,
        Secp256k1,
        Ed25519
    }

    struct Validator {
        // Public key of validator
        bytes public_key;
        // Public key type
        PublicKeyType ty;
        // memo of validator
        string memo;
        // rate of validator, decimal is 6
        uint256 rate;
        // address of staker
        address staker;
    }

    // address of tendermint => validator
    mapping(address => Validator) public validators;

    // Addresses of all validators
    EnumerableSet.AddressSet private allValidators;

    /// --- End State of validator

    /// --- State of delegator

    /// delegator => validator => amount
    mapping(address => mapping(address => uint256)) public delegatorsAmount;



    /// --- End state of delegator

    /*
     * All delegators of a validator
     * (validator address => delegator address set).
     */
    mapping(address => EnumerableSet.AddressSet) private delegatorsOfValidators;

    /*
     * Delegate info
     * (delegator => (validator => amount)).
     */
    // (delegator => total delegate amount).
    mapping(address => uint256) public delegateInfo;

    // Total amount of delegate
    uint256 public delegateTotal;

    struct UndelegationRecord {
        address validator;
        address payable receiver;
        uint256 amount;
        uint256 height;
    }

    // UnDelegation records
    UndelegationRecord[] public undelegationRecords;
    /*
     * 在21天等待期的记录
     * (undelegated address => mapping(validator address => amount))
     */
    mapping(address => mapping(address => uint256)) public unDelegatingRecords;

    event Stake(
        bytes public_key,
        address staker,
        uint256 amount,
        string memo,
        uint256 rate
    );
    event Delegation(address validator, address receiver, uint256 amount);
    event Undelegation(address validator, address receiver, uint256 amount);

    function initialize(
        address system_,
        address powerAddress_,
        uint256 stakeMinimum_,
        uint256 delegateMinimum_,
        uint256 powerRateMaximum_,
        uint256 blockInterval_
    ) public initializer {
        powerAddress = powerAddress_;
        stakeMinimum = stakeMinimum_;
        delegateMinimum = delegateMinimum_;
        powerRateMaximum = powerRateMaximum_;
        blockInterval = blockInterval_;
        heightDifference = (86400 / blockInterval) * 21;

        _setupRole(SYSTEM_ROLE, system_);
    }

    function adminSetPowerAddress(address powerAddress_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        powerAddress = powerAddress_;
    }

    function adminSetStakeMinimum(uint256 stakeMinimum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakeMinimum = stakeMinimum_;
    }

    function adminSetDelegateMinimum(uint256 delegateMinimum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delegateMinimum = delegateMinimum_;
    }

    function adminSetPowerRateMaximum(uint256 powerRateMaximum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        powerRateMaximum = powerRateMaximum_;
    }

//     function adminSetBlockInterval(uint256 blockInterval_)
    //     public
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     blockInterval = blockInterval_;
    //     heightDifference = (86400 / blockInterval) * 21;
    // }
    //
    // function _addDelegateAmountAndPower(
    //     address validator,
    //     address delegator,
    //     uint256 amount
    // ) internal {
    //     delegators[delegator][validator] += amount;
    //     delegateInfo[delegator] += amount;
    //     delegateTotal += amount;
    //
    //     Power powerContract = Power(powerAddress);
    //     powerContract.addPower(validator, amount);
    // }
    //
    // function _descDelegateAmountAndPower(
    //     address validator,
    //     address delegator,
    //     uint256 amount
    // ) internal {
    //     delegators[delegator][validator] -= amount;
    //     delegateInfo[delegator] -= amount;
    //     delegateTotal -= amount;
    //
    //     Power powerContract = Power(powerAddress);
    //     powerContract.descPower(validator, amount);
    // }
    //
    // // Stake
    // function stake(
    //     address validator,
    //     bytes calldata public_key,
    //     string calldata memo,
    //     uint256 rate
    // ) external payable override {
    //     // Check whether the validator was staked
    //     require(validators[validator].staker == address(0), "already staked");
    //
    //     uint256 amount = msg.value.dropAmount(12);
    //
    //     require(amount * (10**12) == msg.value, "lower 12 must be 0.");
    //
    //     require(amount >= stakeMinimum, "amount too small");
    //
    //     Validator storage v = validators[validator];
    //     v.public_key = public_key;
    //     v.memo = memo;
    //     v.rate = rate;
    //     v.staker = msg.sender;
    //
    //     _addDelegateAmountAndPower(validator, msg.sender, amount);
    //
    //     allValidators.add(validator);
    //
    //     emit Stake(public_key, msg.sender, msg.value, memo, rate);
    // }
    //
    // // Delegate assets
    // function delegate(address validator) external payable override {
    //     // Check whether the validator is a stacker
    //     Validator storage v = validators[validator];
    //     require(v.staker != address(0), "invalid validator");
    //
    //     uint256 amount = msg.value.dropAmount(12);
    //
    //     Power powerContract = Power(powerAddress);
    //
    //     require(amount >= delegateMinimum, "amount is too small");
    //
    //     require(amount * (10**12) == msg.value, "lower 12 must be 0.");
    //
    //     uint256 maxAmount = ((powerContract.powerTotal() + amount) /
    //         powerRateMaximum) * (10**6);
    //
    //     require(amount < maxAmount, "amount is too large");
    //
    //     _addDelegateAmountAndPower(validator, msg.sender, amount);
    //
    //     delegatorsOfValidators[validator].add(msg.sender);
    //
    //     emit Delegation(validator, address(this), amount);
    // }
    //
    // // UnDelegate assets
    // function undelegate(address validator, uint256 amount) external override {
    //     Validator storage v = validators[validator];
    //     require(v.staker != address(0), "invalid validator");
    //
    //     require(amount > 0, "amount must be greater than 0");
    //
    //     uint256 delegateAmount = delegators[msg.sender][validator];
    //
    //     require(delegateAmount > amount, "amount too large");
    //
    //     _descDelegateAmountAndPower(validator, msg.sender, amount);
    //
    //     // Push record
    //     undelegationRecords.push(
    //         UndelegationRecord(
    //             validator,
    //             payable(msg.sender),
    //             amount,
    //             block.number
    //         )
    //     );
    // }
    //
    // // Return unDelegate assets
    // function trigger() public onlyRole(SYSTEM_ROLE) {
    //     uint256 blockNo = block.number;
    //     Power powerContract = Power(powerAddress);
    //     for (uint256 i; i < undelegationRecords.length; i++) {
    //         if ((blockNo - undelegationRecords[i].height) >= heightDifference) {
    //             Address.sendValue(
    //                 undelegationRecords[i].receiver,
    //                 undelegationRecords[i].amount
    //             );
    //
    //             // Decrease amount and power
    //             // 减去质押amount，减去power，在undelegate时候已经判断过金额，这里不必判断会减为负数,以及后12位
    //
    //             // Update delegate amount and decrease power of validator
    //             _descDelegateAmountAndPower(
    //                 undelegationRecords[i].validator,
    //                 undelegationRecords[i].receiver,
    //                 undelegationRecords[i].amount
    //             );
    //
    //             // Update the amount of 21 day waiting period
    //             undelegationRecords[undelegationRecords[i].receiver][
    //                 undelegationRecords[i].validator
    //             ] -= undelegationRecords[i].amount;
    //
    //             // Remove the delegator of validator, if the delegate amount is 0
    //             // 当某一质押者在某节点质押金额变为0，就从该节点下质押者地址集合移除质押者账户地址
    //             if (
    //                 delegators[undelegationRecords[i].receiver][
    //                     undelegationRecords[i].validator
    //                 ] == 0
    //             ) {
    //                 delegatorsOfValidators[undelegationRecords[i].validator]
    //                     .remove(undelegationRecords[i].receiver);
    //             }
    //
    //             // Removed from the validator set If the power of validator was reduced to 0
    //             if (
    //                 powerContract.getPower(undelegationRecords[i].validator) ==
    //                 0
    //             ) {
    //                 allValidators.remove(undelegationRecords[i].validator);
    //             }
    //
    //             // Event
    //             emit Undelegation(
    //                 undelegationRecords[i].validator,
    //                 undelegationRecords[i].receiver,
    //                 undelegationRecords[i].amount
    //             );
    //         }
    //     }
    // }
    //
    // // Update validator
    // // 该操作只能有 staker来操作
    // function updateValidator(
    //     address validator,
    //     string calldata memo,
    //     uint256 rate
    // ) public {
    //     // Check whether the validator is a stacker
    //     Validator storage v = validators[validator];
    //     require(
    //         (v.staker != address(0)) && (v.staker == msg.sender),
    //         "invalid staker"
    //     );
    //
    //     validators[validator].memo = memo;
    //     validators[validator].rate = rate;
    // }
    //
    // // Get all validator's addresses
    // function getAllValidators() public view returns (address[] memory) {
    //     return allValidators.values();
    // }
    //
    // // Get all delegators of a validator
    // function getDelegatorsByValidator(address validator)
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     return delegatorsOfValidators[validator].values();
    // }
    //
    // // Get staker address of a validator
    // function getStakerByValidator(address validator)
    //     public
    //     view
    //     returns (address)
    // {
    //     return validators[validator].staker;
    // }
    //
    // // Check whether an validator-account is a Legal validator
    // function isValidator(address validator) public view returns (bool) {
    //     return allValidators.contains(validator);
    // }
    //
    // // Get delegate amount
    // function getDelegateAmount(address validator, address delegator)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return delegators[validator][delegator];
    // }
    //
    // // Get staker delegate amount
    // function getStakerDelegateAmount(address validator)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     return delegators[validator][validators[validator].staker];
    // }
    //
    // // Get validator rate
    // function getValidatorRate(address validator) public view returns (uint256) {
    //     return validators[validator].rate;
    // }
    //
    // // Get total delegate amount of a delegator
    // function getDelegateTotalAmount(address delegator)
    //     public
    //     view
    //     onlyRole(REWARD_ROLE)
    //     returns (uint256)
    // {
    //     return delegateInfo[delegator];
    // }
    //
    // // Check the last 12 digits of the amount before use
    // function descDelegateAmountAndPower(
    //     address validator,
    //     address delegator,
    //     uint256 amount
    // ) public onlyRole(SYSTEM_ROLE) {
    //     require(
    //         delegators[delegator][validator] >= amount,
    //         "insufficient amount"
    //     );
    //
    //     // Update delegator's delegate-amount of validator
    //     delegators[delegator][validator] -= amount;
    //     // Decrease total delegate-amount of delegator
    //     delegateInfo[delegator] -= amount;
    //     // Decrease total delegate-amount
    //     delegateTotal -= amount;
    //
    //     // Decrease power
    //     uint256 power = amount;
    //     Power powerContract = Power(powerAddress);
    //     powerContract.descPower(validator, power);
    // }
}
