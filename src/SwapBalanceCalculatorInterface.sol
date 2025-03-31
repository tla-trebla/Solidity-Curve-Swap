pragma solidity ^0.8.13;

interface SwapBalanceCalculatorInterface {
    function getNewBalance(
        uint256 tokenInIndex,
        uint256 tokenOutIndex,
        uint256 newBalanceTokenIn,
        uint256[] memory tokenBalances
    ) external view returns (uint256 newBalanceTokenOut);
}