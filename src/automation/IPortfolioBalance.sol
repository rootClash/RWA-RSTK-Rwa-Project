// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPortfolioBalance {
    struct AccountSnapshot{
        uint256 portfolioBalance;
    }

    function getbalance() external returns(uint256);
}