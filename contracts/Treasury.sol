// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
  struct TreasuryRecord {
      uint256 value;
      uint256 timestamp;
      uint256 hydroPaid;
  }

  TreasuryRecord[] public treasuryRecords;

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
    treasuryRecords.push(TreasuryRecord(treasuryRecords.length + 1, block.timestamp, balance));
  }

  function viewBalance() public view returns (uint256) {
    return address(this).balance;
  }
}