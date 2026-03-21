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
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract PortfolioBalance is FunctionsClient, ConfirmedOwner {
    /*//////////////////////////////////////////////////////////////
                            TYPE DECLERATION
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 private s_latestRequestId;
    string private s_source;
    string[] private s_args;
    bytes[] private s_bytesArgs;
    IPortfolioBalance.RequestData private s_config;
    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    uint64 immutable i_subscriptionId;
    uint32 immutable i_gasLimit;
    bytes32 immutable i_donID;

    /*//////////////////////////////////////////////////////////////
                                  ERROR
    //////////////////////////////////////////////////////////////*/\
    error PortfolioBalance__RequestIdNotFound();
    error PortfolioBalance__ErrorFromOracle(bytes memory err);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IPortfolioBalance.RequestData memory requestData) FunctionsClient(requestData.router) ConfirmedOwner(requestData.accessControlAddress.owner()) {
        i_donHostedSecretsSlotID = requestData.donHostedSecretsSlotID;
        i_donHostedSecretsVersion = requestData.donHostedSecretsVersion;
        i_subscriptionId = requestData.subscriptionId;
        i_gasLimit = requestData.gasLimit;
        i_donID = requestData.donID;
        s_source = requestData.source;
        s_args = requestData.args;
        s_bytesArgs = requestData.bytesArgs;
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function sendRequest() external returns (bytes32 requestId) {
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
        if(s_latestRequestId != requestId){
            revert PortfolioBalance__RequestIdNotFound();
        }
        if(err.length > 0){
            revert PortfolioBalance__ErrorFromOracle(err); 
        }
        uint256 portFolioBalance = abi.decode(response, (uint256));
        s_config = IPortfolioBalance.AccountSnapshot({
            portfolioBalance: portFolioBalance
        });
        emit PortfolioBalance(portFolioBalance);
    }
}