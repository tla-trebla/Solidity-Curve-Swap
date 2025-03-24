pragma solidity ^0.8.13;

abstract contract AbstractToken {
    function mint(address to, uint256 amount) public virtual;
    function approve(address spender, uint256 amount) public virtual;
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function balanceOf(address account) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
}