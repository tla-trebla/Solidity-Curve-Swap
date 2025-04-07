// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import "../src/DummyToken.sol";
import "../src/StableSwap.sol";

contract DeployStableSwap is Script {
    uint256 private constant N = 3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DummyToken dai = new DummyToken("Dai Stablecoin", "DAI");
        DummyToken usdc = new DummyToken("USD Coin", "USDC");
        DummyToken usdt = new DummyToken("Tether USD", "USDT");
        
        address deployer = vm.addr(deployerPrivateKey);
        dai.mint(deployer, 1_000_000e18);
        usdc.mint(deployer, 1_000_000e6);
        usdt.mint(deployer, 1_000_000e6);

        address[] memory tokens = new address[](N);
        tokens[0] = address(dai);
        tokens[1] = address(usdc);
        tokens[2] = address(usdt);
        
        uint256[] memory multipliers = new uint256[](N);
        multipliers[0] = 1;
        multipliers[1] = 1e12;
        multipliers[2] = 1e12;

        StableSwap swap = new StableSwap(tokens, multipliers);
        
        console.log("Deployer address:", deployer);
        console.log("DAI deployed at:", address(dai));
        console.log("USDC deployed at:", address(usdc));
        console.log("USDT deployed at:", address(usdt));
        console.log("StableSwap deployed at:", address(swap));

        vm.stopBroadcast();
    }
}