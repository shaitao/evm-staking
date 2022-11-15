// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function redeploySystem(proxy) {
    const System = await ethers.getContractFactory("System");
    const system = await System.deployProxy(proxy);
    await system.deployed();

    const P = await ethers.getContractFactory("Proxy");
    const proxy = await P.attach(proxy);
    await proxy.adminSetSystemAddress(system.address);

    console.log("System address:", system.address);

    return system.address;
}

async function deployStaking(system) {
    const Staking = await ethers.getContractFactory("Staking");

    const staking = await upgrades.deployProxy(Staking, [system]);

    await staking.deployed();

    console.log("Staking address:", staking.address);

    return staking.address;
}

async function deployPower(staking, limit) {
    const Power = await ethers.getContractFactory("Power");

    const p = await Power.deploy(staking, limit);

    await p.deployed();

    console.log("Power address:", p.address);
}

async function deployReward(staking, system) {
    const Reward = await ethers.getContractFactory("Reward");
    const reward = await upgrades.deployProxy(Reward, [staking, system]);

    await reward.deployed();

    console.log("Reward address:", reward.address);
}

async function main() {
    const proxy = "0x72488baa718f52b76118c79168e55c209056a2e6";

    const system_addr = await redeploySystem(proxy);

    const staking_addr = await deployStaking(system_addr);

    await deployPower(staking_addr, 10);

    await deployReward(staking_addr, system_addr);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
