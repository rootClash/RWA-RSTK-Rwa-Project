// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPortfolioBalance {
    struct AccountSnapshot{
        uint256 portfolioBalance;
    }

    struct RequestData {
        string source;
        uint8 donHostedSecretsSlotID;
        uint64 donHostedSecretsVersion;
        string[] args;
        bytes[] bytesArgs;
        uint64 subscriptionId;
        uint32 gasLimit;
        bytes32 donID;
        address router;
        address accessControlAddress;
    }

    function getbalance() external returns(uint256);
}