// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ElectionVoting} from "../src/ElectionVoting.sol"; // Import the ElectionVoting contract
import {console} from "forge-std/console.sol";

contract ElectionScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the ElectionVoting contract
        ElectionVoting election = new ElectionVoting();
        console.log("ElectionVoting contract deployed at:", address(election));

        vm.stopBroadcast();
    }
}
