pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {InvariantCalculator} from "../src/InvariantCalculator.sol";

contract InvariantCalculatorTest is Test {
    function test_Initialization_ShouldDoNothing() public {
        uint256 expectedTokenCount = 3;
        
        InvariantCalculator sut = new InvariantCalculator(expectedTokenCount);
        assertTrue(address(sut) != address(0), "Deployment failed");

        assertEq(sut.getTokenCount(), expectedTokenCount, "Token count mismatch");
        uint256 expectedAmplificationFactor = 1000 * (expectedTokenCount ** (expectedTokenCount - 1));
        assertEq(sut.getAmplificationFactor(), expectedAmplificationFactor, "Amplification factor mismatch");
    }

    function test_GetInvariant_ShouldReturnCorrectInvariant() public {
        uint256[] memory balances = new uint256[](3);
        balances[0] = 1000 * 1e18;
        balances[1] = 2000 * 1e18;
        balances[2] = 3000 * 1e18;
        
        InvariantCalculator sut = new InvariantCalculator(balances.length);

        uint256 invariant = sut.getInvariant(balances);

        uint256 expectedInvariant = 5999925937812179024969;
        assertEq(invariant, expectedInvariant, "Invariant calculation is incorrect");
    }

    function test_ImbalancedReserves_ShouldRevertOnNonConvergence() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator calculator = new InvariantCalculator(expectedTokenCount);

        uint256[] memory imbalancedReserves = new uint256[](expectedTokenCount);
        imbalancedReserves[0] = 1e18;
        imbalancedReserves[1] = 1;    
        imbalancedReserves[2] = 1;    

        vm.expectRevert("Invariant calculation did not converge");
        calculator.getInvariant(imbalancedReserves);
    }

    function test_ZeroBalances_ShouldReturnZeroWhenAllBalancesAreZero() public {
        uint256 expectedTokenCount = 3;
        InvariantCalculator calculator = new InvariantCalculator(expectedTokenCount);

        uint256[] memory zeroBalances = new uint256[](expectedTokenCount);
        for (uint256 i = 0; i < expectedTokenCount; i++) {
            zeroBalances[i] = 0;
        }

        uint256 invariant = calculator.getInvariant(zeroBalances);
        assertEq(invariant, 0, "Invariant should be zero when all balances are zero");
    }
}