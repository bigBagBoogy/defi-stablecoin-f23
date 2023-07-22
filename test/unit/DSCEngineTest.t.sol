// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig public helperConfig;

    address ethUsdPriceFeed;
    address weth;

    function setup() external {
        deployer = new DeployDSC(); // we run the deploy script which will run the HelperConfig(), DecentralizedStableCoin(), and the DSCEngine().
        (dsc, dsce, helperConfig) = deployer.run(); //running deploy will return (dsc, dsce, helperConfig) objects. (DecentralizedStableCoin, DSCEngine, HelperConfig)
        (ethUsdPriceFeed,, weth,,) = helperConfig.activeNetworkConfig();
        /**
         * @dev: (ethUsdPriceFeed, ,weth, ,) contains 4 commas. The 1st is an actual comma, the 2nd is "wbtcUsdPriceFeed" the 3rd is "wbtc" and the 4th is "deployerKey".
         */
    }
    ////////////////////
    // price tests ////
    //////////////////

    function testGetUsdValue() public {}
}
