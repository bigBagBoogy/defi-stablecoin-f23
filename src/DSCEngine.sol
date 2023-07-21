// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    // Errors
    ///////////////////
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__needsMoreThanZero();
    error DSCEngine__onlyWETHorWBTCAllowed();
    error DSCEngine__TransferFailed();
    error DSCEngine__NotAllowedToken();
    ///////////////////
    // State Variables
    ///////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; //adds 10 zeroes to match in WEI
    uint256 private constant PRECISION = 1e18; //to devide by to get ETH


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

    ///////////////////
    // Modifiers
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

    ///////////////////
    // External Functions
    ///////////////////
    // CEI = checks, executions, interactions
        /*
     * @param amountDscToMint: The amount of DSC you want to mint
     * You can only mint DSC if you have enough collateral (meet the minimum threshold)
     */
    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
s_DSCMinted[msg.sender] += amountDscToMint
//If they minted too much (DSC $150, ETH $100)
_revertIfHealthFactorIsBroken(msg.sender);
//require they have sufficient collateral
//appoint the coins to the user.
//update by emitting "minted(amount, coin, to whom)"
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
///////////////////
    // Public Functions
    ///////////////////

 ///////////////////
    // Private Functions
    ///////////////////


     //////////////////////////////
    // Private & Internal View & Pure Functions
    // Internal _functions _get a _leading _underscore!!!
    //////////////////////////////
function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
totalDscMinted = s_DSCMinted[user]; // pass in user as a key to the totalDscMinted value in the s_DSCMinted mapping.
collateralValueInUsd = getAccountCollateralValue(user);
}

    /*
    * Returns how close to liquidation a user is
    * If a user goes below 1, then they can get liqidated
    */
function _healthFactor(address user) private view {
// need get total DSC minted
// need get total collateral VALUE
(uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
}


function _getUsdValue(address token, uint amount) private view returns (uint256) {

}

    function _revertIfHealthFactorIsBroken(address user) internal view {
// 1. Check health factor (do they have enough collateral?)
// 2. revert if they don't
(uint256 totalDscMinted,/*debt*/ uint256 collateralValueInUsd) = getAccountInformation(user);
    }
        ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////

//there's a _getUsdValue AND a getUsdValue function (without underscore).
// a helper function used internally within the contract to calculate a value, while getUsdValue might be a function designed to provide the calculated USD value to external callers (a public getter function).
    function getUsdValue(address token, uint256 amount /* in WEI*/) external view returns (uint256) {
return _getUsdValue(token, amount);
    }
// Since users need to be able to call this themselves, it's public.
    function getAccountCollateralValue(address user) public view returns(uint256 totalCollateralValueInUsd) {
        // loop through each collateral token in the s_collateralDeposited mapping,  
        // get the amount they have deposited, "deconstruct the elements..."
        // and map it to the price, to get the USD value. I would say 
        for(uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i]; //get token
            uint256 amount = s_collateralDeposited[amount][token]; //look up the amount of tokens they deposited in the s_collateralDeposited mapping.
            totalCollateralValueInUsd += _getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }
    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.latestRoundData(); //returns 5 things, but we only care about the price...Notice it returns an int256, not a uint256!
        // lets say 1 ETH = $1000,
        // The returned value by Chainlink will be 1000 * 10e8
        return (uint256(price) * ADDITIONAL_FEED_PRECISION * amount) / PRECISION // 1000 * 1e8 * 1e10 <- now this has 18 decimals, same as "amount", because "amount" is in Wei.   We then devide it by 1e18 go get "whole" Eth
        // Notice we cast price as a uint256 by using the parentheses.
    }
}
