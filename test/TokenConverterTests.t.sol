pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AbstractToken} from "../src/AbstractToken.sol";
import {MockToken} from "./MockToken.sol";

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

    function test_SameDecimals_ShouldReturnSameAmount() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 18);
        MockToken tokenB = new MockToken("TokenB", "TKB", 18);
        TokenConverter sut = new TokenConverter();
        uint256 amount = 100 * 1e18;

        uint256 result = sut.convert(amount, tokenA, tokenB);

        assertEq(result, amount, "Conversion should return the same amount");
    }

    function test_TargetLowerDecimal_ShouldDivide() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 18);
        MockToken tokenB = new MockToken("TokenB", "TKB", 6);
        TokenConverter sut = new TokenConverter();
        uint256 amount = 100 * 1e18;

        uint256 result = sut.convert(amount, tokenA, tokenB);

        assertEq(result, 100 * 1e6, "Conversion should scale down");
    }

    function test_TargetHigherDecimal_ShouldMultiply() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 6);
        MockToken tokenB = new MockToken("TokenB", "TKB", 18);
        TokenConverter sut = new TokenConverter();
        uint256 amount = 100 * 1e6;

        uint256 result = sut.convert(amount, tokenA, tokenB);

        assertEq(result, 100 * 1e18, "Conversion should scale up");
    }
}