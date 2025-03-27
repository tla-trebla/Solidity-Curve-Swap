pragma solidity ^0.8.13;

import "./AbstractToken.sol";

contract SwapContract {
    AbstractToken public tokenA;
    AbstractToken public tokenB;

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "TokenA and TokenB must be different");
        tokenA = AbstractToken(_tokenA);
        tokenB = AbstractToken(_tokenB);
    }

    function swap(address sender, address recipient, uint256 amount) public {
        require(tokenA.balanceOf(sender) >= amount, "Insufficient TokenA balance");
        require(tokenA.allowance(sender, address(this)) >= amount, "TokenA not approved");
        require(tokenA.transferFrom(sender, address(this), amount), "TokenA transfer failed");

        tokenB.mint(recipient, amount);
    }
}