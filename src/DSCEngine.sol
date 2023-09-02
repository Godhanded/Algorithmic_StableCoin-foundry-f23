// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DecentralisedStableCoin} from "./DecentralisedStableCoin.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error DSCEngine__TransferFailed();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAndPriceFeedLengthsMustBeSame();

    ///////////////////////
    // State Variables   //
    ///////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    mapping(address user => mapping(address token => uint256 amount))
        private s_collateralDeposited;
    DecentralisedStableCoin private immutable i_decentralisedStableCoin;

    address[] public s_collateralTokens;

    /////////////////
    // Events      //
    /////////////////
    event CollateralDeposited(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    /////////////////
    // Modifiers   //
    /////////////////
    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) revert DSCEngine__NeedsMoreThanZero();
        _;
    }

    modifier isAllowedToken(address _tokenAddress) {
        if (s_priceFeeds[_tokenAddress] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
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
        if (_tokenAddresses.length != _priceFeedAddresses.length) {
            revert DSCEngine__TokenAndPriceFeedLengthsMustBeSame();
        }
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            s_priceFeeds[_tokenAddresses[i]] = _priceFeedAddresses[i];
            s_collateralTokens.push(_tokenAddresses[i]);
        }
        i_decentralisedStableCoin = DecentralisedStableCoin(_dscAddress);
    }

    /////////////////////////
    // External Funcions   //
    /////////////////////////

    function depositCollateralAndMintDSC() external {}

    /**
     *
     * @notice follows CEI(Checks Effects Interactions)
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
    {
        s_collateralDeposited[msg.sender][
            _tokenCollateralAddress
        ] += _amountCollateral;
        emit CollateralDeposited(
            msg.sender,
            _tokenCollateralAddress,
            _amountCollateral
        );
        bool success = IERC20(_tokenCollateralAddress).transferFrom(
            msg.sender,
            address(this),
            _amountCollateral
        );
        if (!success) revert DSCEngine__TransferFailed();
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    /**
     * @notice follows CEI
     * @param _amountDscToMint amount of decentralised stablecoin to mint
     * @notice they must have more collateral value than minimum threshold
     */
    function mintDSC(
        uint256 _amountDscToMint
    ) external moreThanZero(_amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += _amountDscToMint;
        // if they mint too much eg $100 dsc with $100 eth
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    //////////////////////////////////////////
    // Private and Internal view Funcions   //
    //////////////////////////////////////////

    function _getAccountInformation(
        address _user
    )
        private
        view
        returns (uint256 totalDscMinted, uint256 collateralValueInUsd)
    {
        totalDscMinted = s_DSCMinted[_user];
        collateralValueInUsd = getAccountCollateralValue(_user);
    }

    /// @notice returns how close to liquidation a user is
    /// @dev if user goes below 1 they can get liquidated
    /// @param _user address to check
    /// @return healthFactor how close to liquidation a user is
    function _healthFactor(address _user) private view returns (uint256) {
        (
            uint256 totalDscMinted,
            uint256 collateralValueInUsd
        ) = _getAccountInformation(_user);
        return (collateralValueInUsd / totalDscMinted);
    }

    function _revertIfHealthFactorIsBroken(address _user) internal view {}

    //////////////////////////////////////////
    // Public and External view Funcions    //
    //////////////////////////////////////////

    function getAccountCollateralValue(
        address _user
    ) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateraltoken, get the amount they have deposited, map it to price, to get usd value
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[_user][token];
            totalCollateralValueInUsd += getUsdValue(
                s_collateralTokens[i],
                amount
            );
        }
    }

    function getUsdValue(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_priceFeeds[_token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //say 1 eth = $1000
        // returned value from chainlink will be 1000 * 1e8
        return
            ((uint256(price) * ADDITIONAL_FEED_PRECISION) * _amount) /
            PRECISION;
    }
}
