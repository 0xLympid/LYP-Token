// SPDX-License-Identifier: MIT 
pragma solidity 0.8.25;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IERC677} from "./IERC677.sol";
import {IERC677Receiver} from "./IERC677Receiver.sol";

contract ERC677 is IERC677, ERC20 {
  constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

  /// @inheritdoc IERC677
  function transferAndCall(address to, uint amount, bytes memory data) public returns (bool success) {
    super.transfer(to, amount);
    emit Transfer(msg.sender, to, amount, data);
    if (address(to).code.length > 0) {
      IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
    }
    return true;
  }
}

