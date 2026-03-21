// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRSTKToken} from "../RSTK/token/IRSTKToken.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IContractStruct} from "./IContractStruct.sol";
import {IPriceOracle} from "../Oracle/IPriceOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SRSTKConstant} from "./SRSTKConstant.sol";

contract SRSTK is FunctionsClient, ConfirmedOwner, IContractStruct {
    /*//////////////////////////////////////////////////////////////
                            TYPE DECLERATION
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 private s_portfolioBalance;
    bytes32 private s_depositRequestId;
    bytes32 private s_burnRequestId;
    uint256 private s_priceIdCounter = 1;
    uint256 private s_totalContractBalance;
    uint256 private s_totalUserBalance;
    address[] private s_totalUsers;
    mapping(bytes32 => IContractStruct.Depositor) private s_depositorData; // independent 1
    mapping(bytes32 => IContractStruct.Redeemer) private s_redeemerData; // independent 2
    mapping(address => mapping(uint8 => bytes32)) private s_userUniqueId;
    mapping(bytes32 => IContractStruct.RequestType) private s_requestType;
    mapping(IContractStruct.RequestType => IContractStruct.RequestConfig) private s_request;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_donId;
    uint32 immutable i_gasLimit;
    uint256 immutable i_precision;
    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    address immutable i_usdcAddress;
    address immutable i_srstkTokenAddr;
    address immutable i_priceOracleAddr;
    AggregatorV3Interface internal immutable i_aggregator;
    /*//////////////////////////////////////////////////////////////
                                EVENT       
    //////////////////////////////////////////////////////////////*/
    event SRSTK__DepositRequested(bytes32 indexed requestId, address indexed depositor, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SRSTK__AmountCannotBeZero();
    error SRSTK__InvalidRequestType();
    error SRSTK__InsufficientCollateral();

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireToCheckAmount(uint256 amount) {
        if(amount < SRSTKConstant.MINIMUM_DEPSOIT){
            revert SRSTK__AmountCannotBeZero();
        }
        _;
    }
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IPriceOracle.RequestData memory config,IContractStruct.ExtraInfo memory extra) FunctionsClient(config.router) ConfirmedOwner(config.accessControlAddress.owner()) {
        i_subscriptionId = config.subscriptionId;
        i_donId = config.donID;
        i_gasLimit = config.gasLimit;
        i_donHostedSecretsSlotID = config.donHostedSecretsSlotID;
        i_donHostedSecretsVersion = config.donHostedSecretsVersion;
        i_aggregator = AggregatorV3Interface(extra.aggregator);
        i_precision = extra.precision;
        i_usdcAddress = extra.usdc;
        i_srstkTokenAddr = extra.srstkTokenAddr;
        i_priceOracleAddr = extra.priceOracleAddr;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function sendMintRequest(uint256 amount) external requireToCheckAmount(amount) returns (bytes32) {
        uint256 minimumCollateral = minimumCollateralNeeded(amount);
        if(minimumCollateral > IERC20(i_usdcAddress).balanceOf(msg.sender)){
            revert SRSTK__InsufficientCollateral();
        }
        IContractStruct.RequestConfig memory config = setRequestConfig(SRSTKConstant.SRC_MINT, new string[](0), new bytes[](0));
        bytes32 requestId = makeRequestToDon(config);
        s_depositRequestId = requestId;
        uint256 priceId = s_priceIdCounter++;
        s_totalContractBalance += amount;
        s_depositorData[s_depositRequestId] = IContractStruct.Depositor({
            depositorAddress: msg.sender,
            amountDeposited: amount,
            priceId: priceId
        });
        s_userUniqueId[msg.sender] = requestId;
        s_requestType[requestId] = IContractStruct.RequestType.MINT;
        s_request[IContractStruct.RequestType.MINT] = config;
        s_userUniqueId[msg.sender][0] = requestId;
        IERC20(i_usdcAddress).transferFrom(msg.sender, address(this), amount);
        emit SRSTK__DepositRequested(requestId, msg.sender, amount);
        return requestId;
    }

    function sendBurnRequest() external {}

    function withdraw() external {}


    /*//////////////////////////////////////////////////////////////
                             EXTERNAL GETTER
    //////////////////////////////////////////////////////////////*/
    function getUSDCPrice() external view returns(uint256){
        return _getUSDCPriceInUSD();
    }

    function getCurrentRequestIntent(bytes32 requestID) external view returns (IContractStruct.RequestType) {
        return s_requestType[requestID];
    }

    function getUserRequestID(address user) external view returns  (bytes32){
        return s_userUniqueId[user];
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if(s_requestType[requestId] == IContractStruct.RequestType.MINT){
            _handleMintToken();
        }
        else if(s_requestType[requestId] == IContractStruct.RequestType.BURN){
            _handleBurnToken();
        }else if(s_requestType[requestId] == IContractStruct.RequestType.PORTFOLIO){
            _handleFetchPortFolioBalance();
        }else{
            revert SRSTK__InvalidRequestType();
        }
    }

    function _getUSDCPriceInUSD() internal view returns (uint256) {
        (, int256 price, , , ) = i_aggregator.latestRoundData();
        return uint256(price);
    }

    function minimumCollateralNeeded(uint256 anountToMint) public view returns (uint256 minCollateralRequired) {
        uint256 assetRequired = _calculateRequiredValue(anountToMint);
        minCollateralRequired = (assetRequired * SRSTKConstant.MIN_COLLATERAL_BPS )/ SRSTKConstant.BPS_DENOMINATOR;
    } 

    function _calculateRequiredValue(uint256 amountOfTokenToMint) internal view returns (uint256 assetRequired) {
        uint256 priceOfRsst = IPriceOracle(i_priceOracleAddr).getPrice();
        assetRequired = priceOfRsst * amountOfTokenToMint;
    }

    function makeRequestToDon(IContractStruct.RequestConfig memory config) internal returns(uint256) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(config.source);
        req.addDONHostedSecrets(
            i_donHostedSecretsSlotID,
            i_donHostedSecretsVersion
        );
        if (config.args.length > 0) req.setArgs(config.args);
        if (config.bytesArgs.length > 0) req.setBytesArgs(config.bytesArgs);
        bytes32 requestID = _sendRequest(
            req.encodeCBOR(),
            i_subscriptionId,
            i_gasLimit,
            i_donId
        );
        return requestID;
    }
    function setRequestConfig(string calldata source, string[] calldata args, bytes[] calldata bytesArgs) internal returns(IContractStruct.RequestConfig memory config){
        config = IContractStruct.RequestConfig({
            source : source
            args: args,
            bytesArgs: bytesArgs
        });
    }

    function _handleFetchPortFolioBalance() internal {}

    function _handleMintToken() internal {}

    function _handleBurnToken() internal {}

    function portFolio() internal {}
}
