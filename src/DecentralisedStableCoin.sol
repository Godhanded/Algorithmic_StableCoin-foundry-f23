// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DecentralisedStableCoin
 * @author Godand
 * Collateral: Exogenouge(BTC & ETH)
 * Minting: Algorithmic
 * Relative Stability: Pegged in USD
 * 
 * This Contract is governed by DSCEngine. This is just the ERC20 implementation of the StableCoin.
 * 
 */
contract DecentralisedStableCoin is ERC20Burnable,Ownable{
    error DecentralisedStableCoin_NotZeroAddress();
    error DecentralisedStableCoin__MustBeMoreThanZero();
    error DecentralisedStableCoin__BurnAmountExceedsBalance();
    
    constructor() ERC20("DescentralisedStableCoin","DSC"){}

    function burn(uint256 _amount)public override onlyOwner{
            uint256 balance = balanceOf(msg.sender);
            if(_amount <= 0) revert DecentralisedStableCoin__MustBeMoreThanZero();

            if(balance <_amount) revert DecentralisedStableCoin__BurnAmountExceedsBalance();
            super.burn(_amount);
        }
    
    function mint(address _to, uint256 _amount)external onlyOwner returns(bool){
        if(_to==address(0)) revert DecentralisedStableCoin_NotZeroAddress();
        if(_amount<=0) revert DecentralisedStableCoin__MustBeMoreThanZero();
        _mint(_to,_amount);
        return true;
    }

}