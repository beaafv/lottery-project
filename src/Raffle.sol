// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private

// view & pure functions

/*
  * @title Raffle
  * @author Beatriz Vieira
  * @notice This contract is a raffle contract
  * @dev It implements chainlink VRFv2.5 and Chainlink Automation
 */

contract Raffle {
  // errors

  error NotEnoughFunds();

  error NotEnoughTime();


  // variables


  uint256 private immutable i_entryFee;
  address payable[] private s_players;
  uint256 private immutable i_interval;
  uint256 private s_lastTimeStamp;

  constructor(uint256 entryFee, uint256 interval) {
    i_entryFee = entryFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
  }

  function enterRaffle() external payable {

    if (msg.value == i_entryFee) {
     revert NotEnoughFunds();
    }

     s_players.push(payable(msg.sender));


  }

  function pickWinner() external {

    if (block.timestamp - s_lastTimeStamp < i_interval)
      revert NotEnoughTime();
  }

  /*  Getter */

  function getEntranceFee() public view returns (uint256) {
    return i_entryFee;
  }

}
