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

    enum RequestStatus { PENDING, CANCELED, APPROVED, REJECTED }

    struct Request {
        address requester; // Owner of the request
        uint amount; // Amount of token to mint/burn
        string depositAddress; // User's XPX deposit address in burn, user's ETH address in mint
        string txid; // Assets txid for sending / redemming asset in the burn / mint process
        uint nonce; // Serial number allocated for each request
        uint timestamp; // Time of the request creation.
        RequestStatus status; // Status of the request.
    }

    // mapping between a mint request hash and the corresponding request nonce. 
    mapping(bytes32 => uint) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32 => uint) public burnRequestNonce;

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

    // Pause functions

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

    function _calcRequestHash(Request memory request) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.nonce,
            request.timestamp
        ));
    }

    function getPendingMintRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash) internal view returns (uint nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }
}
