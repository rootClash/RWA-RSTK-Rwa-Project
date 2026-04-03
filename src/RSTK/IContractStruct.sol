// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IContractStruct {
    enum MarketState {
        CLOSED,
        OPEN
    }
    enum RequestType {
        NONE,
        MINT,
        BURN,
        DONE
    }

    enum RequestForSource{
        BUY,
        SELL
    }
    struct Market {
        uint256 marketId;
        uint256 totalDeposited;
        MarketState state;
    }

    struct Depositor {
        bool fullfilled;
        bytes32 priceId;
        address depositorAddress;
        uint256 amountToMint;
        uint256 collateralPaid;
        uint256 notionalAmount;
    }

    struct Redeemer {
        bool fullfilled;
        bytes32 priceId;
        address user;
        uint256 amountToTokenBurned;
        uint256 minCollateralExpected;
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
