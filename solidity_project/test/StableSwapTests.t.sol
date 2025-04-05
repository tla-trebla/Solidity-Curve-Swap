pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {DummyToken} from "../src/DummyToken.sol";
import {StableSwap} from "../src/StableSwap.sol";

contract StableSwapTests is Test {
    function test_DeployContract_Deployed() public {
        DummyToken dai = new DummyToken("Dai Stablecoin", "DAI", 1_000_000e18);
        DummyToken usdc = new DummyToken("USD Coin", "USDC", 1_000_000e6);
        DummyToken usdt = new DummyToken("Tether USD", "USDT", 1_000_000e6);

        address[] memory tokens = new address[](3);
        tokens[0] = address(dai);
        tokens[1] = address(usdc);
        tokens[2] = address(usdt);
        
        uint256[] memory multipliers = new uint256[](3);
        multipliers[0] = 1;
        multipliers[1] = 1e12;
        multipliers[2] = 1e12;

        StableSwap sut = new StableSwap(tokens, multipliers);
        
        assertTrue(address(sut) != address(0));
    }
}