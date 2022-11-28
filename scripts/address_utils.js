const axios = require("axios");

async function get_proxy_address() {
    let checkpoint = await axios.get("https://dev-qa04.dev.findora.org:8668/display_checkpoint");
    let proxy_address = checkpoint.data.evm_staking_address;

    return proxy_address;
}

module.exports = {
    get_proxy_address,
}

