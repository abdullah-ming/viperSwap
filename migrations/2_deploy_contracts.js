const Multicall = artifacts.require("Multicall");
const viperV2Factory = artifacts.require("ViperFactory");
const WATP = artifacts.require("WATP");
const viperV2Router02 = artifacts.require("ViperV2Router02");
const viperV2ERC20 = artifacts.require("ViperERC20");
const feeToSetter='atp1rzpujegp3uhdl6pfdcrjt04xja456656pssudz'; //有权更改 feeTo 地址的账户,为当前合约部署者

module.exports = async function(deployer) {
   await deployer.deploy(viperV2Factory,feeToSetter);
   console.log('viperV2Factory at:',viperV2Factory.address);

   await  deployer.deploy(WATP);
   console.log('WATP at:',WATP.address);

   await  deployer.deploy(viperV2Router02,viperV2Factory.address,WATP.address);
   console.log('viperV2Router02 at:',viperV2Router02.address);

//   await  deployer.deploy(viperV2ERC20);
//   console.log('viperV2ERC20 at:',viperV2ERC20.address);

   await deployer.deploy(Multicall);
   console.log('Multicall  at:',Multicall.address);

   var factory = new web3.platon.Contract(require("../build/contracts/ViperV2Factory.json")['abi'], viperV2Factory.address, {net_type:"atp"});

   var initHash = await factory.methods.INIT_VIPERV2PAIR_HASH().call();
   console.log("initHash is at:",initHash);
};