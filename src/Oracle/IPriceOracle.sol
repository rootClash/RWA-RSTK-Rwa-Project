// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPriceOracle {
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
    function getPrice() external view returns (uint256);
    function setPrice(uint256 newPrice) external;
}
