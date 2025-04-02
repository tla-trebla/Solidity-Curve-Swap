# StableSwap

A Solidity implementation of a stable swap AMM (Automated Market Maker) based on the Curve protocol. This implementation supports 3 tokens with equal decimals and uses a constant product formula with an amplification factor to maintain price stability.

## Features

- Support for 3 tokens with equal decimals
- Constant product formula with amplification factor
- Swap functionality with fees
- Add/remove liquidity functionality
- Single token liquidity removal
- Virtual price calculation
- Comprehensive test coverage

## Architecture

The contract uses the following key components:

1. **Math Library**: Provides mathematical functions for calculations
2. **StableSwap Contract**: Main contract implementing the AMM logic
3. **MockERC20**: Test token implementation for testing

### Key Functions

- `swap`: Exchange one token for another
- `addLiquidity`: Add liquidity to the pool
- `removeLiquidity`: Remove liquidity from the pool
- `removeLiquidityOneToken`: Remove liquidity in a single token
- `getVirtualPrice`: Calculate the virtual price of LP tokens

## Development

### Prerequisites

- Foundry
- Solidity 0.8.13
- OpenZeppelin Contracts

### Setup

1. Clone the repository
2. Install dependencies:
   ```bash
   forge install
   ```
3. Build the project:
   ```bash
   forge build
   ```
4. Run tests:
   ```bash
   forge test
   ```

### Testing

The project includes comprehensive tests covering:
- Initial state
- Adding liquidity
- Swapping tokens
- Removing liquidity
- Edge cases and error conditions

## Security Considerations

- The contract uses OpenZeppelin's SafeMath for arithmetic operations
- Fees are applied to prevent price manipulation
- Liquidity removal is protected against slippage
- All external calls are made after state changes

## License

MIT
