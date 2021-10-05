// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleStructs.sol";

interface ISPOracle {
    /**
     * @dev the constructor for minimal proxies
     */
    function initialize(
        string memory,
        PriceOracleInfo memory,
        ScopeTimestamps memory,
        address[] memory
    ) external;

    /**
     * @dev returns the last S report of the oracle
     */
    // solhint-disable-next-line
    function latest_S() external view returns (uint256);

    /**
     * @dev returns the last P report of the oracle
     */
    // solhint-disable-next-line
    function latest_P() external view returns (uint256);
}
