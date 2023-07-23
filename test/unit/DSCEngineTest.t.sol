// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig public helperConfig;
    address ethUsdPriceFeed;
    address weth;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;


    function setUp() external {
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

    function testGetUsdValue() public {
        // CEI Checks, Effects, Interactions
        // we have 15eth with a value of 30k
        // if we call the getUsdValue and pass it the token and amount, it should return 30k
        uint256 expectedUsd = 30000e18; // ethAmount = 15e18   15* $2000 = 30.000
        uint256 actualUsd = dsce.getUsdValue(weth, 15e18);
        console.log(actualUsd);
        assertEq(expectedUsd, actualUsd);
    }
    /////////////////////////////////
    // deposit collateral Tests ////
    ///////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL); // address(dsce) is owner here. So the DSCEnging contract = owner.
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank;
    }
function testGetsAccountCollateralValue() public {
    uint256 expectedCollateralUsd = 20000e18;
    vm.startPrank(USER);
    ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
    dsce.depositCollateral(weth, 10e18);
    dsce.getAccountCollateralValue()







}
    function testCalculatesHealthFactorCorrectly() public {}
}
