pragma solidity ^0.8.13;

import {AbstractToken} from "../src/AbstractToken.sol";
import {TokenConverterInterface} from "../src/TokenConverterInterface.sol";

contract MockTokenConverter is TokenConverterInterface {
    function convert(uint256 amount, AbstractToken tokenA, AbstractToken tokenB) external pure override returns (uint256) {
        return amount * 2;
    }
}