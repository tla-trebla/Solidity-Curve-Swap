pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AbstractToken} from "../src/AbstractToken.sol";
import {TokenConverter} from "../src/TokenConverter.sol";
import {InvariantCalculator} from "../src/InvariantCalculator.sol";
import {SwapBalanceCalculator} from "../src/SwapBalanceCalculator.sol";
import {SwapContract} from "../src/SwapContract.sol";
import {MockToken} from "./MockToken.sol";
import {MockTokenConverter} from "./MockTokenConverter.sol";
import {MockSwapBalanceCalculator} from "./MockSwapBalanceCalculator.sol";

contract SwapContractTest is Test {
    function test_Initialization_ShouldStartWithZeroBalances() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);

        TokenConverter converter = new TokenConverter();

        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);

        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        assertEq(tokenA.balanceOf(address(swapContract)), 0, "TokenA balance should start at zero");
        assertEq(tokenB.balanceOf(address(swapContract)), 0, "TokenB balance should start at zero");
    }

    function test_SufficientBalance_BalancesShouldDeductedAndMinted() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        TokenConverter converter = new TokenConverter();
        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);

        SwapContract sut = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 10**8;

        vm.startPrank(addressA);
        tokenA.mint(addressA, swapAmount);
        tokenA.approve(address(sut), swapAmount);
        vm.stopPrank();

        assertEq(tokenA.balanceOf(addressA), swapAmount, "Minting did not work");

        assertEq(tokenB.balanceOf(address(sut)), 0, "TokenB should start with zero balance");

        vm.prank(addressA);
        sut.swap(addressA, addressB, swapAmount);

        assertEq(tokenA.balanceOf(addressA), 0, "TokenA should be deducted from addressA");
        assertEq(tokenB.balanceOf(addressB), swapAmount, "TokenB should be minted to addressB");
    }

    function test_SufficientBalance_TransferCorrectly() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 18);
        MockToken tokenB = new MockToken("Token B", "TKB", 18);
        MockTokenConverter converter = new MockTokenConverter();
        MockSwapBalanceCalculator balanceCalculator = new MockSwapBalanceCalculator();
        SwapContract sut = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 5 * 1e18;

        vm.prank(addressA);
        tokenA.mint(addressA, swapAmount);
        assertEq(tokenA.balanceOf(addressA), swapAmount, "Minting did not work");

        uint256 tokenBMintAmount = 1000 * 1e18;
        tokenB.mint(address(sut), tokenBMintAmount);
        assertEq(tokenB.balanceOf(address(sut)), tokenBMintAmount, "Contract should have pre-minted tokenB");

        vm.prank(addressA);
        tokenA.approve(address(sut), swapAmount);
        assertEq(tokenA.allowance(addressA, address(sut)), swapAmount, "Approval did not work");

        vm.prank(addressA);
        sut.swap(addressA, addressB, swapAmount);

        assertEq(tokenA.balanceOf(addressA), 0, "TokenA should be deducted from addressA");
        assertEq(tokenB.balanceOf(addressB), swapAmount * 2, "TokenB should be received by addressB");  // Adjust based on mock converter logic
        assertEq(tokenB.balanceOf(address(sut)), 0, "Contract should have given tokenB to addressB");
    }

    function test_SwapInsufficientBalance_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        TokenConverter converter = new TokenConverter();
        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;

        vm.prank(addressA);
        vm.expectRevert("Insufficient TokenA balance");
        swapContract.swap(addressA, addressB, swapAmount);
    }

    function test_NoApproval_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        TokenConverter converter = new TokenConverter();
        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;

        vm.prank(addressA);
        tokenA.mint(addressA, swapAmount);

        vm.prank(addressA);
        vm.expectRevert("TokenA not approved");
        swapContract.swap(addressA, addressB, swapAmount);
    }

    function test_TransferFail_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        TokenConverter converter = new TokenConverter();
        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);
        address sender = vm.addr(1);
        address recipient = vm.addr(2);
        uint256 swapAmount = 100;
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB), converter, balanceCalculator);

        tokenA.mint(sender, swapAmount);
        
        vm.prank(sender);
        tokenA.approve(address(swapContract), swapAmount);
        
        tokenA.setTransferShouldFail(true);

        vm.expectRevert("MockToken: transferFrom failed");
        swapContract.swap(sender, recipient, swapAmount);
    }

    function test_SwapSameToken_FailToSwap() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 8);
        TokenConverter converter = new TokenConverter();
        uint256 tokenCount = 2;
        InvariantCalculator invariantCalculator = new InvariantCalculator(tokenCount);
        SwapBalanceCalculator balanceCalculator = new SwapBalanceCalculator(invariantCalculator);
        vm.expectRevert("TokenA and TokenB must be different");
        
        new SwapContract(address(tokenA), address(tokenA), converter, balanceCalculator);
    }
}