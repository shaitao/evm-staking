// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IBase.sol";

interface IPrismXX {
    function depositFRA(bytes calldata _to) external payable;
}
