// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IStaking.sol";

contract Staking is Ownable, IStaking {
    address public system;

    struct Validator {
        bytes public_key;
        uint256 power;
        string memo;
        uint256 rate;
        address staker;
    }

    mapping(address => Validator) public validators;

    // Enumable.

    // delegator => validator => amount.
    mapping(address => mapping(address => uint256)) public delegators;

    struct UndelegationRecord {
        address payable receiver;
        uint256 amount;
        uint256 height;
    }

    UndelegationRecord[] public records;

    function stake(
        address validator,
        bytes calldata public_key,
        string calldata memo,
        uint256 rate
    ) external payable override {
        // require();

        Validator storage v = validators[validator];

        v.public_key = public_key;
        v.memo = memo;
        v.rate = rate;
        v.staker = msg.sender;
        v.power = msg.value;
    }

    function delegate(address validator) external payable override {
        // require()

        delegators[msg.sender][validator] += msg.value;
        validators[validator].power += msg.value;
    }

    function undelegate(address validator, uint256 amount) external override {
        // require()

        delegators[msg.sender][validator] -= amount;
        validators[validator].power -= amount;

        // Push record.
    }

    function trigger() public {
        // iter
        // Address.sendValue()
    }
}
