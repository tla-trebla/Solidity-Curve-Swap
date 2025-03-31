pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvariantCalculator} from "../src/InvariantCalculator.sol";
import {SwapBalanceCalculator} from "../src/SwapBalanceCalculator.sol";

contract SwapBalanceCalculatorTests is Test {
    function test_Init_DoNothing() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);

        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        assertTrue(address(sut) != address(0), "Contract should be deployed successfully");
    }

    function test_ProperTokens_ReturnsProperResult() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);
        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        uint256[] memory initialBalances = new uint256[](expectedTokenCount);
        initialBalances[0] = 1000;
        initialBalances[1] = 2000;
        initialBalances[2] = 3000;

        uint256 tokenInIndex = 0;
        uint256 tokenOutIndex = 1;
        uint256 newBalanceTokenA = 1200;

        uint256 expectedBalanceTokenB = sut.getNewBalance(tokenInIndex, tokenOutIndex, newBalanceTokenA, initialBalances);

        assertGt(expectedBalanceTokenB, 0, "Token B balance should be updated after swap");
    }

    function test_SameInputAndOutputIndex_ShouldRevert() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);
        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        uint256[] memory initialBalances = new uint256[](expectedTokenCount);
        initialBalances[0] = 1000;
        initialBalances[1] = 2000;
        initialBalances[2] = 3000;

        uint256 tokenIndex = 1;
        vm.expectRevert("Cannot swap the same token");
        sut.getNewBalance(tokenIndex, tokenIndex, initialBalances[tokenIndex], initialBalances);
    }

    function test_OutOfBounds_ShouldRevert() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);
        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        uint256[] memory tokenBalances = new uint256[](expectedTokenCount);
        tokenBalances[0] = 100;
        tokenBalances[1] = 200;
        tokenBalances[2] = 300;

        uint256 invalidIndex = expectedTokenCount;

        vm.expectRevert("Invalid token index");
        sut.getNewBalance(invalidIndex, 1, 50, tokenBalances);

        vm.expectRevert("Invalid token index");
        sut.getNewBalance(1, invalidIndex, 50, tokenBalances);
    }

    function test_OneTokenHasHigherBalance_ShouldComputedProperly() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);
        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        uint256[] memory tokenBalances = new uint256[](expectedTokenCount);
        tokenBalances[0] = 100;
        tokenBalances[1] = 10**18;
        tokenBalances[2] = 100;

        uint256 inputTokenIndex = 0;
        uint256 outputTokenIndex = 1;
        uint256 inputAmount = 50;

        uint256 newBalance = sut.getNewBalance(inputTokenIndex, outputTokenIndex, inputAmount, tokenBalances);

        assertTrue(newBalance > 0, "New balance should be computed properly");
    }

    function test_SwappingZeroAmount_ReturnsSameBalance() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);
        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        uint256[] memory tokenBalances = new uint256[](expectedTokenCount);
        tokenBalances[0] = 500;
        tokenBalances[1] = 1000;
        tokenBalances[2] = 750;

        uint256 inputTokenIndex = 0;
        uint256 outputTokenIndex = 1;
        uint256 inputAmount = 0;

        uint256 newBalance = sut.getNewBalance(inputTokenIndex, outputTokenIndex, inputAmount, tokenBalances);

        assertEq(newBalance, tokenBalances[outputTokenIndex], "Balance should remain unchanged when swapping zero tokens.");
    }
}