// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function deloyAmountUtils() {
    const AmountUtils = await ethers.getContractFactory("AmountUtils");
    const au = await AmountUtils.deploy();

    await au.deployed();

    console.log("AmountUtils address is:", au.address);

    return au.address;
}

async function main() {
    const Staking = await ethers.getContractFactory("Staking");

    const mc = await upgrades.deployProxy(Staking, ["0x72488bAa718F52B76118C79168E55c209056A2E6"]);

    await mc.deployed();

    console.log("Staking address:", mc.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
