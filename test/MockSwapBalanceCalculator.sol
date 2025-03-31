pragma solidity ^0.8.13;

import {SwapBalanceCalculatorInterface} from "../src/SwapBalanceCalculatorInterface.sol";

contract MockSwapBalanceCalculator is SwapBalanceCalculatorInterface {
    function getNewBalance(uint256 tokenIndexA, uint256 tokenIndexB, uint256 convertedAmount, uint256[] memory reserves) external pure override returns (uint256) {
        return reserves[tokenIndexB] + convertedAmount;
    }
}