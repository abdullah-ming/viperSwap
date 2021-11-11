const HDWalletProvider = require('@truffle/hdwallet-provider');
module.exports = {
    networks: {
        development: {
            provider: () => new HDWalletProvider("2dca9b1cb7916875a2957d303cc793f0613c695ea1a70b7e2778e8935dcb50f8", `http://47.241.91.2:6789`),
            network_id: "*",       // Any network (default: none)
         },
  },
  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },
  // Configure your compilers
  compilers: {
    solc: {
        version: "^0.5.17",    // Fetch exact version from solc-bin (default: truffle's version)
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