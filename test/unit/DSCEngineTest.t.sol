// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract DSCEngineTest is StdCheats, Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig public helperConfig;
    address ethUsdPriceFeed;
    address weth;

    address public user = address(1);
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        deployer = new DeployDSC(); // we run the deploy script which will run the HelperConfig(), DecentralizedStableCoin(), and the DSCEngine().
        (dsc, dsce, helperConfig) = deployer.run(); //running deploy will return (dsc, dsce, helperConfig) objects. (DecentralizedStableCoin, DSCEngine, HelperConfig)
        (ethUsdPriceFeed,, weth,,) = helperConfig.activeNetworkConfig();
        if (block.chainid == 31337) {
            vm.deal(user, STARTING_USER_BALANCE);
        }
        /**
         * @dev: (ethUsdPriceFeed, ,weth, ,) contains 4 commas. The 1st is an actual comma, the 2nd is "wbtcUsdPriceFeed" the 3rd is "wbtc" and the 4th is "deployerKey".
         */
    }
    ////////////////////
    // price tests ////
    //////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18; // but really it's Ethereum-WEI
        // CEI Checks, Effects, Interactions
        // we have 15eth with a value of 30k
        // if we call the getUsdValue and pass it the token and amount, it should return 30k
        uint256 expectedUsd = 30000e18; // 15* $2000 = 30.000 30000e18 in DCS-WEI
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        console.log("amount of Ethereum-WEI:", ethAmount);
        console.log("actualUsd:", actualUsd);
        assertEq(expectedUsd, actualUsd);
    }

    /////////////////////////////////
    // deposit collateral Tests ////
    ///////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL); // address(dsce) is owner here. So the DSCEnging contract = owner.
        vm.expectRevert(DSCEngine.DSCEngine__needsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank;
    }

    /* @dev: I pasted the ERC20.sol _approve function here to get some insight
    *    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }*/

    function testGetCollateralBalanceOfUser() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        uint256 collateralBalance = dsce.getCollateralBalanceOfUser(user, weth);
        assertEq(collateralBalance, AMOUNT_COLLATERAL);
    }

    // below an AI generated test
    function testGetCollateralBalanceOfUserAi() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        // Check user's initial balance
        uint256 initialBalance = ERC20Mock(weth).balanceOf(user);
        console.log(initialBalance);
        require(initialBalance >= AMOUNT_COLLATERAL, "Insufficient balance for deposit");

        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);

        // Verify that the user's balance has been reduced after the deposit
        uint256 finalBalance = ERC20Mock(weth).balanceOf(user);
        assertEq(finalBalance, initialBalance - AMOUNT_COLLATERAL);

        uint256 collateralBalance = dsce.getCollateralBalanceOfUser(user, weth);
        assertEq(collateralBalance, AMOUNT_COLLATERAL);
    }

    function testGetAccountCollateralValue() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        uint256 collateralValue = dsce.getAccountCollateralValue(user);
        uint256 expectedCollateralValue = dsce.getUsdValue(weth, AMOUNT_COLLATERAL);
        assertEq(collateralValue, expectedCollateralValue);
    }

    function testCalculatesHealthFactorCorrectly() public {}

    //////////////////
    // Price Tests //
    //////////////////

    function testGetTokenAmountFromUsd() public {
        // If we want $100 of WETH @ $2000/WETH, that would be 0.05 WETH
        uint256 expectedWeth = 0.05 ether; // this ether here is Ethereum ether
        uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether); // 100 ether here is $100 worth of the 1 - 1 stablecoins (called "ether" here) and this is not 100 ETH!!!!
        assertEq(amountWeth, expectedWeth);
        console.log("amountWeth:", amountWeth, "expectedWeth:", expectedWeth);
    }

    // bigBagBoogy audit test:
}
