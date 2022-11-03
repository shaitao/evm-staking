// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
    const S = await ethers.getContractFactory("Staking");

    const s = await S.attach("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");

    let r0 = await s.totalDelegationAmount();

    console.log("total:", r0);


    let r1 = await s.delegatorsBoundAmount("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "0856654F7CD4BB0D6CC4409EF4892136C9D24692");
    console.log("unbound:", r1);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
