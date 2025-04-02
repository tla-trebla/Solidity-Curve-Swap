// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Math {
    function abs(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x - y : y - x;
    }
} 