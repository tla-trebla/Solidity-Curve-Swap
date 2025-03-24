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
        require(tokenA.allowance(sender, address(this)) >= amount, "TokenA not approved");
        require(tokenA.transferFrom(sender, address(this), amount), "TokenA transfer failed");

        tokenB.mint(recipient, amount);
    }
}

abstract contract AbstractToken {
    function mint(address to, uint256 amount) public virtual;
    function approve(address spender, uint256 amount) public virtual;
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function balanceOf(address account) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
}

contract MockToken is AbstractToken {
    string public name;
    string public symbol;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    bool private transferShouldFail = false;

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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function setTransferShouldFail(bool shouldFail) public {
        transferShouldFail = shouldFail;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");
        require(!transferShouldFail, "MockToken: transferFrom failed");

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

    function test_NoApproval_FailToSwap() public {
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");
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
        MockToken tokenA = new MockToken("Token A", "TKA");
        MockToken tokenB = new MockToken("Token B", "TKB");
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
}