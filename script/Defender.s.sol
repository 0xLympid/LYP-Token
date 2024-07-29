// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
import {DefenderOptions, TxOverrides} from "openzeppelin-foundry-upgrades/Options.sol";

import {BurnMintERC677} from "../src/token/ERC677/BurnMintERC677.sol";
import {TokenVesting} from "../src/vesting/TokenVesting.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        DefenderOptions memory defenderOpts;
        defenderOpts.useDefenderDeploy = true;
        defenderOpts.skipVerifySourceCode = false;
        defenderOpts.salt = bytes32(block.timestamp); // Change this to something else. Same salt value, deployer address and contract bytecode will result in the same contract address

        uint8 decimals = 18;
        uint256 maxSupply = 100_000_000 * 10**decimals;
        address token = Defender.deployContract("BurnMintERC677.sol", abi.encode("Lympid", "LYP", decimals, maxSupply), defenderOpts);
        console.log("Deployed contract to address", token);

        address vesting = Defender.deployContract("TokenVesting.sol", abi.encode(token), defenderOpts);
        console.log("Deployed contract to address", vesting);
    }
}
