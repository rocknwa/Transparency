// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ElectionVoting} from "../src/ElectionVoting.sol"; // Import the ElectionVoting contract
import {console} from "forge-std/console.sol";

contract ElectionScript is Script {
    //function setUp() public {}

    function run() external {
        // Load deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the ElectionVoting contract
        ElectionVoting election = new ElectionVoting();
        console.log("ElectionVoting deployed at:", address(election));

        // The deployer is automatically the owner and a government official
        console.log("Deployer registered as owner and government official:", deployer);

        vm.stopBroadcast();
    }
}
