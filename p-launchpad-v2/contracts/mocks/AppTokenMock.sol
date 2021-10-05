// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @notice mock to simulate app token contract
 * @author Eric Nordelo
 */
contract AppTokenMock is ERC20, AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");

    mapping(address => bool) private _alreadyClaimedFreeTokens;

    constructor() ERC20("App Token Mock", "pATM") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN, msg.sender);
        _setupRole(MINTER, msg.sender);

        _setRoleAdmin(MINTER, ADMIN);

        _mint(msg.sender, 10000000000 * 10**decimals());
    }

    function getFreeTokens() external {
        require(!_alreadyClaimedFreeTokens[msg.sender], "Only can get free tokens once");
        _alreadyClaimedFreeTokens[msg.sender] = true;

        _mint(msg.sender, 1000 * 10**decimals());
    }

    function mintTo(address _recipient, uint256 _amount) external onlyRole(MINTER) {
        _mint(_recipient, _amount * 10**decimals());
    }
}
