// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
    const P = await ethers.getContractFactory("SystemProxy");

    const proxy = await P.deploy();
    await proxy.deployed();

    const System = await ethers.getContractFactory("System");
    const system = System.attach(proxy.address);

    console.log(system.interface.getSighash("getValidatorsList"));

    const list = await system.getValidatorsList();

    console.log(list);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
