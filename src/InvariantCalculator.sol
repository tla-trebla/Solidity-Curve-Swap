pragma solidity ^0.8.13;

contract InvariantCalculator {
    uint256 private tokenCount;
    uint256 private amplificationFactor;

    constructor(uint256 numberOfTokens) {
        require(numberOfTokens > 1, "Pool must have at least 2 tokens");
        tokenCount = numberOfTokens;
        amplificationFactor = 1000 * (numberOfTokens ** (numberOfTokens - 1));
    }

    function getInvariant(uint256[] memory tokenBalances) public view returns (uint256) {
        require(tokenBalances.length == tokenCount, "Incorrect number of balances");

        uint256 adjustedAmplification = amplificationFactor * tokenCount;
        uint256 sumOfBalances;

        for (uint256 i = 0; i < tokenCount; ++i) {
            sumOfBalances += tokenBalances[i];
        }

        if (sumOfBalances == 0) {
            return 0;
        }

        uint256 invariantValue = sumOfBalances;
        uint256 previousInvariantValue;

        for (uint256 iteration = 0; iteration < 255; ++iteration) {
            uint256 productOfBalances = invariantValue;
            for (uint256 j = 0; j < tokenCount; ++j) {
                productOfBalances = (productOfBalances * invariantValue) / (tokenCount * tokenBalances[j]);
            }

            previousInvariantValue = invariantValue;
            invariantValue = ((adjustedAmplification * sumOfBalances + tokenCount * productOfBalances) * invariantValue) /
                         ((adjustedAmplification - 1) * invariantValue + (tokenCount + 1) * productOfBalances);

            if (_absoluteDifference(invariantValue, previousInvariantValue) <= 1) {
                return invariantValue;
            }
        }

        revert("Invariant calculation did not converge");
    }

    function _absoluteDifference(uint256 value1, uint256 value2) private pure returns (uint256) {
        return value1 >= value2 ? value1 - value2 : value2 - value1;
    }

    function getTokenCount() external view returns (uint256) {
        return tokenCount;
    }

    function getAmplificationFactor() external view returns (uint256) {
        return amplificationFactor;
    }
}