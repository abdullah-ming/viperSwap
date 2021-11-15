// const HDWalletProvider = require('@truffle/hdwallet-provider');
module.exports = {
    networks: {
        development: {
            host: "47.241.91.2",     // 区块链所在服务器主机
            port: 6789,            // 链端口号
            network_id: "*",       // Any network (default: none)
            from: "atp1rzpujegp3uhdl6pfdcrjt04xja456656pssudz", //部署合约账号的钱包地址
            gas: 4612388,
            gasPrice: 500000000004,
         },
  },
  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },
  // Configure your compilers
  compilers: {
    solc: {
        version: "^0.5.16",    // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
        settings: {          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: false,
            runs: 200
          }
      //  evmVersion: "byzantium"
        }
    }
  }
}