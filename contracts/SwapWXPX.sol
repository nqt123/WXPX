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

  WXPX public token;

  constructor (WXPX _token) {
    require(address(_token) != address(0), "SwapWXPX::INVALID_TOKEN_ADDRESS");
    token = WXPX(_token);

    _setupRole(CUSTODIAN, msg.sender);
  }

  modifier onlyCustodian() {
    require(hasRole(CUSTODIAN, msg.sender), "SwapWXPX::NOT_AUTHORIZED");
    _;
  }

  // events

  
}
