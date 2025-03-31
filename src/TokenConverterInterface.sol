pragma solidity ^0.8.13;

import "./AbstractToken.sol";

interface TokenConverterInterface {
    function convert(uint256 amount, AbstractToken tokenA, AbstractToken tokenB) external returns(uint256);
}