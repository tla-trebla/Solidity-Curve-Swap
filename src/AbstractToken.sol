pragma solidity ^0.8.13;

abstract contract AbstractToken {
    string public name;
    string public symbol;
    uint8 private _decimals;
    mapping(address => uint256) public balances;

    constructor(string memory _name, string memory _symbol, uint8 decimals_) {
        name = _name;
        symbol = _symbol;
        _decimals = decimals_;
    }

    function mint(address to, uint256 amount) public virtual;
    function approve(address spender, uint256 amount) public virtual;
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function balanceOf(address account) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
    function decimals() public view returns(uint8) {
        return _decimals;
    }
}