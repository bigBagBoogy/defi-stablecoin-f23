// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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

contract DSCEngine {
    ///////////////////
    // Errors
    ///////////////////
    error DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch();
    error DSCEngine__needsMoreThanZero();
    error DSCEngine__onlyWETHorWBTCAllowed();
     ///////////////////
    // State Variables
    ///////////////////

mapping(address token => address priceFeed) private s_priceFeeds;


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
        address weth = 00xbb9bc244d798123fde783fcc1c72d3bb8c189413;
        address wbtc = 0x0164431354;
        if (tokenSent != weth || wbtc) {
            revert DSCEngine__onlyWETHorWBTCAllowed();
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
    }

    ///////////////////
    // External Functions
    ///////////////////

    function depositCollateral(
        address tokenCollateralAddress,
        uint256 _amountCollateral
    ) external moreThanZero(_amountCollateral) {}
}
