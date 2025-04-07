pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import "../src/DummyToken.sol";

contract MintDummyTokens is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        DummyToken dai = new DummyToken("Dai Stablecoin", "DAI");
        DummyToken usdc = new DummyToken("USD Coin", "USDC");
        DummyToken usdt = new DummyToken("Tether USD", "USDT");
        
        dai.mint(0x83d67c55BF60F14a400822363448E692Ca211528, 1_000_000e18);
        usdc.mint(0x702B720867172110B7a1C8448353fa0410da6B17, 1_000_000e6);
        usdt.mint(0xC3EBd2EbE952A00747031E281C4F6edDF1d56A0b, 1_000_000e6);

        vm.stopBroadcast();
    }
}