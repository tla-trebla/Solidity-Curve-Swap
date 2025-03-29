pragma solidity ^0.8.13;

import "./AbstractToken.sol";
import "./TokenConverter.sol";

contract SwapContract {
    AbstractToken public tokenA;
    AbstractToken public tokenB;
    TokenConverter private converter;

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "TokenA and TokenB must be different");
        tokenA = AbstractToken(_tokenA);
        tokenB = AbstractToken(_tokenB);
        converter = new TokenConverter();
    }

    function swap(address sender, address recipient, uint256 amount) public {
        require(tokenA.balanceOf(sender) >= amount, "Insufficient TokenA balance");
        require(tokenA.allowance(sender, address(this)) >= amount, "TokenA not approved");
        
        uint256 convertedAmount = converter.convert(amount, tokenA, tokenB);
        
        require(tokenA.transferFrom(sender, address(this), amount), "TokenA transfer failed");

        uint256 tokenBBalance = tokenB.balanceOf(address(this));

        if (tokenBBalance >= convertedAmount) {
            require(tokenB.transfer(recipient, convertedAmount), "TokenB transfer failed");
        } else {
            uint256 mintAmount = convertedAmount - tokenBBalance;
            tokenB.mint(recipient, mintAmount);

            if (tokenBBalance > 0) {
                require(tokenB.transfer(recipient, tokenBBalance), "Token transfer failed");
            }
        }
    }
}