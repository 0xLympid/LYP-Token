// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BurnMintERC677} from "./BurnMintERC677.sol";

/**
 * @title LympidToken
 */
contract LympidToken is BurnMintERC677 {
  constructor() BurnMintERC677("LympidToken", "LYP", 18, 1e27) {}
}

