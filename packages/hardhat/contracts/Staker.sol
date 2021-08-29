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

  function stake() public payable {
    require(!exampleExternalContract.completed, 'Failed to stake: contract already completed.')

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public {
    require(block.timestamp >= deadline, 'Failed to execute: deadline is not reached.');
    require(!exampleExternalContract.completed, 'Failed to execute: contract already completed.')

    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  function withdraw(address payable sender) public {
    require(msg.sender == sender, 'Failed to withdraw: permission denied.');
    require(openForWithdraw, 'Failed to withdraw: withdraw is not open.');

    uint balance = balances[sender];
    require(balance > 0, 'Failed to withdraw: nothing to withdraw.');

    bool sent = sender.send(balance);
    require(sent, 'Failed to withdraw: transfer failed.');

    delete balances[sender];
  }

  function timeLeft() public view returns (uint) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }
}
