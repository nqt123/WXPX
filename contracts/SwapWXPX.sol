//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./token/WXPX.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SwapWXPX is Ownable, AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant CUSTODIAN = keccak256("CUSTODIAN");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    WXPX public token;

    constructor(WXPX _token) {
        require(address(_token) != address(0), "SwapWXPX::INVALID_TOKEN_ADDRESS");

        token = WXPX(_token);

        _setupRole(CUSTODIAN, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }
    

    // events


    // modifiers
    
    /**
     * @notice Modifier to make a function callable only by custodian.
     */
    modifier onlyCustodian() {
        require(hasRole(CUSTODIAN, msg.sender), "SwapWXPX::NOT_AUTHORIZED");
        _;
    }

    // custodian functions

    /**
     * @notice Pauses all request.
     * Requirements:
     * - contract is unpausing
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public whenNotPaused virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()),"WXPX: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all request.
     *
     * Requirements:
     * - contract is paused
     * - the caller must have the `PAUSER_ROLE`.
    */
    function unpause() public whenPaused virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "WXPX: must have pauser role to unpause");
        _unpause();
    }
}
