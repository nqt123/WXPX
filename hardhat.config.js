require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: '0.7.1',
  defaultNetwork: 'localhost',
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    goerli: {
      url:
        'https://eth-goerli.alchemyapi.io/v2/xGtdt4Mu_Kib3_VzN0uoa8s3G57NWPNd',
      accounts: [
        '8a4902974a7ff479944b3abe29a2b5be56c6e68ba5c491474412f33e1710839e',
      ],
    },
    ropsten: {
      url:
        'https://ropsten.infura.io/v3/d5b0b1695ced49f39207480b43a346b2',
      accounts: [
        '8a4902974a7ff479944b3abe29a2b5be56c6e68ba5c491474412f33e1710839e',
      ],
    },
  },
  etherscan: {
    apiKey: 'VU7SX55SS1NJ1S85HDKN1REWYZTRCC9ZGZ',
  },
  
};
