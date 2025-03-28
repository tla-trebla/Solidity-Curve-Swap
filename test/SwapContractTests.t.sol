pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {AbstractToken} from "../src/AbstractToken.sol";
import {SwapContract} from "../src/SwapContract.sol";
import {MockToken} from "./MockToken.sol";

contract SwapContractTest is Test {
    function test_Initialization_ShouldStartWithZeroBalances() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);

        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(address(swapContract)), 0, "TokenA balance should start at zero");
        assertEq(tokenB.balanceOf(address(swapContract)), 0, "TokenB balance should start at zero");
    }

    function test_SufficientBalance_BalancesShouldDeductedAndMinted() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        SwapContract sut = new SwapContract(address(tokenA), address(tokenB));

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;
        
        vm.startPrank(addressA);
        tokenA.mint(addressA, swapAmount);
        tokenA.approve(address(sut), swapAmount);
        vm.stopPrank();
        assertEq(tokenA.balanceOf(addressA), swapAmount, "Minting did not work");

        vm.prank(addressA);
        tokenA.approve(address(sut), swapAmount);
        assertEq(tokenA.allowance(addressA, address(sut)), swapAmount, "Approval did not work");
        assertEq(tokenA.balanceOf(addressA), swapAmount, "Balance not updated before swap");

        vm.prank(addressA);
        sut.swap(addressA, addressB, swapAmount);

        assertEq(tokenA.balanceOf(addressA), 0, "TokenA should be deducted from addressA");
        assertEq(tokenB.balanceOf(addressB), swapAmount, "TokenB should be received by addressB");
    }

    function test_SufficientBalance_TransferCorrectly() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 18);
        MockToken tokenB = new MockToken("Token B", "TKB", 18);
        SwapContract sut = new SwapContract(address(tokenA), address(tokenB));

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;

        vm.prank(addressA);
        tokenA.mint(addressA, swapAmount);
        assertEq(tokenA.balanceOf(addressA), swapAmount, "Minting did not work");

        tokenB.mint(address(sut), swapAmount);
        assertEq(tokenB.balanceOf(address(sut)), swapAmount, "Contract should have pre-minted tokenB");

        vm.prank(addressA);
        tokenA.approve(address(sut), swapAmount);
        assertEq(tokenA.allowance(addressA, address(sut)), swapAmount, "Approval did not work");

        vm.prank(addressA);
        sut.swap(addressA, addressB, swapAmount);

        assertEq(tokenA.balanceOf(addressA), 0, "TokenA should be deducted from addressA");
        assertEq(tokenB.balanceOf(addressB), swapAmount, "TokenB should be received by addressB");
        assertEq(tokenB.balanceOf(address(sut)), 0, "Contract should have given tokenB to addressB");
    }

    function test_SwapInsufficientBalance_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA", 8);
        MockToken tokenB = new MockToken("Token B", "TKB", 8);
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

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
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

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
        address sender = vm.addr(1);
        address recipient = vm.addr(2);
        uint256 swapAmount = 100;
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

        tokenA.mint(sender, swapAmount);
        
        vm.prank(sender);
        tokenA.approve(address(swapContract), swapAmount);
        
        tokenA.setTransferShouldFail(true);

        vm.expectRevert("MockToken: transferFrom failed");
        swapContract.swap(sender, recipient, swapAmount);
    }

    function test_SwapSameToken_FailToSwap() public {
        MockToken tokenA = new MockToken("TokenA", "TKA", 8);
        vm.expectRevert("TokenA and TokenB must be different");
        
        new SwapContract(address(tokenA), address(tokenA));
    }
}