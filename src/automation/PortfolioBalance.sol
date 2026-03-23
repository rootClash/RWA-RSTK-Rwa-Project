// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    ConfirmedOwner
} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {
    FunctionsClient
} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {
    FunctionsRequest
} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IPortfolioBalance} from "../automation/IPortfolioBalance.sol";
import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IContractStruct} from "../RSTK/IContractStruct.sol";

contract PortfolioBalance is FunctionsClient, ConfirmedOwner {
    /*//////////////////////////////////////////////////////////////
                            TYPE DECLERATION
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    bytes32 private s_latestRequestId;
    string private s_source;
    string[] private s_args;
    bytes[] private s_bytesArgs;
    IPortfolioBalance.AccountSnapshot private s_config;
    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    uint64 immutable i_subscriptionId;
    uint32 immutable i_gasLimit;
    bytes32 immutable i_donID;
    uint256 private s_lastTimestamp;
    uint256 private s_interaval = 43200;

    event PortfolioBalanceUpdated(uint256 newBalance);

    /*//////////////////////////////////////////////////////////////
                                  ERROR
    //////////////////////////////////////////////////////////////*/
    error PortfolioBalance__RequestIdNotFound();
    error PortfolioBalance__ErrorFromOracle(bytes err);
    error PortfolioBalance__UpkeepNotNeeded();
    error PortfolioBalance__RequestIdAlreadyExist();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address owner,
        IContractStruct.RequestData memory requestData,
        IContractStruct.RequestConfig memory config
    ) FunctionsClient(requestData.router) ConfirmedOwner(owner) {
        i_donHostedSecretsSlotID = requestData.donHostedSecretsSlotID;
        i_donHostedSecretsVersion = requestData.donHostedSecretsVersion;
        i_subscriptionId = requestData.subscriptionId;
        i_gasLimit = requestData.gasLimit;
        i_donID = requestData.donID;
        s_source = config.source;
        s_args = config.args;
        s_bytesArgs = config.bytesArgs;
        s_lastTimestamp = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function sendRequest() public returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_source);
        req.addDONHostedSecrets(
            i_donHostedSecretsSlotID,
            i_donHostedSecretsVersion
        );
        if (s_args.length > 0) req.setArgs(s_args);
        if (s_bytesArgs.length > 0) req.setBytesArgs(s_bytesArgs);
        requestId = _sendRequest(
            req.encodeCBOR(),
            i_subscriptionId,
            i_gasLimit,
            i_donID
        );
        s_latestRequestId = requestId;
    }
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_latestRequestId != requestId) {
            revert PortfolioBalance__RequestIdNotFound();
        }
        if (err.length > 0) {
            revert PortfolioBalance__ErrorFromOracle(err);
        }
        uint256 portFolioBalance = abi.decode(response, (uint256));
        s_config = IPortfolioBalance.AccountSnapshot({
            portfolioBalance: portFolioBalance
        });
        emit PortfolioBalanceUpdated(portFolioBalance);
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) internal returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool checkTime = (block.timestamp - s_lastTimestamp) >= s_interaval;
        upkeepNeeded = checkTime;
        s_lastTimestamp = block.timestamp;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata performData) external {
        (bool upkeepNeeded, ) = checkUpkeep(performData);
        if (!upkeepNeeded) {
            revert PortfolioBalance__UpkeepNotNeeded();
        }
        bytes32 requestId = sendRequest();
        if (requestId == s_latestRequestId) {
            revert PortfolioBalance__RequestIdAlreadyExist();
        }
        s_latestRequestId = requestId;
    }

    function getbalance() external returns (uint256) {
        return s_config.portfolioBalance;
    }
}
