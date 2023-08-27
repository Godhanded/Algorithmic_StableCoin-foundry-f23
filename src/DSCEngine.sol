// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title DSCEngine
 * @author Godand
 * @notice This sstem is designed to be as minimal as possibleand have the token maintain 1 token==1 dollar peg
 * Has the follwing characteristics
 * - Exogenous Collateral
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * similar to DAI if DAI has no governance no fees and only backed by wETH and WBTC
 *
 * The DSC system Should always be overCollaterised. value of all collateral should never be <= $ value of all DSC
 *
 * @notice This is the core of the DSC system.handles logic for mining and redeeming DSC as well as depositing and withdrawing collateral
 *
 * @notice Tis contract isvery loosely based on the MakerDAO DSS (DAI) system.
 */
contract DSCEngine is ReentrancyGuard {
    /////////////////
    // Errors      //
    /////////////////
    error DSCEngine__NotAllowedToken();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAndPriceFeedLengthsMustBeSame();

    ///////////////////////
    // State Variables   //
    ///////////////////////
    mapping(address token => address priceFeed) private s_priceFeeds;
    DecentralisedStableCoin private immutable i_decentralisedStableCoin;

    /////////////////
    // Modifiers   //
    /////////////////
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) revert DSCEngine__NeedsMoreThanZero();
        _;
    }

    modifier isAllowedToken(address _tokenAddress) {
        if (s_priceFeeds[_tokenAddress] == address(0))
            revert DSCEngine__NotAllowedToken();
        _;
    }

    /////////////////
    // Functions   //
    /////////////////
    constructor(
        address[] memory _tokenAddresses,
        address[] memory _priceFeedAddresses,
        address _dscAddress
    ) {
        if (_tokenAddresses.length != _priceFeedAddresses.length)
            revert DSCEngine__TokenAndPriceFeedLengthsMustBeSame();
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
        }
        i_decentralisedStableCoin = DecentralisedStableCoin(_dscAddress);
    }

    /////////////////////////
    // External Funcions   //
    /////////////////////////

    function depositCollateralAndMintDSC() external {}

    /**
     *
     * @param _tokenCollateralAddress Address of token to be deposited as collateral
     * @param _amountCollateral Amount of token to be deposited as collateral
     */
    function depositCollateral(
        address _tokenCollateralAddress,
        uint256 _amountCollateral
    )
        external
        isAllowedToken(_tokenCollateralAddress)
        moreThanZero(_amountCollateral)
        nonReentrant
    {}

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    function mintDSC() external {}

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
