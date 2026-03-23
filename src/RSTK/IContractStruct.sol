// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IContractStruct {
    enum MarketState {
        CLOSED,
        OPEN
    }
    enum RequestType {
        MINT,
        BURN
    }
    struct Market {
        uint256 marketId;
        uint256 totalDeposited;
        MarketState state;
    }

    struct Depositor {
        uint256 priceId;
        uint256 amountDeposited;
        uint256 collateralPaid;
        address depositorAddress;
        bool fullfilled;
        RequestType requestType;
    }

    struct Redeemer {
        uint256 priceId;
        uint256 amountToTokenBurned;
        uint256 minCollateralExpected;
        address user;
        bool fullfilled;
        RequestType requestType;
    }

    struct ExtraInfo {
        uint256 precision;
        address aggregator;
        address usdc;
        address srstkTokenAddr;
        address priceOracleAddr;
        address portfolioContractAddr;
        address owner;
    }

    struct RequestConfig {
        string source;
        string[] args;
        bytes[] bytesArgs;
    }

     struct RequestData {
        uint8 donHostedSecretsSlotID;
        uint64 donHostedSecretsVersion;
        uint64 subscriptionId;
        uint32 gasLimit;
        bytes32 donID;
        address router;
        address accessControlAddress;
    }

}
