pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AbstractToken} from "../src/AbstractToken.sol";

contract TokenConverter {
    function convert(uint256 amount, AbstractToken tokenA, AbstractToken tokenB) external view returns(uint256) {
        uint8 decimalsA = tokenA.decimals();
        uint8 decimalsB = tokenB.decimals();

        require(decimalsA > 0 && decimalsB > 0, "Invalid token decimals");

        if (decimalsA == decimalsB) {
            return amount;
        } else if (decimalsA > decimalsB) {
            return amount / (10 ** (decimalsA - decimalsB));
        } else {
            return amount * (10 ** (decimalsB - decimalsA));
        }
    }
}

contract TokenConverterTest is Test {
    function test_Initialization_doesNothing() public {
        assertTrue(address(new TokenConverter()) != address(0));
    }
}