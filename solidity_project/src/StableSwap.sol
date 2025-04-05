// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StableSwap {
    // Number of tokens
    uint256 public immutable N;
    // Amplification coefficient multiplied by N^(N - 1)
    // Higher value makes the curve more flat
    // Lower value makes the curve more like constant product AMM
    uint256 public immutable A;
    // 0.03%
    uint256 private constant SWAP_FEE = 300;
    // Liquidity fee is derived from 2 constraints
    // 1. Fee is 0 for adding / removing liquidity that results in a balanced pool
    // 2. Swapping in a balanced pool is like adding and then removing liquidity
    //    from a balanced pool
    // swap fee = add liquidity fee + remove liquidity fee
    uint256 public immutable LIQUIDITY_FEE;
    uint256 private constant FEE_DENOMINATOR = 1e6;

    address[] public tokens;
    // Normalize each token to 18 decimals
    // Example - DAI (18 decimals), USDC (6 decimals), USDT (6 decimals)
    uint256[] private multipliers;
    uint256[] public balances;

    // 1 share = 1e18, 18 decimals
    uint256 private constant DECIMALS = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address[] memory _tokens, uint256[] memory _multipliers) {
        require(_tokens.length == _multipliers.length, "Length mismatch");

        N = _tokens.length;

        uint256 computedA = 1000;
        for (uint256 i = 0; i < N; ++i) {
            computedA *= N;
        }
        A = computedA;

        require(N > 1, "N must be > 1");
        LIQUIDITY_FEE = (SWAP_FEE * N) / (4 * (N - 1));

        tokens = _tokens;
        multipliers = _multipliers;
        balances = new uint256[](N);
    }

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    // Return precision-adjusted balances, adjusted to 18 decimals
    function _xp() private view returns (uint256[] memory xp) {
        xp = new uint256[](N);
        for (uint256 i; i < N; ++i) {
            xp[i] = balances[i] * multipliers[i];
        }
    }

    /**
     * @notice Calculate D, sum of balances in a perfectly balanced pool
     * If balances of x_0, x_1, ... x_(n-1) then sum(x_i) = D
     * @param xp Precision-adjusted balances
     * @return D
     */
    function _getD(uint256[] memory xp) private view returns (uint256) {
        xp = new uint256[](N);
        /*
        Newton's method to compute D
        -----------------------------
        f(D) = ADn^n + D^(n + 1) / (n^n prod(x_i)) - An^n sum(x_i) - D 
        f'(D) = An^n + (n + 1) D^n / (n^n prod(x_i)) - 1

                     (as + np)D_n
        D_(n+1) = -----------------------
                  (a - 1)D_n + (n + 1)p

        a = An^n
        s = sum(x_i)
        p = (D_n)^(n + 1) / (n^n prod(x_i))
        */
        uint256 a = A * N; // An^n

        uint256 s; // x_0 + x_1 + ... + x_(n-1)
        for (uint256 i; i < N; ++i) {
            s += xp[i];
        }

        // Newton's method
        // Initial guess, d <= s
        uint256 d = s;
        uint256 d_prev;
        for (uint256 i; i < 255; ++i) {
            // p = D^(n + 1) / (n^n * x_0 * ... * x_(n-1))
            uint256 p = d;
            for (uint256 j; j < N; ++j) {
                p = (p * d) / (N * xp[j]);
            }
            d_prev = d;
            d = ((a * s + N * p) * d) / ((a - 1) * d + (N + 1) * p);

            if (Math.abs(d, d_prev) <= 1) {
                return d;
            }
        }
        revert("D didn't converge");
    }

    /**
     * @notice Calculate the new balance of token j given the new balance of token i
     * @param i Index of token in
     * @param j Index of token out
     * @param x New balance of token i
     * @param xp Current precision-adjusted balances
     */
    function _getY(uint256 i, uint256 j, uint256 x, uint256[] memory xp)
        private
        view
        returns (uint256)
    {
        xp = new uint256[](N);
        /*
        Newton's method to compute y
        -----------------------------
        y = x_j

        f(y) = y^2 + y(b - D) - c

                    y_n^2 + c
        y_(n+1) = --------------
                   2y_n + b - D

        where:
        b = sum(x_i) + D/A
        c = D^(n+1) / (n^n * prod(x_i))
        */
        uint256 n = N;
        uint256 amp = A;
        uint256 d = _getD(xp);
        
        uint256 sum = 0;
        uint256 c = d;
        uint256 _x = 0;
        
        for (uint256 k = 0; k < n; k++) {
            if (k == i) {
                _x = x;
            } else if (k == j) {
                continue;
            } else {
                _x = xp[k];
            }
            sum += _x;
            c = (c * d) / (n * _x);
        }
        c = (c * d) / (n * amp);
        uint256 b = sum + d / amp;
        
        uint256 y_prev = 0;
        uint256 y = d;
        
        for (uint256 _i = 0; _i < 255; _i++) {
            y_prev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (Math.abs(y, y_prev) <= 1) {
                return y;
            }
        }
        revert("Y didn't converge");
    }

    function getVirtualPrice() external view returns (uint256) {
        uint256[] memory xp = _xp();
        uint256 d = _getD(xp);
        uint256 _totalSupply = totalSupply;
        if (_totalSupply > 0) {
            return (d * 10 ** DECIMALS) / _totalSupply;
        }
        return 0;
    }

    /**
     * @notice Swap dx amount of token i for token j
     * @param i Index of token in
     * @param j Index of token out
     * @param dx Token in amount
     * @param minDy Minimum token out
     */
    function swap(uint256 i, uint256 j, uint256 dx, uint256 minDy)
        external
        returns (uint256 dy)
    {
        require(i != j, "i = j");

        IERC20(tokens[i]).transferFrom(msg.sender, address(this), dx);

        // Calculate dy
        uint256[] memory xp = _xp();
        uint256 x = xp[i] + dx * multipliers[i];

        uint256 y0 = xp[j];
        uint256 y1 = _getY(i, j, x, xp);
        // y0 must be >= y1, since x has increased
        // -1 to round down
        dy = (y0 - y1 - 1) / multipliers[j];

        // Subtract fee from dy
        uint256 fee = (dy * SWAP_FEE) / FEE_DENOMINATOR;
        dy -= fee;
        require(dy >= minDy, "dy < min");

        balances[i] += dx;
        balances[j] -= dy;

        IERC20(tokens[j]).transfer(msg.sender, dy);
    }

    function addLiquidity(uint256[] calldata amounts, uint256 minShares)
        external
        returns (uint256 shares)
    {
        require(amounts.length == N, "Wrong number of amounts");
        
        // calculate current liquidity d0
        uint256 _totalSupply = totalSupply;
        uint256 d0;
        uint256[] memory old_xs = _xp();
        if (_totalSupply > 0) {
            d0 = _getD(old_xs);
        }

        // Transfer tokens in
        uint256[] memory new_xs = new uint256[](N);
        for (uint256 i; i < N; ++i) {
            uint256 amount = amounts[i];
            if (amount > 0) {
                IERC20(tokens[i]).transferFrom(
                    msg.sender, address(this), amount
                );
                new_xs[i] = old_xs[i] + amount * multipliers[i];
            } else {
                new_xs[i] = old_xs[i];
            }
        }

        // Calculate new liquidity d1
        uint256 d1 = _getD(new_xs);
        require(d1 > d0, "liquidity didn't increase");

        // Reccalcuate D accounting for fee on imbalance
        uint256 d2;
        if (_totalSupply > 0) {
            for (uint256 i; i < N; ++i) {
                // TODO: why old_xs[i] * d1 / d0? why not d1 / N?
                uint256 idealBalance = (old_xs[i] * d1) / d0;
                uint256 diff = Math.abs(new_xs[i], idealBalance);
                new_xs[i] -= (LIQUIDITY_FEE * diff) / FEE_DENOMINATOR;
            }

            d2 = _getD(new_xs);
        } else {
            d2 = d1;
        }

        // Update balances
        for (uint256 i; i < N; ++i) {
            balances[i] += amounts[i];
        }

        // Shares to mint = (d2 - d0) / d0 * total supply
        // d1 >= d2 >= d0
        if (_totalSupply > 0) {
            shares = ((d2 - d0) * _totalSupply) / d0;
        } else {
            shares = d2;
        }
        require(shares >= minShares, "shares < min");
        _mint(msg.sender, shares);
    }

    function removeLiquidity(uint256 shares, uint256[] calldata minAmountsOut)
        external
        returns (uint256[] memory amountsOut)
    {
        uint256 _totalSupply = totalSupply;
        uint256 n = N;

        require(minAmountsOut.length == n, "Wrong minAmountsOut length");

        amountsOut = new uint256[](n);

        for (uint256 i; i < N; ++i) {
            uint256 amountOut = (balances[i] * shares) / _totalSupply;
            require(amountOut >= minAmountsOut[i], "out < min");

            balances[i] -= amountOut;
            amountsOut[i] = amountOut;

            IERC20(tokens[i]).transfer(msg.sender, amountOut);
        }

        _burn(msg.sender, shares);
    }

    /**
     * @notice Calculate amount of token i to receive for shares
     * @param shares Shares to burn
     * @param i Index of token to withdraw
     * @return dy Amount of token i to receive
     *         fee Fee for withdraw. Fee already included in dy
     */
    function _calcWithdrawOneToken(uint256 shares, uint256 i)
        private
        view
        returns (uint256 dy, uint256 fee)
    {
        uint256 _totalSupply = totalSupply;
        uint256[] memory xp = _xp();

        // Calculate d0 and d1
        uint256 d0 = _getD(xp);
        uint256 d1 = d0 - (d0 * shares) / _totalSupply;

        // Calculate reduction in y if D = d1
        uint256 y0 = _getY(i, i, xp[i], xp);
        // d1 <= d0 so y must be <= xp[i]
        uint256 dy0 = (xp[i] - y0) / multipliers[i];

        // Calculate imbalance fee, update xp with fees
        uint256 dx;
        for (uint256 j; j < N; ++j) {
            if (j == i) {
                dx = (xp[j] * d1) / d0 - y0;
            } else {
                // d1 / d0 <= 1
                dx = xp[j] - (xp[j] * d1) / d0;
            }
            xp[j] -= (LIQUIDITY_FEE * dx) / FEE_DENOMINATOR;
        }

        // Recalculate y with xp including imbalance fees
        uint256 y1 = _getY(i, i, xp[i], xp);
        // - 1 to round down
        dy = (xp[i] - y1 - 1) / multipliers[i];
        fee = dy0 - dy;
    }

    function calcWithdrawOneToken(uint256 shares, uint256 i)
        external
        view
        returns (uint256 dy, uint256 fee)
    {
        return _calcWithdrawOneToken(shares, i);
    }

    /**
     * @notice Withdraw liquidity in token i
     * @param shares Shares to burn
     * @param i Token to withdraw
     * @param minAmountOut Minimum amount of token i that must be withdrawn
     */
    function removeLiquidityOneToken(
        uint256 shares,
        uint256 i,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        (amountOut,) = _calcWithdrawOneToken(shares, i);
        require(amountOut >= minAmountOut, "out < min");

        balances[i] -= amountOut;
        _burn(msg.sender, shares);

        IERC20(tokens[i]).transfer(msg.sender, amountOut);
    }
}