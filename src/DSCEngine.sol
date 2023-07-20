// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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

    mapping(address token => address priceFeed) private s_priceFeeds;
    //mapping (who(what => how many))collateralDeposited
    mapping(address user => mapping(address collateraltoken => uint256 amount)) private s_collateralDeposited;
    /// @dev Amount of DSC minted by user
    mapping(address user => uint256 amount) private s_DSCMinted;
    DecentralizedStableCoin private immutable i_dsc;

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


require they have sufficient collateral
appoint the coins to the user
update by emitting "minted(amount, coin, to whom)"
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
     //////////////////////////////
    // Private & Internal View & Pure Functions
    //////////////////////////////
    /*
    * Returns how close to liquidation a user is
    * If a user goes below 1, then they can get liqidated
    */
function _healthFactor(address user) private view {
// total DSC minted
// total collateral VALUE
}

    function _revertIfHealthFactorIsBroken(address user) internal view {
// 1. Check health factor (do they have enough collateral?)
// 2. revert if they don't
    }
}
