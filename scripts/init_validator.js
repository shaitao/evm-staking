// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
    let memo1 = {"desc":"a","logo":"https://i.imgur.com/JfxwM7J.png","name":"Koncrete Validator","website":"Koncrete.org"};

    const sa = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

    const validatos = [
        {
            validator: "0x000E33AB7471186F3B1DE9FC08BB9C480F453590",
            public_key: "0x1fac26b9312e978eac0afc035170ad611c6d5bac62540c306bda5eceb3f6a3cd",
            staker: sa,
            memo: JSON.stringify(memo1),
            rate: 20000,
        },
        {
            validator: "0856654F7CD4BB0D6CC4409EF4892136C9D24692",
            public_key: "0x1fac26b9312e978eac0afc035170ad611c6d5bac62540c306bda5eceb3f6a3cd",
            staker: sa,
            memo: JSON.stringify(memo1),
            rate: 20000,
        },
        {
            validator: "5C97EE9B91D90B332813078957E3A96B304791B4",
            public_key: "0x1fac26b9312e978eac0afc035170ad611c6d5bac62540c306bda5eceb3f6a3cd",
            staker: sa,
            memo: JSON.stringify(memo1),
            rate: 20000,
        },
        {
            validator: "FD8C65634A9D8899FA14200177AF19D24F6E1C37",
            public_key: "0x1fac26b9312e978eac0afc035170ad611c6d5bac62540c306bda5eceb3f6a3cd",
            staker: sa,
            memo: JSON.stringify(memo1),
            rate: 20000,
        },
    ];

    const Power = await ethers.getContractFactory("Staking");

    const power = await Power.attach("0x610178dA211FEF7D417bC0e6FeD39F05609AD788");

    for (let v of validatos) {
        await power.adminStake(v.validator, v.public_key, v.staker, v.memo, v.rate, {
            value: ethers.utils.parseEther("1"),
        });
        console.log("stake: ", v.validator);
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
