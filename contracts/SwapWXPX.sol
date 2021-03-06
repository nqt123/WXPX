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
        RequestStatus status; // Status of the request.
    }

    // mapping between a mint request hash and the corresponding request nonce. 
    mapping(bytes32 => uint) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32 => uint) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    // events
    //
    event Burned(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string depositAddress,
        uint256 timestamp,
        bytes32 requestHash
    );

    event BurnConfirmed(
        uint indexed nonce,
        address indexed requester,
        uint amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 inputRequestHash
    );

    constructor(WXPX _token) {
        require(address(_token) != address(0), "SwapWXPX::Invalid token address");

        token = WXPX(_token);

        _setupRole(CUSTODIAN, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }
    
    // modifiers

    /**
     * @notice Modifier to make a function callable only by custodian.
     */
    modifier onlyCustodian() {
        require(hasRole(CUSTODIAN, msg.sender), "SwapWXPX::Not authorized");
        _;
    }

    // External functions
    //
    function swapWrappedTokenToXpx(uint256 amount, string memory xpxAddress) external returns (bool) {
        string memory depositAddress = xpxAddress;
        require(!isEmptyString(depositAddress), "SwapWXPX::Deposit address was not set"); 

        uint nonce = burnRequests.length;

        // set txid as empty since it is not known yet.
        string memory txid = "";

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            depositAddress: depositAddress,
            txid: txid,
            nonce: nonce,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce; 
        burnRequests.push(request);

        require(_deliverTokensFrom(msg.sender, address(this), amount), "SwapWXPX::Transfer tokens to burn failed");

        emit Burned(nonce, msg.sender, amount, depositAddress, block.timestamp, requestHash);

        return true;
    }

    function confirmSwapWrappedTokenToXpx(bytes32 requestHash, string memory txid) external onlyCustodian returns (bool) {
        uint nonce;
        Request memory request;

        require(!isEmptyString(txid), "SwapWXPX::Txid invalid"); 

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].txid = txid;
        burnRequests[nonce].status = RequestStatus.APPROVED;

        require(_tokenBurn(burnRequests[nonce].amount), "SwapWXPX::Burn failed");
        
        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            txid,
            block.timestamp,
            requestHash
        );
        
        return true;
    }

    function getSwapToXpxRequest(uint nonce)
        external
        view
        returns (
            uint requestNonce,
            address requester,
            uint amount,
            string memory depositAddress,
            string memory txid,
            string memory status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status); 

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        status = statusString;
        requestHash = calcRequestHash(request);
    }
    
    // Public functions
    //
    /**
     * @notice Pauses all request.
     * Requirements:
     * - contract is unpausing
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual whenNotPaused {
        require(hasRole(PAUSER_ROLE, _msgSender()),"SwapWXPX::Must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all request.
     *
     * Requirements:
     * - contract is paused
     * - the caller must have the `PAUSER_ROLE`.
    */
    function unpause() public virtual whenPaused {
        require(hasRole(PAUSER_ROLE, _msgSender()), "SwapWXPX::Must have pauser role to unpause");
        _unpause();
    }

    // Internal functions
    //
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

    function calcRequestHash(Request memory request) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.nonce
        ));
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash) internal pure {
        require(request.status == RequestStatus.PENDING, "SwapWXPX::Request is not pending");
        require(requestHash == calcRequestHash(request), "SwapWXPX::Request hash does not match a pending request");
    }

    function compareStrings (string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function isEmptyString (string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status) internal pure returns (string memory) {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
            // this fallback can never be reached.
            return "unknown";
        }
    }
    // Private functions
    /**
    * @dev Source of tokens
    * @param _from Address performing the token purchase
    * @param _to Address receiving the token purchase
    * @param _tokenAmount Number of tokens to be transfer
    */
    function _deliverTokensFrom(
        address _from,
        address _to,
        uint256 _tokenAmount
    )
      private
      returns (bool)
    {
      token.transferFrom(_from, _to, _tokenAmount);
      return true;
    }

    function _tokenBurn(uint256 amount) private returns (bool) {
      token.burn(amount);
      return true;
    }

}
