// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "./Power.sol";
import "./utils/utils.sol";
import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Staking is Initializable, AccessControlEnumerable, IStaking {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using AmountUtils for uint256;
    using SafeMath for uint256;

    /// --- contract config for Staking ---

    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM");
    uint256 public constant FRA_UNITS = 10 ** 6;

    /// --- End contract config for staking ---

    /// --- Configure

    // Mininum staking value; Default: 10000 FRA
    uint256 public stakeMininum = 10000 * FRA_UNITS;

    function adminSetStakeMinimum(uint256 stakeMininum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakeMininum = stakeMininum_;
    }

    // Mininum delegate value; Default 1 unit
    uint256 public delegateMininum = 1;

    function adminSetDelegateMinimum(uint256 delegateMininum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delegateMininum = delegateMininum_;
    }

    // rate of power. decimal is 6
    uint256 public powerRateMaximum = 200000;

    function adminSetPowerRateMaximum(uint256 powerRateMaximum_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        powerRateMaximum = powerRateMaximum_;
    }

    // blocktime; Default 16.
    uint256 public blocktime = 16;

    function adminSetBlocktime(uint256 blocktime_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        blocktime = blocktime_;
    }

    // unbound block count; Default 21 day. (21 * 24 * 60 * 60 / 16)
    uint256 public unboundBlock = 21 * 24 * 60 * 60 / 16;

    function adminUnboundBlock(uint256 unboundBlock_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unboundBlock = unboundBlock_;
    }

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
        uint256 power;
    }

    // address of tendermint => validator
    mapping(address => Validator) public validators;

    // Addresses of all validators
    EnumerableSet.AddressSet private allValidators;

    function allValidatorsLength() public view returns(uint256) {
        return allValidators.length();
    }

    function allValidatorsAt(uint256 idx) public view returns(address) {
        return allValidators.at(idx);
    }

    function allValidatorsContains(address value) public view returns(bool) {
        return allValidators.contains(value);
    }

    /// --- End State of validator

    /// --- State of delegator

    struct Delegator {
        mapping(address => uint256) boundAmount;
        mapping(address => uint256) unboundAmount;
        uint256 amount;
    }

    mapping(address => Delegator) public delegators;

    mapping(address => EnumerableSet.AddressSet) private delegatorOfValidator;

    mapping(address => EnumerableSet.AddressSet) private validatorOfDelegator;

    EnumerableSet.AddressSet private allDelegators;

    function _addDelegator(address delegator, address validator, uint256 amount) private {
        Delegator storage d = delegators[delegator];

        uint256 boundAmount = d.boundAmount[validator];
        d.boundAmount[validator] = boundAmount.add(amount);

        d.amount = d.amount.add(amount);

        Validator storage v = validators[validator];
        v.power = v.power.add(amount);

        delegatorOfValidator[delegator].add(validator);
        validatorOfDelegator[validator].add(delegator);

        totalDelegationAmount = totalDelegationAmount.add(amount);
    }

    function _delDelegator(address delegator, address validator, uint256 amount) private {
        Delegator storage d = delegators[delegator];

        uint256 boundAmount = d.boundAmount[validator];
        d.boundAmount[validator] = boundAmount.sub(amount);

        uint256 unboundAmount = d.unboundAmount[validator];
        d.unboundAmount[validator] = unboundAmount.add(amount);
    }

    function _realDelDelegator(address delegator, address validator, uint256 amount) private {
        Delegator storage d = delegators[delegator];

        uint256 unboundAmount = d.unboundAmount[validator];
        d.unboundAmount[validator] = unboundAmount.sub(amount);

        if(d.unboundAmount[validator] + d.boundAmount[validator] == 0) {
            delegatorOfValidator[delegator].remove(validator);
            validatorOfDelegator[validator].remove(delegator);
        }

        d.amount = d.amount.sub(amount);

        Validator storage v = validators[validator];
        v.power = v.power.sub(amount);

        totalDelegationAmount = totalDelegationAmount.sub(amount);
    }

    function delegatorOfValidatorLength(address delegator) public view returns(uint256) {
        return delegatorOfValidator[delegator].length();
    }

    function delegatorOfValidatorAt(address delegator, uint256 idx) public view returns(address) {
        return delegatorOfValidator[delegator].at(idx);
    }

    function delegatorOfValidatorContains(address delegator, address value) public view returns(bool) {
        return delegatorOfValidator[delegator].contains(value);
    }

    function validatorOfDelegatorLength(address validator) public view returns(uint256) {
        return validatorOfDelegator[validator].length();
    }

    function validatorOfDelegatorAt(address validator, uint256 idx) public view returns(address) {
        return validatorOfDelegator[validator].at(idx);
    }

    function validatorOfDelegatorContains(address validator, address value) public view returns(bool) {
        return validatorOfDelegator[validator].contains(value);
    }

    function allDelegatorsLength() public view returns(uint256) {
        return allDelegators.length();
    }

    function allDelegatorsAt(uint256 idx) public view returns(address) {
        return allDelegators.at(idx);
    }

    function allDelegatorsContains(address value) public view returns(bool) {
        return allDelegators.contains(value);
    }

    /// --- End state of delegator

    /// --- State of total staking

    // Total amount of delegate
    uint256 public totalDelegationAmount;

    function maxDelegationAmountBasedOnTotalAmount() public view returns(uint256) {
        return totalDelegationAmount * powerRateMaximum / FRA_UNITS;
    }

    /// --- End state of total staking

    /// --- State of undelegation
    struct UndelegationRecord {
        address validator;
        address payable delegator;
        uint256 amount;
        uint256 height;
    }

    // UnDelegation records
    UndelegationRecord[] public undelegationRecords;

    /// --- End state of undelegation

    event Stake(
        bytes public_key,
        address staker,
        uint256 amount,
        string memo,
        uint256 rate
    );
    event Delegation(address validator, address delegator, uint256 amount);
    event Undelegation(address validator, address receiver, uint256 amount);

    function initialize(
        address system_
    ) public initializer {
        _setupRole(SYSTEM_ROLE, system_);
    }

    // Stake
    function stake(
        address validator,
        bytes calldata public_key,
        string calldata memo,
        uint256 rate
    ) external payable override {
        // Check whether the validator was staked
        require(validators[validator].staker == address(0), "already staked");
    
        uint256 amount = msg.value.dropAmount(12);
    
        require(amount * (10**12) == msg.value, "lower 12 must be 0.");
    
        require(amount >= stakeMininum, "amount too small");

        uint256 maxDelegateAmount = maxDelegationAmountBasedOnTotalAmount();

        require(amount <= maxDelegateAmount, "amount too large");

        Validator storage v = validators[validator];
        v.public_key = public_key;
        v.memo = memo;
        v.rate = rate;
        v.staker = msg.sender;

        allValidators.add(validator);
    
        _addDelegator(msg.sender, validator, amount);

        emit Stake(public_key, msg.sender, msg.value, memo, rate);
    }
    
    // Delegate assets
    function delegate(address validator) external payable override {
        Validator storage v = validators[validator];
        require(v.staker != address(0), "invalid validator");
    
        uint256 amount = msg.value.dropAmount(12);

        require(amount * (10**12) == msg.value, "lower 12 must be 0.");

        require(amount >= delegateMininum, "amount is too small");

        uint256 maxDelegateAmount = maxDelegationAmountBasedOnTotalAmount();

        require(amount <= maxDelegateAmount, "amount too large");

        _addDelegator(msg.sender, validator, msg.value);

        emit Delegation(validator, msg.sender, amount);
    }

    // UnDelegate assets
    function undelegate(address validator, uint256 amount) external override {
        Validator storage v = validators[validator];
        require(v.staker != address(0), "invalid validator");

        require(amount > 0, "amount must be greater than 0");

        Delegator storage d = delegators[msg.sender];
        require(amount < d.boundAmount[validator], "amount greater than bound amount");

        _delDelegator(msg.sender, validator, amount);

        // Push record
        undelegationRecords.push(
            UndelegationRecord(
                validator,
                payable(msg.sender),
                amount,
                block.number
            )
        );

        emit Undelegation(validator, msg.sender, amount);
    }

    // Update validator
    // 该操作只能有 staker来操作
    function updateValidator(
        address validator,
        string calldata memo,
        uint256 rate
    ) public {
        // Check whether the validator is a stacker
        Validator storage v = validators[validator];
        require(
            v.staker == msg.sender,
            "only staker can do this operation"
        );
    
        validators[validator].memo = memo;
        validators[validator].rate = rate;
    }

    
    // Return unDelegate assets
    function trigger() public onlyRole(SYSTEM_ROLE) {
        uint256 blockNo = block.number;

        for (uint256 i; i < undelegationRecords.length; i++) {
            UndelegationRecord storage ur = undelegationRecords[i];

            // If this record reach target hright, send value and descrease amount.
            if ((blockNo - ur.height) >= unboundBlock) {
                _realDelDelegator(ur.delegator, ur.validator, ur.amount);

                // Send value
                Address.sendValue(
                    ur.delegator,
                    ur.amount
                );
            }
        }
    }
}
