// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/ISystem.sol";

contract System {
    mapping(address => uint256) powers;

    mapping(address => bytes) pubkeys;

    function addPower(address validator, uint256 power) public {}

    function descPower(address validator, uint256 power) public {}

    function blockTrigger() public {}
}
