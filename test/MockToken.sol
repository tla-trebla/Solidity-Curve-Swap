pragma solidity ^0.8.13;

import {AbstractToken} from "../src/AbstractToken.sol";

contract MockToken is AbstractToken {
    mapping(address => mapping(address => uint256)) private allowances;
    bool private transferShouldFail = false;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) AbstractToken(_name, _symbol, decimals_) {}

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

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(!transferShouldFail, "MockToken: transfer failed");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        return true;
    }
}