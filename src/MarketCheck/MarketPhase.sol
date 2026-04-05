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
import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IContractStruct} from "../RSTK/IContractStruct.sol";

/// @title MarketPhase
/// @notice Automates fetching the stock market phase using Chainlink Functions and Chainlink Automation.
contract MarketPhase is FunctionsClient, ConfirmedOwner, AutomationCompatibleInterface {
    using FunctionsRequest for FunctionsRequest.Request;

    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 public s_marketOpenTime;
    uint256 public s_marketCloseTime;
    uint256 public s_lastUpkeepTimeStamp;
    uint256 public s_upkeepInterval;

    string private s_source;
    string[] private s_args;
    bytes[] private s_bytesArgs;
    bytes32 private s_latestRequestId;
    bool public s_marketState;
    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    uint64 immutable i_subscriptionId;
    uint32 immutable i_gasLimit;
    bytes32 immutable i_donID;

    /*//////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////*/
    event MarketPhaseUpdated(uint256 openTime, uint256 closeTime, uint256 timestamp);
    event MarketPhaseRequestSent(bytes32 indexed requestId);
    event UpkeepIntervalUpdated(uint256 newInterval);

    /*//////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////*/
    error MarketPhase__UpkeepNotNeeded();
    error MarketPhase__UnexpectedRequestId();
    error MarketPhase__OracleError(string err);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address confirmedOwner,
        IContractStruct.RequestData memory requestData,
        IContractStruct.RequestConfig memory config,
        uint256 upkeepInterval
    ) FunctionsClient(requestData.router) ConfirmedOwner(confirmedOwner) {
        s_source = config.source;
        i_donHostedSecretsSlotID = requestData.donHostedSecretsSlotID;
        i_donHostedSecretsVersion = requestData.donHostedSecretsVersion;
        s_args = config.args;
        s_bytesArgs = config.bytesArgs;
        i_subscriptionId = requestData.subscriptionId;
        i_gasLimit = requestData.gasLimit;
        i_donID = requestData.donID;
        
        s_upkeepInterval = upkeepInterval;
        s_lastUpkeepTimeStamp = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                AUTOMATION
    //////////////////////////////////////////////////////////////*/
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - s_lastUpkeepTimeStamp) > s_upkeepInterval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if ((block.timestamp - s_lastUpkeepTimeStamp) <= s_upkeepInterval) {
            revert MarketPhase__UpkeepNotNeeded();
        }
        s_lastUpkeepTimeStamp = block.timestamp;
        
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_source);
        req.addDONHostedSecrets(i_donHostedSecretsSlotID, i_donHostedSecretsVersion);
        
        if (s_args.length > 0) req.setArgs(s_args);
        if (s_bytesArgs.length > 0) req.setBytesArgs(s_bytesArgs);
        
        s_latestRequestId = _sendRequest(req.encodeCBOR(), i_subscriptionId, i_gasLimit, i_donID);
        
        emit MarketPhaseRequestSent(s_latestRequestId);
    }

    /*//////////////////////////////////////////////////////////////
                            CHAINLINK FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (s_latestRequestId != requestId) {
            revert MarketPhase__UnexpectedRequestId();
        }
        if (err.length > 0) {
            revert MarketPhase__OracleError(string(err));
        }
        (bool state , uint256 marketOpenTime , uint256 marketCloseTime) = abi.decode(response, (bool,uint256 , uint256));
        s_marketOpenTime = marketOpenTime;
        s_marketCloseTime = marketCloseTime;
        s_marketState = state;
        emit MarketPhaseUpdated(marketOpenTime, marketCloseTime, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL ADMIN/GETTERS
    //////////////////////////////////////////////////////////////*/
    function setUpkeepInterval(uint256 newInterval) external onlyOwner {
        s_upkeepInterval = newInterval;
        emit UpkeepIntervalUpdated(newInterval);
    }

    function getMarketPhase() external view returns (bool ,uint256 , uint256) {
        return  (s_marketState , s_marketOpenTime , s_marketCloseTime);
    }
}
