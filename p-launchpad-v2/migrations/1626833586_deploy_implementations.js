const ScopeToken = artifacts.require('ScopeToken');
const StakeToken = artifacts.require('StakeToken');
const Insurance = artifacts.require('Insurance');
const SPOracle = artifacts.require('SPOracle');
const SPOracleMock = artifacts.require('SPOracleMock');
const ProjectInfo = artifacts.require('ProjectInfo');

module.exports = function (deployer, network) {
  deployer.deploy(ScopeToken);
  deployer.deploy(StakeToken);
  deployer.deploy(Insurance);
  deployer.deploy(ProjectInfo);

  // in development deploy the mock for testing (needed because of the oracle)
  if (network != 'development') {
    deployer.deploy(SPOracle);
  } else {
    deployer.deploy(SPOracleMock);
  }
};
