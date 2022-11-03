// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
    const Staking = await ethers.getContractFactory("Staking");

    const mc = await upgrades.deployProxy(Staking, ["0x72488baa718f52b76118c79168e55c209056a2e6"]);

    await mc.deployed();

    console.log("Staking address:", mc.address);

    const Power = await ethers.getContractFactory("Power");

    const p = await Power.deploy(mc.address, 10);

    await p.deployed();

    console.log("Power address:", p.address);

    const Reward = await ethers.getContractFactory("Reward");
    const reward = await upgrades.deployProxy(Reward, [mc.address]);

    await reward.deployed();

    console.log("Reward address:", reward.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
