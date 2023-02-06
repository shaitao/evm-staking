const { ethers } = require("hardhat");
const utils = require("./address_utils");
const Web3 = require('web3');
const fs = require('fs');

async function main() {

    const addrs = await utils.get_address();

    console.log("Staking addres:", addrs.staking);

    const Staking = await ethers.getContractFactory("Staking");
    const staking = Staking.attach(addrs.staking);

    const resp = await staking.delegate("0x000E33AB7471186F3B1DE9FC08BB9C480F453590", {
        value: ethers.utils.parseEther("300"), gasLimit: 3000000
    });

    const data = await resp.wait();
    // console.log(data)
    const events = data.events;
    const receipt = await events[0].getTransactionReceipt();
    console.log("receipt: ", await receipt.events[0].getTransactionReceipt());
}

async function main_web3() {
    const web3 = new Web3('https://dev-qa04.dev.findora.org:8545');
    const contractAbi = JSON.parse(fs.readFileSync("data/abi/contracts/Staking.sol/Staking.json", { encoding: 'utf-8' }).toString());
    // console.log(JSON.stringify(contractAbi));
    const contractAddress = "0xdE981A3249df3f10d7c8768554118b16D63b4132";

    const stakingContract = new web3.eth.Contract(contractAbi, contractAddress);

    // 调用合约，写入数据
    let txn = await web3.eth.accounts.signTransaction({
        gas: "214320",
        from: "0x72488bAa718F52B76118C79168E55c209056A2E6",
        to: contractAddress,
        data: stakingContract.methods.delegate("0x0856654F7CD4BB0D6CC4409EF4892136C9D24692").encodeABI(),
        value: ethers.utils.parseEther("70")
    }, "0x4d05b965f821ea900ddd995dfa1b6caa834eaaa1ebe100a9760baf9331aae567");

    //发送
    web3.eth.sendSignedTransaction(txn.rawTransaction).on('transactionHash', function (hash) {
        console.log("交易hash：", hash)
    }).on('receipt', function (receipt) {
        console.log("返回Receipt：", receipt)
    }).on('confirmation', function (confirmationNumber, receipt) {
        console.log("确认数：", confirmationNumber)
        console.log("返回Receipt：", receipt)
    }).on('error', console.error);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});

main_web3().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});


