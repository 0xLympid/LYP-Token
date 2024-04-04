// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {BurnMintERC677} from "./BurnMintERC677.sol";

/**
 * @title TestToken
 */
contract TestToken is BurnMintERC677 {
  constructor() BurnMintERC677("Test Token", "TT", 18, 1e27) {}
}

