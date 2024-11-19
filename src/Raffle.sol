// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import {VRFCoordinatorV2Interface} from "../lib/chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

import {VRFConsumerBaseV2} from "../lib/chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

import {VRFV2PlusClient} from "../lib/chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


/*
  * @title Raffle
  * @author Beatriz Vieira
  * @notice This contract is a raffle contract
  * @dev It implements chainlink VRFv2.5 and Chainlink Automation
 */


contract Raffle is VRFConsumerBaseV2 {
  // errors

  error NotEnoughFunds();

  error NotEnoughTime();

  error FailedTransaction();
  error Raffle__closed();

  /* type Declarations
   */

    enum RaffleState {
      OPEN,
      CALCULATING
    }


  // variables


  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  uint256 private immutable i_entryFee;
  uint256 private immutable i_interval;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint32 private immutable i_callbackGasLimit;
  bytes32 private immutable i_keyHash;
  bytes32 private immutable i_extraArgs;


  uint256 private s_lastTimeStamp;
  address payable[] private s_players;
  address private s_recentWinner;

  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  RaffleState private s_raffleState;


  /* Events */

  event Raffle_entered(address indexed player);
  event Raffle__winner(address indexed winner);


  // Chainlink VRF related variables



constructor(

  uint256 entranceFee,
  uint256 interval,
  address vrfCoordinator,
  bytes32 gasLane,
  uint64 subscriptionId,
  uint32 callbackGasLimit,
  bytes32 keyHash,
  ) VRFConsumerBaseV2(vrfCoordinator) {
    i_entryFee = entranceFee;
    i_interval = interval;
    s_lastTimeStamp = block.timestamp;
    i_keyHash = keyHash;
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN;


}

  function enterRaffle() external payable {

    if (msg.value == i_entryFee) {
     revert NotEnoughFunds();
    }

    if (s_raffleState == RaffleState.CALCULATING) {
      revert Raffle__closed();
    }

     s_players.push(payable(msg.sender));


  }

  function pickWinner() external view {

    if (block.timestamp - s_lastTimeStamp < i_interval) {
      revert NotEnoughTime();
    }
        s_raffleState = RaffleState.CALCULATING;

      VRFV2PlusClient.ExtraArgsV1 memory extraArgs = VRFV2PlusClient.ExtraArgsV1({
                  nativePayment: true
              });
              bytes memory extraArgsBytes = VRFV2PlusClient._argsToBytes(extraArgs);


      VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest ( {
          keyHash: i_keyHash,
          subId: i_subscriptionId,
          requestConfirmations: REQUEST_CONFIRMATIONS,
          callbackGasLimit: i_callbackGasLimit,
          numWords: NUM_WORDS,
          extraArgs: extraArgsBytes

        });



  }


  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {

    uint256 randomWinnerIndex = randomWords[0] % s_players.length;
    address payable winner = s_players[randomWinnerIndex];
    s_recentWinner = winner;

    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;


    (bool success, ) = winner.call{value: address(this).balance}("");

    if (!success) {
      revert FailedTransaction();
    }

  }

  /*  Getter */

  function getEntranceFee() public view returns (uint256) {
    return i_entryFee;
  }

}
