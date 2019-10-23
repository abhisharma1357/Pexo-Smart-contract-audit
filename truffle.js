//const HDWalletProvider = require('truffle-hdwallet-provider');

//const infura_apikey = 'infura api key goes here';
//const mnemonic = 'your metamask mnemonic goes here';

module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
      //from: '0xcc42b083231d36976a1e018ee219fd37f0079741'
    },
    coverage: {
      host: 'localhost',
      network_id: '*',
      port: 8545,         // <-- If you change this, also set the port option in .solcover.js.
      gas:0xfffffffffff, // <-- Use this high gas value
      gasPrice: 0x01     // <-- Use this low gas price
    },
    // See <http://truffleframework.com/docs/advanced/configuration>
    // to customize your Truffle configuration!
    solc: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }

    /*
    ropsten: {
      provider: function() {
		  return new HDWalletProvider(mnemonic, `https://ropsten.infura.io/${infura_apikey}`);
		  },
      network_id: 3,
      gas: 4698712
    }
    */
  }

};
