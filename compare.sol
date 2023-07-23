uint256 private constant _ADDITIONAL_FEED_PRECISION = 1e10;
uint256 private constant _PRECISION = 1e18;
uint256 private constant _LIQUIDATION_THRESHOLD = 50;
uint256 private constant _LIQUIDATION_PRECISION = 100;
uint256 private constant _LIQUIDATION_BONUS = 10;

function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
    //price of ETH (token)
    // $ -> ETH ?? what would be the value of ETH in terms of X dollars?
    // $2000 / ETH

    AggregatorV3Interface priceFeed = AggregatorV3Interface(_spriceFeeds[token]);
    (, int256 price,,,) = priceFeed.latestRoundData();

    return ((usdAmountInWei * _PRECISION) / uint256(price) * _ADDITIONAL_FEED_PRECISION);
    //10 % bonus to the liquidator
}
