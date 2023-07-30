// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "@openzeppelin/contracts/token//ERC20/IERC20.sol";
import {Handler} from "test/fuzz/Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig helperConfig;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    Handler handler;

    function setUp() external {
        deployer = new DeployDSC(); // we run the deploy script which will run the HelperConfig(), DecentralizedStableCoin(), and the DSCEngine().
        (dsc, dsce, helperConfig) = deployer.run(); //running deploy will return (dsc, dsce, helperConfig) objects. (DecentralizedStableCoin, DSCEngine, HelperConfig)
        targetContract(address(handler));
        (ethUsdPriceFeed,, weth, wbtc,) = helperConfig.activeNetworkConfig();
    }

    function invariant_ProtocolMustHaveMoreThanTotalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));
        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("totalSupply:", totalSupply);
        console.log("totalWethDeposited:", totalWethDeposited);
        console.log("totalWbtcDeposited:", totalWbtcDeposited);
        console.log("wethValue:", wethValue);
        console.log("wbtcValue:", wbtcValue);

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
