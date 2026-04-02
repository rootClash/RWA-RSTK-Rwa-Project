// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SRSTKConstant {
    uint256 public constant PRECISION = 1e18;
    uint256 public constant MIN_COLLATERAL_BPS = 15_000;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    string public constant SRC_BUY = "./functions/source/sourceBuy.js";
    string public constant SRC_SELL = "./functions/source/sourceSell.js";
    string public constant SRC_CHECKPRICE = "./functions/source/source.js";
    string public constant SRC_CHECKBALANCEAVL = "./functions/source/sourcePortfolio.js";
    uint256 public constant MINIMUM_DEPSOIT = 10;
}