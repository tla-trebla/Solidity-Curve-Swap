pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract SwapContract {
    address public tokenA;
    address public tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }
}

abstract contract AbstractToken {
    function balanceOf(address account) public view virtual returns (uint256);
}

contract MockToken is AbstractToken {
    string public name;
    string public symbol;
    mapping(address => uint256) private _balances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
}

contract SwapContractTest is Test {
    function test_SwapContract_Initialization_ShouldStartWithZeroBalances() public {
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");
        
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(address(swapContract)), 0, "TokenA balance should start at zero");
        assertEq(tokenB.balanceOf(address(swapContract)), 0, "TokenB balance should start at zero");
    }
}