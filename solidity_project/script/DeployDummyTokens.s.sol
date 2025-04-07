pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import "../src/DummyToken.sol";

contract DeployDummyTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DummyToken dai = new DummyToken("Dai Stablecoin", "DAI");
        DummyToken usdc = new DummyToken("USD Coin", "USDC");
        DummyToken usdt = new DummyToken("Tether USD", "USDT");

        console.log("DAI:", address(dai));
        console.log("USDC:", address(usdc));
        console.log("USDT:", address(usdt));

        vm.stopBroadcast();
    }
}