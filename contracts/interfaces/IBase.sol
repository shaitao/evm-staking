// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBase {
    enum PublicKeyType {
        Unknown,
        Secp256k1,
        Ed25519
    }

    struct ValidatorInfo {
        bytes public_key;
        PublicKeyType ty;
        address addr;
        uint256 power;
    }

    enum ByztineBehavior {
        DuplicateVote,
        LightClientAttack,
        Unknown
    }

    struct ClaimOps {
        address addr;
        uint256 amount;
    }
}
