pragma solidity ^0.8.13;

import "./AbstractToken.sol";
import "./TokenConverterInterface.sol";
import "./SwapBalanceCalculatorInterface.sol";
import "forge-std/console.sol";

contract SwapContract {
    AbstractToken public tokenA;
    AbstractToken public tokenB;
    TokenConverterInterface private converter;
    SwapBalanceCalculatorInterface private calculator;

    constructor(address _tokenA, address _tokenB, TokenConverterInterface _converter, SwapBalanceCalculatorInterface _calculator) {
        require(_tokenA != _tokenB, "TokenA and TokenB must be different");
        tokenA = AbstractToken(_tokenA);
        tokenB = AbstractToken(_tokenB);
        converter = _converter;
        calculator = _calculator;
    }

    function swap(address sender, address recipient, uint256 amount) public {
        require(tokenA.balanceOf(sender) >= amount, "Insufficient TokenA balance");
        require(tokenA.allowance(sender, address(this)) >= amount, "TokenA not approved");
        require(tokenA.transferFrom(sender, address(this), amount), "TokenA transfer failed");

        uint256 convertedAmount = converter.convert(amount, tokenA, tokenB);
        require(convertedAmount > 0, "Converted amount should not be zero");

        uint256 tokenABalance = tokenA.balanceOf(address(this));
        uint256 tokenBBalance = tokenB.balanceOf(address(this));

        uint256[] memory reserves = new uint256[](2);
        reserves[0] = tokenABalance;
        reserves[1] = tokenBBalance;

        require(reserves[0] > 0, "Reserves should be initialized");

        uint256 amountToTransfer;
        if (reserves[1] == 0) {
            amountToTransfer = convertedAmount;
        } else {
            uint256 newTokenBBalance = calculator.getNewBalance(0, 1, convertedAmount, reserves);
            console.log("tokenBBalance: ", tokenBBalance);
            console.log("newTokenBBalance: ", newTokenBBalance);

            if (tokenBBalance > 0) {
                require(newTokenBBalance < tokenBBalance, "New balance must be lower than the current balance");
            }

            if (tokenBBalance > newTokenBBalance) {
                uint256 difference = tokenBBalance - newTokenBBalance;
                uint256 multiplier = 10 ** uint256(tokenB.decimals());
                amountToTransfer = difference / multiplier;

                if (amountToTransfer == 0 && difference > 0) {
                    amountToTransfer = 1;
                }
            } else {
                amountToTransfer = 0;
            }
        }

        if (tokenBBalance >= amountToTransfer) {
            require(tokenB.transfer(recipient, amountToTransfer), "TokenB transfer failed");
        } else {
            uint256 mintAmount = amountToTransfer - tokenBBalance;
            tokenB.mint(recipient, mintAmount);
        }
    }
}