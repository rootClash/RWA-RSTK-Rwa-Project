// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IContractStruct {
    enum MarketState {
        CLOSED,
        OPEN
    }
    enum userRequest {
        MINT,
        BURN
    }
    enum RequestType {
        PORTFOLIO,
        MINT,
        BURN
    }
    struct Market {
        uint256 marketId;
        uint256 totalDeposited;
        MarketState state;
    }

    struct Depositor {
        uint256 amountDeposited;
        uint256 priceId;
        address depositorAddress;
    }

    struct Redeemer {
        uint256 amountToTokenBurned;
        uint256 priceId;
        address user;
        RequestType requestType;
    }

    struct ExtraInfo {
        uint256 precision;
        address aggregator;
        address usdc;
        address srstkTokenAddr;
        address priceOracleAddr;
    }

    struct RequestConfig {
        string source;
        string[] args;
        bytes[] bytesArgs;
    }
}
