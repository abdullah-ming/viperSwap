const Multicall = artifacts.require("Multicall");
const viperFactory = artifacts.require("ViperFactory");
const WATP = artifacts.require("WATP");
const viperRouter01 = artifacts.require("ViperRouter01");
// const viperV2ERC20 = artifacts.require("ViperERC20");
const feeToSetter='atp1rzpujegp3uhdl6pfdcrjt04xja456656pssudz'; //有权更改 feeTo 地址的账户,为当前合约部署者

module.exports = async function(deployer) {
   await deployer.deploy(viperFactory,feeToSetter);
   console.log('viperFactory at:',viperFactory.address);

   await  deployer.deploy(WATP);
   console.log('WATP at:',WATP.address);

   await  deployer.deploy(viperRouter01,viperFactory.address,WATP.address);
   console.log('viperRouter01 at:',viperRouter01.address);

//   await  deployer.deploy(viperV2ERC20);
//   console.log('viperV2ERC20 at:',viperV2ERC20.address);

   await deployer.deploy(Multicall);
   console.log('Multicall  at:',Multicall.address);

   var factory = new web3.platon.Contract(require("../build/contracts/ViperFactory.json")['abi'], viperFactory.address, {net_type:"atp"});

   var initHash = await factory.methods.INIT_VIPERV2PAIR_HASH().call();
   console.log("initHash is at:",initHash);
};