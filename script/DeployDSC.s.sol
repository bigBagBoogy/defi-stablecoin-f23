// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract DeployDSC is Script {
    function run() external returns (DecentralizedStableCoin, DSCEngine, HelperConfig) {}
vm.startBroadcast();
DecentralizedStableCoin dsc = new DecentralizedStableCoin();
DSCEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
vm.stopBroadcast();
    constructor() {}
}
