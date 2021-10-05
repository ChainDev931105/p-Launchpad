const ScopeToken = artifacts.require('ScopeToken');
const StakeToken = artifacts.require('StakeToken');
const Insurance = artifacts.require('Insurance');
const SPOracle = artifacts.require('SPOracle');
const SPOracleMock = artifacts.require('SPOracleMock');
const ProjectInfo = artifacts.require('ProjectInfo');
const TokenFundingManager = artifacts.require('TokenFundingManager');
const WithdrawManager = artifacts.require('WithdrawManager');

module.exports = async function (_deployer, network) {
  let scopeToken = await ScopeToken.deployed();
  let stakeToken = await StakeToken.deployed();
  let insurance = await Insurance.deployed();
  let projectInfo = await ProjectInfo.deployed();
  let withdrawManager = await WithdrawManager.deployed();

  let oracle;

  // in development deploy the mock for testing (needed because of the oracle)
  if (network != 'development') {
    oracle = await SPOracle.deployed();
  } else {
    oracle = await SPOracleMock.deployed();
  }

  await _deployer.deploy(
    TokenFundingManager,
    withdrawManager.address,
    scopeToken.address,
    stakeToken.address,
    insurance.address,
    oracle.address,
    projectInfo.address
  );

  let tokenFundingManger = await TokenFundingManager.deployed();
  await withdrawManager.initialize(tokenFundingManger.address);
};
