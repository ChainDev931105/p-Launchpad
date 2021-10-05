// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../Structs.sol";
import "./StakeToken.sol";
import "./ScopeToken.sol";
import "../oracles/SPOracle.sol";

/**
 * @notice implementation of the poyect info for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract ProjectInfo is Initializable {
    StakeToken private _stakeToken;
    ScopeToken private _scopeToken;
    SPOracle private _oracle;

    address private _insuranceContractAddress;
    address private _appTokenAddress;

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        address _stakeTokenAddress,
        address _scopeTokenAddress,
        address _insuranceAddress,
        address _oracleAddress,
        address _tokenAddress
    ) external initializer {
        _stakeToken = StakeToken(_stakeTokenAddress);
        _scopeToken = ScopeToken(_scopeTokenAddress);
        _oracle = SPOracle(_oracleAddress);

        _insuranceContractAddress = _insuranceAddress;
        _appTokenAddress = _tokenAddress;
    }

    function getCurrentStakeRoundNumber() external view returns (uint256) {
        return _stakeToken.getRoundNumber();
    }

    function getCurrentScopeRoundNumber() external view returns (uint256) {
        return _scopeToken.getRoundNumber();
    }

    function getUnlockingTime() external view returns (uint256) {
        return _stakeToken.unlockingDate();
    }

    function getMaturityTime() external view returns (uint256) {
        return _scopeToken.maturityDate();
    }

    function getLowerRange() external view returns (uint256) {
        return _scopeToken.rMin();
    }

    function getUpperRange() external view returns (uint256) {
        return _scopeToken.rMax();
    }

    function getAccruedReward(uint256 _stakeTokenId) external view returns (uint256) {
        return _stakeToken.getAccruedReward(_stakeTokenId);
    }

    function getScopeTokenContract() external view returns (address) {
        return address(_scopeToken);
    }

    function getStakeTokenContract() external view returns (address) {
        return address(_stakeToken);
    }

    function getInsuranceContract() external view returns (address) {
        return _insuranceContractAddress;
    }

    function getOracleContract() external view returns (address) {
        return address(_oracle);
    }

    function getAppToken() external view returns (address) {
        return _appTokenAddress;
    }

    function getScopeRoundInfo(uint256 _roundNumber)
        public
        view
        returns (
            uint256 startingDate,
            uint256 endingDate,
            uint256 discount,
            uint256 capTokensToBeSold,
            uint256 mintedTokens
        )
    {
        FundingScopeRoundsData memory data = _scopeToken.getRoundInfo(_roundNumber);

        startingDate = data.openingTime;
        endingDate = data.openingTime + data.durationTime;
        discount = data.discount;
        capTokensToBeSold = data.capTokensToBeSold;
        mintedTokens = data.mintedTokens;
    }

    function getScopeRoundStartingDate(uint256 _roundNumber) external view returns (uint256 startingDate) {
        (startingDate, , , , ) = getScopeRoundInfo(_roundNumber);
    }

    function getScopeRoundEndingDate(uint256 _roundNumber) external view returns (uint256 endingDate) {
        (, endingDate, , , ) = getScopeRoundInfo(_roundNumber);
    }

    function getScopeRoundDiscount(uint256 _roundNumber) external view returns (uint256 discount) {
        (, , discount, , ) = getScopeRoundInfo(_roundNumber);
    }

    function getScopeRoundCap(uint256 _roundNumber) external view returns (uint256 capTokensToBeSold) {
        (, , , capTokensToBeSold, ) = getScopeRoundInfo(_roundNumber);
    }

    function getScopeRoundMintedTokens(uint256 _roundNumber) external view returns (uint256 mintedTokens) {
        (, , , , mintedTokens) = getScopeRoundInfo(_roundNumber);
    }

    function getStakeRoundInfo(uint256 _roundNumber)
        public
        view
        returns (
            uint256 startingDate,
            uint256 endingDate,
            uint256 stakeReward,
            uint256 capTokensToBeStaked,
            uint256 stakedTokens
        )
    {
        FundingStakeRoundsData memory data = _stakeToken.getRoundInfo(_roundNumber);

        startingDate = data.openingTime;
        endingDate = data.openingTime + data.durationTime;
        stakeReward = data.stakeReward;
        capTokensToBeStaked = data.capTokensToBeStaked;
        stakedTokens = data.stakedTokens;
    }

    function getStakeRoundStartingDate(uint256 _roundNumber) external view returns (uint256 startingDate) {
        (startingDate, , , , ) = getStakeRoundInfo(_roundNumber);
    }

    function getStakeRoundEndingDate(uint256 _roundNumber) external view returns (uint256 endingDate) {
        (, endingDate, , , ) = getStakeRoundInfo(_roundNumber);
    }

    function getStakeRoundReward(uint256 _roundNumber) external view returns (uint256 stakeReward) {
        (, , stakeReward, , ) = getStakeRoundInfo(_roundNumber);
    }

    function getStakeRoundCap(uint256 _roundNumber) external view returns (uint256 capTokensToBeStaked) {
        (, , , capTokensToBeStaked, ) = getStakeRoundInfo(_roundNumber);
    }

    function getUnstakeFee() external view returns (uint256) {
        return _stakeToken.unstakeFee();
    }

    function getStakeRoundStakedTokens(uint256 _roundNumber) external view returns (uint256 stakedTokens) {
        (, , , , stakedTokens) = getStakeRoundInfo(_roundNumber);
    }

    function getOracleSourceURL() external view returns (string memory) {
        return _oracle.apiURL();
    }
}
