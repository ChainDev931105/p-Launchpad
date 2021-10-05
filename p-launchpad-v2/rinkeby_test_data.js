const { constants, time } = require('@openzeppelin/test-helpers');

// const {getInputs} = require("./rinkeby_test_data")
// inp = getInputs('0xbc972eecbff0adc4b4fa20b236d1718ec4a5ac84')
// t = await TokenFundingManager.deployed()
// await t.initializeTokenFunding(inp.tokenFundingData, inp.priceOracleInfo, 50)

function getData(dataType) {
  switch (dataType) {
    case 'tokenFundingData': {
      // All the timestamp values are set calling the updateTimesOf function

      let fundingScopeRoundsData = [
        {
          openingTime: 0,
          durationTime: 30,
          discount: 50,
          capTokensToBeSold: 1000,
          mintedTokens: 0,
        },
      ];

      let fundingStakeRoundsData = [
        {
          openingTime: 0,
          durationTime: 30,
          stakeReward: 50,
          capTokensToBeStaked: 1000,
          stakedTokens: 0,
        },
      ];

      let tokenFundingData = {
        appToken: constants.ZERO_ADDRESS,
        rMin: 5000,
        rMax: 15000,
        maturity: 0,
        t: 0,
        owners: ['0x4A8Cc549c71f12817F9aA25F7f6a37EB1A4Fa087'],
        fundingScopeRoundsData,
        fundingStakeRoundsData,
      };

      updateTimesOf(tokenFundingData);
      return tokenFundingData;
    }
    case 'priceOracleInfo': {
      let priceOracleInfo = {
        appToken: 'SHOULD BE SET WITH THE APP TOKEN ADDRESS STRING', // String
        linkToken: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
        chainlinkNode: '0x3A56aE4a2831C3d3514b5D7Af5578E45eBDb7a40',
        jobId: '3b7ca0d48c7a4b2da9268456665d11ae',
        nodeFee: 0, // to divide by 1000
      };

      return priceOracleInfo;
    }
  }
}

function updateTimesOf(tokenFundingData) {
  let now = Math.floor(Date.now() / 1000);

  tokenFundingData.maturity = now + 60;
  tokenFundingData.t = now + 60;

  tokenFundingData.fundingScopeRoundsData.forEach((round, index) => {
    round.openingTime = now + index * 20;
  });
  tokenFundingData.fundingStakeRoundsData.forEach((round, index) => {
    round.openingTime = now + index * 20;
  });
}

function getInputs(appToken) {
  let tokenFundingData = getData('tokenFundingData');
  let priceOracleInfo = getData('priceOracleInfo');

  tokenFundingData.appToken = appToken;
  priceOracleInfo.appToken = appToken;

  return { tokenFundingData, priceOracleInfo };
}

module.exports = { getInputs };
