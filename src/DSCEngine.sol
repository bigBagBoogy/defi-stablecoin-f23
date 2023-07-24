// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import {OracleLib, AggregatorV3Interface} from "./libraries/OracleLib.sol";

/*
 * @title DecentralizedStableCoin
 * @author Patrick Collins
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
 * This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by the DSCEngine smart contract.
 */

contract DSCEngine is ReentrancyGuard {
    ///////////////////
    // Errors        //
    ///////////////////
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__needsMoreThanZero();
    error DSCEngine__onlyWETHorWBTCAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();
    ///////////////////
    // State Variables
    ///////////////////

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; //adds 10 zeroes to match in WEI
    uint256 private constant PRECISION = 1e18; //to devide by to get ETH
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // This means you need to be 200% over-collateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant LIQUIDATION_BONUS = 10;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    mapping(address token => address priceFeed) private s_priceFeeds;
    //mapping (who(what => how many))collateralDeposited
    mapping(address user => mapping(address collateralToken => uint256 amount)) private s_collateralDeposited;
    /// @dev Amount of DSC minted by user
    mapping(address user => uint256 amount) private s_DSCMinted;
    DecentralizedStableCoin private immutable i_dsc;
    address[] private s_collateralTokens; // array of all accepted tokens

    ///////////////////
    // Events
    ///////////////////

    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(
        address indexed redeemedFrom, address indexed redeemedTo, address indexed token, uint256 amount
    );

    ///////////////////
    // Modifiers    ///
    ///////////////////

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert DSCEngine__needsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    ///////////////////
    // Functions
    ///////////////////
    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address dscAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        // after the constructor finishes, set the tokenContract address
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //////////////////////
    // External Functions
    //////////////////////
    // CEI = checks, executions, interactions
    function depositCollateralAndMintDsc(
        address tokenCollateralAddress,
        uint256 _amountCollateral,
        uint256 amountDscToMint
    ) external {
        depositCollateral(tokenCollateralAddress, _amountCollateral);
        mintDsc(amountDscToMint);
    }
    /*
     * @param amountDscToMint: The amount of DSC you want to mint
     * You can only mint DSC if you have enough collateral (meet the minimum threshold)
     */

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint; //this line updates the s_DSCMinted mapping
        _revertIfHealthFactorIsBroken(msg.sender); //If they minted too much (DSC $150, ETH $100)
        //require they have sufficient collateral
        //appoint the coins to the user.
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (minted != true) {
            revert DSCEngine__MintFailed();
        } // no event emit needed here. We update s_DSCMinted internally by saying: s_DSCMinted[msg.sender] += amountDscToMint;
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        _burnDsc(amount, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // This would probably never hit...
    }

    /*
     * @param tokenCollateralAddress: The ERC20 token address of the collateral you're depositing
     * @param amountCollateral: The amount of collateral user is depositing
     */
    function depositCollateral(address tokenCollateralAddress, uint256 _amountCollateral)
        public
        moreThanZero(_amountCollateral)
        nonReentrant
        isAllowedToken(tokenCollateralAddress)
    {
        // fill the mapping s_collateralDeposited with 3 things:
        // the user address, what token, and how many tokens
        // then emit event deposited.
        // read from right to left.
        // increases the amount of collateral deposited by the sender (msg.sender)
        // for a specific token (tokenCollateralAddress)
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += _amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, _amountCollateral);
        // IERC20 down here is a function inherited from IERC20.sol
        bool succes = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), _amountCollateral);
        if (!succes) {
            revert DSCEngine__TransferFailed();
        }
    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        public
        moreThanZero(amountCollateral)
        nonReentrant
    {
        _redeemCollateral(msg.sender, msg.sender, tokenCollateralAddress, amountCollateral);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function liquidate(address collateral, address user, uint256 debtToCover)
        external
        moreThanZero(debtToCover)
        nonReentrant
    {
        // need to check health factor of the user
        uint256 startingUserHealthFactor = _healthFactor(user);
        if (startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        // We want to burn their DSC "debt"
        // and take their collateral
        // Bad User: $140 ETH, $100 DSC
        // debtToCover =$100
        // we need a function to calculate how much ETH $100 is.
        // @ETH=$2000   $100 = 0.05 ETH
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // give the liquidator a 10% bonus
        // so we are giving the liquidator $110 of WETH for 100 DSC
        // We should implement a feature to liquidate in the event the protocol is insolvent
        // and sweep extra amounts into a treasury
        // 0.05 * 0.1 = 0.005 means liquidator getting 0.055 WETH
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / 100;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        _redeemCollateral(user, msg.sender, collateral, totalCollateralToRedeem);
        _burnDsc(debtToCover, user, msg.sender);
        uint256 endingUserHealthFactor = _healthFactor(user);
        if (endingUserHealthFactor <= startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    ///////////////////
    // Public Functions
    ///////////////////

    ///////////////////
    // Private Functions
    ///////////////////
    /*
    * @dev low-level function, do not call unless the function calling it is
    * checking for the health factors being broken
    */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom)
        private
        moreThanZero(amountDscToBurn)
    {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool succes = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn); // we let this function first send the DSC to our contract: address(this), before WE burn it.
        if (!succes) {
            revert DSCEngine__TransferFailed();
        }
        i_dsc.burn(amountDscToBurn);
    }

    //////////////////////////////
    // Private & Internal View & Pure Functions
    // Internal _functions _get a _leading _underscore!!!
    //////////////////////////////
    function _getAccountInformation(address user)
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[user]; // pass in user as a key to the totalDscMinted value in the s_DSCMinted mapping.
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    function _redeemCollateral(address from, address to, address tokenCollateralAddress, uint256 amountCollateral)
        private
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);
        bool succes = IERC20(tokenCollateralAddress).transfer(to, amountCollateral);
        if (!succes) {
            revert DSCEngine__TransferFailed();
        }
    }
    /*
    * Returns how close to liquidation a user is (by means of a ratio)
    * If a user goes below 1, then they can get liqidated
    */

    function _healthFactor(address user) private view returns (uint256) {
        // need get total DSC minted
        // need get total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION; // in the case collateralValueInUsd = 1000,  -> 1000*50   /100   = 500
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        // so if above totalDscMinted = 200, the healthfactor would be: 500 / 200 = 2.5
        // the "* PRECISION" part is just there to match the totalDscMinted by multiplying by 10e18
    }

    function _getUsdValue(address token, uint256 amount) private view returns (uint256) {}

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. Check health factor (do they have enough collateral?)
        // 2. revert if they don't
        uint256 userHealthFactor = _healthFactor(user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) revert DSCEngine__BreaksHealthFactor(userHealthFactor);
    }
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions                         /////////
    ////////////////////////////////////////////////////////////////////////////

    // Since users need to be able to call this themselves, it's public.

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token in the s_collateralDeposited mapping,
        // get the amount they have deposited, "deconstruct the elements..."
        // and map it to the price, to get the USD value. I would say
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i]; //get tokens
            uint256 amount = s_collateralDeposited[user][token]; //look up the amount of tokens they deposited in the s_collateralDeposited mapping.
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }
    //there's a _getUsdValue AND a getUsdValue function (without underscore).
    // a helper function used internally within the contract to calculate a value, while getUsdValue might be a function designed to provide the calculated USD value to external callers (a public getter function).

    function getUsdValue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); //returns 5 things, but we only care about the price...Notice it returns an int256, not a uint256!
        // lets say 1 ETH = $1000,
        // The returned value by Chainlink will be 1000 * 10e8
        return (uint256(price) * ADDITIONAL_FEED_PRECISION * amount) / PRECISION; // 1000 * 1e8 * 1e10 <- now this has 18 decimals, same as "amount", because "amount" is in Wei.   We then devide it by 1e18 go get "whole" USD
            // Notice we cast price as a uint256 by using the parentheses.
    } // Since users need to be able to call this themselves, it's public.

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData(); //So staleCheckLatestRoundData is actually correct! At the top we do using OracleLib for AggregatorV3Interface; which means we use the functions in the OracleLib library for our AggregatorV3Interface - and we have access to staleCheckLatestRoundData!
        // $100e18 USD Debt
        // 1 ETH = 2000 USD
        // The returned value from Chainlink will be 2000 * 1e8
        // Most USD pairs have 8 decimals, so we will just pretend they all do
        return ((usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION));
    }
}
