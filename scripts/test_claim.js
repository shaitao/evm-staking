const { ethers } = require("hardhat");
const utils = require("./address_utils");
const Web3 = require('web3');
const fs = require('fs');

async function main() {

    const addrs = await utils.get_address();

    console.log("Reward addres:", addrs.reward);

    const Reward = await ethers.getContractFactory("Reward");
    const reward = Reward.attach(addrs.reward);

    const resp = await reward.claim(2000, {
        gasLimit: 3000000
    });

    const data = await resp.wait();
    console.log(data);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
