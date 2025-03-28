pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenConverter} from "../src/TokenConverter.sol";
import {MockToken} from "./MockToken.sol";

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

    function test_InvalidDecimals_ShouldRevert() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 0);
        MockToken tokenB = new MockToken("TokenB", "TKB", 18);
        TokenConverter sut = new TokenConverter();
        uint256 amount = 100 * 1e18;

        vm.expectRevert("Invalid token decimals");
        sut.convert(amount, tokenA, tokenB);
    }
}