// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../oracles/SPOracle.sol";
import "../Structs.sol";
import "./Insurance.sol";

/**
 * @notice implementation of the erc20 token for minimal proxy multiple deployments
 * @author Eric Nordelo
 */
contract ScopeToken is ERC20, AccessControl, Pausable, Initializable {
    bytes32 private constant OWNER = keccak256("OWNER");
    uint256 private constant DISCOUNT_PRECISION = 1000;
    uint256 private constant PRECISION = 1000000;

    address private _appToken;
    address private _insuranceContractAddress;

    uint256 public rMin;
    uint256 public rMax;

    string private _proxiedName;
    string private _proxiedSymbol;
    address private _priceOracleAddress;

    FundingScopeRoundsData[] private _fundingRoundsData;

    uint256 public maturityDate; // date of maturity of the options

    event ClaimTokens(address indexed holder, uint256 balance);

    // solhint-disable-next-line
    constructor() ERC20("Privi Scope Token Implementation", "pSTI") {}

    /**
     * @notice initializes the minimal proxy clone
     * @dev ! INSERTING AN ARRAY OF STRUCTS, VERY EXPENSIVE!!!
     * @param _name the name of the token
     * @param _symbol the symbol of the token
     * @param _tokenFundingData the token funding data
     * @param __insuranceContractAddress the insurance contract address for app token balance handling
     * @param __priceOracleAddress the price oracle contract address
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        TokenFundingData calldata _tokenFundingData,
        address __insuranceContractAddress,
        address __priceOracleAddress
    ) external initializer {
        _proxiedName = _name;
        _proxiedSymbol = _symbol;

        _appToken = _tokenFundingData.appToken;
        _insuranceContractAddress = __insuranceContractAddress;

        // initialize variables
        rMin = _tokenFundingData.rMin;
        rMax = _tokenFundingData.rMax;
        maturityDate = _tokenFundingData.maturity;
        _priceOracleAddress = __priceOracleAddress;

        require(_tokenFundingData.fundingScopeRoundsData.length > 0, "Invalid rounds count");
        for (uint256 i; i < _tokenFundingData.fundingScopeRoundsData.length; i++) {
            require(_tokenFundingData.fundingScopeRoundsData[i].mintedTokens == 0, "Invalid data");
            _fundingRoundsData.push(_tokenFundingData.fundingScopeRoundsData[i]);
        }

        for (uint256 i; i < _tokenFundingData.fundingScopeRoundsData.length - 1; i++) {
            require(_tokenFundingData.fundingScopeRoundsData[i].mintedTokens == 0, "Invalid data");
            if (
                _tokenFundingData.fundingScopeRoundsData[i].discount <
                _tokenFundingData.fundingScopeRoundsData[i + 1].discount ||
                _tokenFundingData.fundingScopeRoundsData[i].discount == 0
            ) {
                revert("Invalid discount distribution");
            }
            _fundingRoundsData.push(_tokenFundingData.fundingScopeRoundsData[i]);
        }
        _fundingRoundsData.push(
            _tokenFundingData.fundingScopeRoundsData[_tokenFundingData.fundingScopeRoundsData.length - 1]
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i; i < _tokenFundingData.owners.length; i++) {
            _setupRole(OWNER, _tokenFundingData.owners[i]);
        }
    }

    /**
     * @notice allows owners to pause the contract
     */
    function pause() external onlyRole(OWNER) {
        _pause();
    }

    /**
     * @notice allows owners to unpause the contract
     */
    function unpause() external onlyRole(OWNER) {
        _unpause();
    }

    /**
     * @notice allows to claim the app tokens at the right time
     */
    function claim() external whenNotPaused {
        // solhint-disable-next-line
        require(maturityDate <= block.timestamp, "Maturity date not reached yet");

        (uint256 holderBalance, uint256 payout) = balanceAndPayoutOf(msg.sender);
        require(holderBalance > 0, "No tokens to claim");

        uint256 appTokensToReceive = ((holderBalance * payout) / PRECISION);

        // burn the tokens before transfer
        _burn(msg.sender, holderBalance);

        // send the tokens from payout
        bool transfered = Insurance(_insuranceContractAddress).sendAppTokens(msg.sender, appTokensToReceive);
        require(transfered, "Fail to transfer");

        emit ClaimTokens(msg.sender, appTokensToReceive);
    }

    /**
     * @notice returns the owed balance of the contract in app tokens at the time
     */
    function getAppTokensOwed() external view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 payout = scopeTokenPayout();

        return (supply * payout) / PRECISION;
    }

    /**
     * @notice returns the estimated payout at the time
     * @dev the actual value should be divided by precision
     */
    function scopeTokenPayout() public view returns (uint256) {
        // solhint-disable-next-line
        require(maturityDate <= block.timestamp, "Maturity has not been reached");

        uint256 p = SPOracle(_priceOracleAddress).latest_P();
        uint256 s = SPOracle(_priceOracleAddress).latest_S();

        require(p > 0, "P not set yet (call the oracle first)");
        require(s > 0, "S not set yet (call the oracle first)");

        // multiply * 10**15 to get 18 decimals as s and p (3 from input)
        uint256 rMaxWith18decimals = rMax * 10**15;
        uint256 rMinWith18decimals = rMin * 10**15;

        if (p < (rMinWith18decimals)) {
            return (rMaxWith18decimals * PRECISION) / (rMinWith18decimals);
        } else if (p > rMaxWith18decimals) {
            return PRECISION; // 1 for 1
        } else {
            return (rMaxWith18decimals * PRECISION) / p;
        }
    }

    /**
     * @notice returns the balance and the payout at the time
     */
    function balanceAndPayoutOf(address _holder) public view returns (uint256 balance, uint256 payout) {
        balance = balanceOf(_holder);
        payout = scopeTokenPayout();
    }

    /**
     * @notice returns the round info
     */
    function getRoundInfo(uint256 _roundNumber) public view returns (FundingScopeRoundsData memory) {
        require(_roundNumber > 0, "Rounds index starts with 1");
        require(_fundingRoundsData[_roundNumber - 1].capTokensToBeSold > 0, "Unexistent round");
        return _fundingRoundsData[_roundNumber - 1];
    }

    /**
     * @notice returns the index of the active round or zero if there is none
     */
    function getRoundNumber() public view returns (uint256) {
        // solhint-disable-next-line
        uint256 currentTime = block.timestamp;
        if (
            currentTime < _fundingRoundsData[0].openingTime ||
            currentTime >
            _fundingRoundsData[_fundingRoundsData.length - 1].openingTime +
                _fundingRoundsData[_fundingRoundsData.length - 1].durationTime
        ) {
            return 0;
        }
        for (uint256 i; i < _fundingRoundsData.length; i++) {
            if (
                currentTime >= _fundingRoundsData[i].openingTime &&
                currentTime < _fundingRoundsData[i].openingTime + _fundingRoundsData[i].durationTime
            ) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @dev allow to investors buy scope tokens specifiying the amount of scope tokens
     * @param _amount allow to the investors that buy scope token specifying the amount
     */
    function buyTokensByAmountToGet(uint256 _amount) external whenNotPaused {
        uint256 _roundId = getRoundNumber();
        require(_roundId != 0, "None open round");

        uint256 _roundIndex = _roundId - 1;
        require(
            _fundingRoundsData[_roundIndex].mintedTokens < _fundingRoundsData[_roundIndex].capTokensToBeSold,
            "All tokens sold"
        );
        require(
            _amount <=
                (_fundingRoundsData[_roundIndex].capTokensToBeSold -
                    _fundingRoundsData[_roundIndex].mintedTokens),
            "Insuficient tokens"
        );

        uint256 _amountToPay = _amount;
        _amountToPay -= (_amountToPay * _fundingRoundsData[_roundIndex].discount) / DISCOUNT_PRECISION;
        require(_amountToPay > 0, "Invalid payment after discount");

        _mint(msg.sender, _amount);
        _fundingRoundsData[_roundIndex].mintedTokens += _amount;

        bool result = ERC20(_appToken).transferFrom(msg.sender, _insuranceContractAddress, _amountToPay);
        // solhint-disable-next-line
        require(result);
    }

    function name() public view virtual override returns (string memory) {
        return _proxiedName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _proxiedSymbol;
    }
}
