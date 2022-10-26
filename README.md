# Evm staking for findora

## Deploy

``` shell
npx hardhat run scripts/deploy.js --network qa04
```

## Methods

### Decimal

All method use 6 decimal for FRA.

For Native FRA is 18 decimal, you must follow this rule:

Stake 3.123456 FRA, in Native FRA is: 312_3456_0000_0000_0000. this value is accept by Staking contract.

Stake 3.1234567 FRA, in Native is : 312_3456_7000_0000_0000. this value will be reject by Staking contract.

**The above rule is only used for `msg.value`. Argument of contract decimal is 6.**

### Staking Operations

#### stake

Make a fullnode to validator

- validator: address of validator. You can get this information from `config/priv_validator_key.json`
- public_key: validator's public key, you can get this information from `config/priv_validator_key.json`. Note: Need convert to hex format.
- memo: json format for display on blockexplorer.
- rate: rate. 6 decimal. i.e. 0.6 = 600000

Example of `config/priv_validator_key.json`:

```json
{
  "address": "E6987F77282FE6978373D64462EE3F823D114129",
  "pub_key": {
    "type": "tendermint/PubKeyEd25519",
    "value": "CifZFoeSuzNhJG0uMH0tSh1C9on37hicVsR3/41JkpA="
  },
  "priv_key": {
    "type": "tendermint/PrivKeyEd25519",
    "value": "S9lcIc4k+Ez5ZGu32Q6g3vfqtfYCbW3LcXtFeZEZwv0KJ9kWh5K7M2EkbS4wfS1KHUL2iffuGJxWxHf/jUmSkA=="
  }
}
```

Please use `msg.value` sending some FRA to stake. And `msg.sender` will be this validator's `staker`.


#### delegate

Delegate FRA to validator.

- validator: Which validator you want to delegete.

msg.value: Send some FRA.

#### undelegate

Undelegate FRA from validator. You must have enough FRA on this validator to undelegate.

- address: Which validator you want to undelegate.
- amount: how many FRA you want to undelegate.


#### updateValidator

Update `memo`, `rate`. You must be a `staker` of the validator.

- validator: Which validator you want to update.
- memo: Same as stake.
- rate: Same as stake.

### Read Operations

#### State Variable

These `state variable` can access directly. Default value maybe change, don't hardcode it.

- stakeMininum: Mininum staking value; Default: 10000 FRA
- delegateMininum: Mininum delegate value; Default 1 unit (0.000001 FRA)
- powerRateMaximum: Maxinum rate of power, Default is 0.2 (200000)
- blocktime: Blocktime, Default is 16.
- unboundBlock: Lock time for undelegate.
- totalDelegationAmount; totol amount.
- maxDelegationAmountBasedOnTotalAmount(); Stake / Delegate value must less than this value.

#### Validators

- validators: mapping(address => Validator); Mapping address to validator:
- allValidatorsLength() -> usize; Get all validators count.
- allValidatorsAt(uint256) -> address; Get validator's address based on idx, the range is `0 .. allValidatorsLength()`.
- allValidatorsContains(address) -> bool; If an address is validator, return true;

Validator struct contain these field:

```solidity
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
    // totol power of this validator
    uint256 power;
}
```

#### Delegators

- delegators: mapping(address => Delegator); Get Delegator info based on address

Delegators:

- boundAmount: mapping(address => uint256); Delegate / Stake amount on validator. address is validator address.
- unboundAmount: mapping(address => uint256); Total locked amount in undelegation.
- amount; Total amount for all validators.

Iterate all delegator:

- allDelegatorsLength(); Get all delegators count.
- allDelegatorsAt(uint256 idx) -> address; Get validator's address based on idx, the range is 0 .. allDelegatorsLength().
- allDelegatorsContains(address value) -> bool; If an address is delegator, return true;

Iterate `validator` to `delegator` . Get delegators under a validator:

- validatorOfDelegatorLength(address validator); Get all delegators count under validator.
- validatorOfDelegatorAt(address validator, uint256 idx) -> address; Get delegator address under validator.
- validatorOfDelegatorContains(address validator, address delegator) -> bool; If a validator have this delegator, return true.


Iterate `delegator` to `validator` . Get `delegator` stake to `validator`.

- delegatorOfValidatorLength(address delegator); Get all validators count is staked / delegated.
- delegatorOfValidatorAt(address delegator, uint256 idx) -> address; Get validator under delegator.
- delegatorOfValidatorContains(address delegator, address value) -> bool; If a delegator stake / delegate to validator, return true.








