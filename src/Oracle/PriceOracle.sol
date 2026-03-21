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
import {IRWAAccessControl} from "../access/IRWAAccessControl.sol";
import {IPriceOracle} from "./IPriceOracle.sol";

/// @title PriceOracle
/// @notice A price oracle that fetches price data from an external source using Chainlink Functions
/// @dev This contract is designed to be used in a real estate context, where KYC agents can update price data manually, and the contract owner can fetch price data from an external source using Chainlink Functions. The contract uses a mapping to store price data associated with unique request IDs, allowing for multiple price updates and retrievals.
/// @dev The contract will be handled by the BOT and KYC Agent...
contract PriceOracle is FunctionsClient, ConfirmedOwner, IPriceOracle {
    /*//////////////////////////////////////////////////////////////
                                TYPE DECLERATION
    //////////////////////////////////////////////////////////////*/
    IRWAAccessControl private immutable i_accessControl;
    using FunctionsRequest for FunctionsRequest.Request;
    struct PriceData {
        uint256 price;
        uint256 timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    PriceData public s_priceData;
    // mapping(bytes32 => PriceData) private s_priceData;
    string private s_source;
    string[] private s_args;
    bytes[] private s_bytesArgs;
    bytes32 private s_latestRequestId;

    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    uint64 immutable i_subscriptionId;
    uint32 immutable i_gasLimit;
    bytes32 immutable i_donID;
    /*//////////////////////////////////////////////////////////////
                                    EVENT
        //////////////////////////////////////////////////////////////*/
    event PriceUpdated(uint256 newPrice, uint256 timestamp);
    event PriceFetchedAndUpdated(
        bytes32 requestId,
        uint256 newPrice,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                                    ERROR
        //////////////////////////////////////////////////////////////*/
    error PriceOracle__RequestIdNotFound();
    error PriceOracle__HeartbeatNotReached();

    /*//////////////////////////////////////////////////////////////
                                    MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyKycAgent() {
        require(
            i_accessControl.isKYCAgentRole(msg.sender),
            "Caller is not a KYC agent"
        );
        _;
    }
    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address confirmedOwner,
        RequestData memory requestData
    ) FunctionsClient(requestData.router) ConfirmedOwner(confirmedOwner) {
        i_accessControl = IRWAAccessControl(requestData.accessControlAddress);
        s_source = requestData.source;
        i_donHostedSecretsSlotID = requestData.donHostedSecretsSlotID;
        i_donHostedSecretsVersion = requestData.donHostedSecretsVersion;
        s_args = requestData.args;
        s_bytesArgs = requestData.bytesArgs;
        i_subscriptionId = requestData.subscriptionId;
        i_gasLimit = requestData.gasLimit;
        i_donID = requestData.donID;
    }                

    // automate : can be automated but can be used by Kyc Agent
    function setPrice(
        uint256 newPrice
    ) external onlyKycAgent {
        if(block.timestamp - s_priceData.timestamp < 3600){
            revert PriceOracle__HeartbeatNotReached();
        }
        uint256 scaledPrice = newPrice * 10 ** 8;
        s_priceData = PriceData({
            price: scaledPrice,
            timestamp: block.timestamp
        });
        emit PriceUpdated(newPrice, block.timestamp);
    }

    // Alpaca : update the struct with the response from the oracle
    function sendRequest() external onlyKycAgent returns (bytes32 requestId) {
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
            revert PriceOracle__RequestIdNotFound();
        }
        if (err.length > 0) {
            revert(
                string(abi.encodePacked("Error from oracle: ", string(err)))
            );
        }
        uint256 price = abi.decode(response, (uint256));
        s_priceData = PriceData({
            price: price,
            timestamp: block.timestamp
        });
        emit PriceFetchedAndUpdated(requestId, price, block.timestamp);
    }

    function getLatestRequestId() external view returns (bytes32) {
        return s_latestRequestId;
    }

    function getPrice() external view returns (uint256) {
        return s_priceData.price;
    }

    function getFullFilRequest() public {}
}
