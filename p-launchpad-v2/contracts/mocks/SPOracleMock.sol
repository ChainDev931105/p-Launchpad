// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../oracles/OracleStructs.sol";
import "../oracles/ISPOracle.sol";

/**
 * @title oracle to get the assets price in USD
 * @author Eric Nordelo
 */
contract SPOracleMock is ChainlinkClient, AccessControl, Initializable, ISPOracle {
    bytes32 private constant OWNER = keccak256("OWNER");
    int256 private constant TIMES = 10**18;

    uint256 private _s;
    uint256 private _p;

    ScopeTimestamps public scopeTimestamps;

    /// @notice the token to get the price for
    string public token;

    /// @notice the url to get the prices
    string public apiURL;

    /// @notice the chainlink node
    address public chainlinkNode;

    /// @notice the node job id
    bytes32 public jobId;

    /// @notice the fee in LINK
    uint256 public nodeFee;

    /// @notice the address of the LINK token
    address public linkToken;

    address[] public owners;

    // solhint-disable-next-line
    constructor() {}

    /**
     * @notice initializes minimal proxy clone
     */
    function initialize(
        string memory _token,
        PriceOracleInfo memory _oracleInfo,
        ScopeTimestamps memory _timestamps,
        address[] memory _owners
    ) external override initializer {
        owners = _owners;
        token = _token;
        linkToken = _oracleInfo.linkToken;
        chainlinkNode = _oracleInfo.chainlinkNode;
        jobId = stringToBytes32(_oracleInfo.jobId);
        nodeFee = (_oracleInfo.nodeFee * LINK_DIVISIBILITY) / 1000;

        apiURL = "https://backend-exchange-oracle-prod.privi.store/past?token=";
        scopeTimestamps = _timestamps;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i; i < _owners.length; i++) {
            _setupRole(OWNER, _owners[i]);
        }

        setChainlinkToken(linkToken);

        /**
         * @dev this is the Mocked part
         */
        _s = 10 * 10**18;
        _p = 11 * 10**18;
    }

    function setOracleInfo(PriceOracleInfo calldata _oracleInfo) external onlyRole(OWNER) {
        linkToken = _oracleInfo.linkToken;
        chainlinkNode = _oracleInfo.chainlinkNode;
        jobId = stringToBytes32(_oracleInfo.jobId);
        nodeFee = (_oracleInfo.nodeFee * LINK_DIVISIBILITY) / 1000; // 0.01 LINK

        setChainlinkToken(linkToken);
    }

    function setAPIURL(string calldata _url) external onlyRole(OWNER) {
        apiURL = _url;
    }

    // solhint-disable-next-line
    function update_S() external returns (bytes32 requestId) {
        // solhint-disable-next-line
        require(block.timestamp > scopeTimestamps.lastGSlabEndingDate, "Can't update S yet");
        require(_s == 0, "S already set");

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill_S.selector
        );

        // set the request params
        Chainlink.add(
            request,
            "get",
            string(
                abi.encodePacked(
                    apiURL,
                    token,
                    "&start=",
                    uint2str(scopeTimestamps.firstGSlabOpeningDate),
                    "&end=",
                    uint2str(scopeTimestamps.lastGSlabEndingDate)
                )
            )
        );
        Chainlink.add(request, "path", "vwap");
        Chainlink.addInt(request, "times", TIMES);

        // Send the request
        return sendChainlinkRequestTo(chainlinkNode, request, nodeFee);
    }

    // solhint-disable-next-line
    function update_P() external returns (bytes32 requestId) {
        // solhint-disable-next-line
        require(block.timestamp > scopeTimestamps.maturityDate, "Can't update P yet");
        require(_p == 0, "P already set");

        Chainlink.Request memory request = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill_P.selector
        );

        // set the request params
        Chainlink.add(
            request,
            "get",
            string(
                abi.encodePacked(
                    apiURL,
                    token,
                    "&start=",
                    uint2str(scopeTimestamps.lastGSlabEndingDate),
                    "&end=",
                    uint2str(scopeTimestamps.maturityDate)
                )
            )
        );
        Chainlink.add(request, "path", "vwap");
        Chainlink.addInt(request, "times", TIMES);

        // Sends the request
        return sendChainlinkRequestTo(chainlinkNode, request, nodeFee);
    }

    /**
     * @dev Receive the response in the form of uint256
     */
    // solhint-disable-next-line
    function fulfill_S(bytes32 _requestId, uint256 __s) public recordChainlinkFulfillment(_requestId) {
        _s = __s;
    }

    /**
     * @dev Receive the response in the form of uint256
     */
    // solhint-disable-next-line
    function fulfill_P(bytes32 _requestId, uint256 __p) public recordChainlinkFulfillment(_requestId) {
        _p = __p;
    }

    /**
     * @dev returns the last S report of the oracle
     */
    // solhint-disable-next-line
    function latest_S() external view override returns (uint256) {
        return _s;
    }

    /**
     * @dev returns the last P report of the oracle
     */
    // solhint-disable-next-line
    function latest_P() external view override returns (uint256) {
        return _p;
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := mload(add(source, 32))
        }
    }

    function uint2str(uint256 _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
