pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract SwapContract {
    AbstractToken public tokenA;
    AbstractToken public tokenB;

    constructor(address _tokenA, address _tokenB) {
        tokenA = AbstractToken(_tokenA);
        tokenB = AbstractToken(_tokenB);
    }

    function swap(address sender, address recipient, uint256 amount) public {
        require(tokenA.balanceOf(sender) >= amount, "Insufficient TokenA balance");

        require(MockToken(address(tokenA)).transferFrom(sender, address(this), amount), "TokenA transfer failed"); // TODO: Use the production's implemented token later
        
        tokenB.mint(recipient, amount);
    }
}

abstract contract AbstractToken {
    function mint(address to, uint256 amount) public virtual;
    function approve(address spender, uint256 amount) public virtual;
    function balanceOf(address account) public view virtual returns (uint256);
}

contract MockToken is AbstractToken {
    string public name;
    string public symbol;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) public override {
        balances[to] += amount;
    }

    function approve(address spender, uint256 amount) public override {
        allowances[msg.sender][spender] = amount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        return true;
    }
}

contract SwapContractTest is Test {
    function test_Initialization_ShouldStartWithZeroBalances() public {
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");

        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(address(swapContract)), 0, "TokenA balance should start at zero");
        assertEq(tokenB.balanceOf(address(swapContract)), 0, "TokenB balance should start at zero");
    }

    function test_SwapSufficientBalance_BalancesShouldDeductedAndReceived() public {
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");
        SwapContract sut = new SwapContract(address(tokenA), address(tokenB));

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;

        tokenA.mint(addressA, swapAmount);

        assertEq(tokenA.balanceOf(addressA), swapAmount, "Minting failed for addressA");

        vm.prank(addressA);
        tokenA.approve(address(sut), swapAmount);

        vm.prank(addressA);
        sut.swap(addressA, addressB, swapAmount);

        assertEq(tokenA.balanceOf(addressA), 0, "TokenA should be deducted from addressA");
        assertEq(tokenB.balanceOf(addressB), swapAmount, "TokenB should be received by addressB");
    }

    function test_SwapInsufficientBalance_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");
        SwapContract swapContract = new SwapContract(address(tokenA), address(tokenB));

        address addressA = vm.addr(1);
        address addressB = vm.addr(2);
        uint256 swapAmount = 100 * 1e18;

        vm.prank(addressA);
        vm.expectRevert("Insufficient TokenA balance");
        swapContract.swap(addressA, addressB, swapAmount);
    }
}