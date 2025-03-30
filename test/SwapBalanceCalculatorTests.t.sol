pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvariantCalculator} from "../src/InvariantCalculator.sol";

contract SwapBalanceCalculator {
    InvariantCalculator private immutable invariantCalculator;
    uint256 private immutable tokenCount;
    uint256 private immutable amplificationFactor;

    constructor(InvariantCalculator _invariantCalculator) {
        invariantCalculator = _invariantCalculator;
        tokenCount = _invariantCalculator.getTokenCount();
        amplificationFactor = _invariantCalculator.getAmplificationFactor();
    }
    
    function getExpectedBalanceAfterSwap(
        uint256 tokenIn,
        uint256 tokenOut,
        uint256 newBalanceIn,
        uint256[] memory tokenBalances
    ) public view returns (uint256) {
        require(tokenIn != tokenOut, "Cannot swap the same token");
        require(tokenIn < tokenCount && tokenOut < tokenCount, "Invalid token index");
        require(tokenBalances.length == tokenCount, "Incorrect number of balances");

        uint256 aN = amplificationFactor * tokenCount;
        uint256 d = invariantCalculator.getInvariant(tokenBalances);
        uint256 sumBalances;
        uint256 c = d;
        uint256 balanceK;

        for (uint256 k = 0; k < tokenCount; ++k) {
            if (k == tokenIn) {
                balanceK = newBalanceIn;
            } else if (k == tokenOut) {
                continue;
            } else {
                balanceK = tokenBalances[k];
            }

            sumBalances += balanceK;
            c = (c * d) / (tokenCount * balanceK);
        }

        c = (c * d) / (tokenCount * aN);
        uint256 b = sumBalances + d / aN;

        uint256 yPrev;
        uint256 y = d;

        for (uint256 i = 0; i < 255; ++i) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - d);

            if (_absoluteDifference(y, yPrev) <= 1) {
                return y;
            }
        }

        revert("Swap calculation did not converge");
    }

    function _absoluteDifference(uint256 value1, uint256 value2) private pure returns (uint256) {
        return value1 > value2 ? value1 - value2 : value2 - value1;
    }
}

contract SwapBalanceCalculatorTests is Test {
    function test_Init_DoNothing() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator invariantCalculator = new InvariantCalculator(expectedTokenCount);

        SwapBalanceCalculator sut = new SwapBalanceCalculator(invariantCalculator);

        assertTrue(address(sut) != address(0), "Contract should be deployed successfully");
    }
}