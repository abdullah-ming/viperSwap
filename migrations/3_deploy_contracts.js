var config = require("./config.json");
var RLP = require("rlp");
const { keccak256 } = require("eth-lib/lib/hash");
var Bytes = require("bytes");
const { toBech32Address, decodeBech32Address, hexToBytes, bytesToHex } = require("@alayanetwork/web3-utils");
const stakingRewards = artifacts.require("StakingRewards");
const uni = artifacts.require("Uni");
const Timelock = artifacts.require("Timelock");
const GovernorAlpha = artifacts.require("GovernorAlpha");

module.exports = async function(deployer) {
    var seconds = (new Date().getTime() / 1000).toFixed() + 600;
    await deployer.deploy(uni, config.feeToSetter, config.uniMiner, seconds);
    console.log('Uni at:', uni.address);

    await Promise.all(config.pairs.map(async pair => {
        await deployer.deploy(stakingRewards, config.rewardsDistribution, uni.address,pair.address);
        console.log(`${pair.name} stakingRewards at: `, stakingRewards.address);
    }));

    const nonce = await web3.platon.getTransactionCount(config.feeToSetter);
    console.log("nonce: ", nonce);
    var sender = decodeBech32Address(config.feeToSetter);
    var rlp = RLP.encode([sender, nonce + 1]);
    var pubBytes = hexToBytes('0x' + rlp.toString("hex"));
    var publicHash = keccak256('0x' + rlp.toString("hex"));
    var address = "0x" + publicHash.slice(-40);
    console.log("Governor contract address predict: ", toBech32Address("atp", address));

    // 172800对应的是2 Days秒数
    await deployer.deploy(Timelock, config.feeToSetter, 172800);
    console.log('Timelock at: ', Timelock.address);

    await deployer.deploy(GovernorAlpha, Timelock.address, uni.address);
    console.log('GovernorAlpha at: ', GovernorAlpha.address);
};