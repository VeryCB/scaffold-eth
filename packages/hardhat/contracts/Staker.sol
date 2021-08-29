pragma solidity >=0.6.0 <0.7.0;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint) public balances;

  uint public deadline;
  uint public threshold = 1 ether;
  bool public openForWithdraw = false;

  event Stake(address indexed sender, uint value);

  constructor(address exampleExternalContractAddress) public {
    deadline = block.timestamp + 30 seconds;
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    require(!exampleExternalContract.completed, 'Failed to stake: contract already completed.')

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public {
    require(block.timestamp >= deadline, 'Cannot execute until deadline is reached.');
    require(!exampleExternalContract.completed, 'Failed to execute: contract already completed.')

    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      // TODO: clear balance mapping
    } else {
      openForWithdraw = true;
    }
  }

  function withdraw(address payable sender) public {
    require(msg.sender == sender, 'Only the owner can withdraw.');
    require(openForWithdraw, 'Withdraw is disabled.');

    uint balance = balances[sender];
    require(balance > 0, 'Nothing to withdraw.');

    bool sent = sender.send(balance);
    require(sent, 'Failed to withdraw.');

    delete balances[sender];
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }
}
