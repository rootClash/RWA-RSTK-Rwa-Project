// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IRSTKToken} from "../RSTK/token/IRSTKToken.sol";
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
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IContractStruct} from "./IContractStruct.sol";
import {IPriceOracle} from "../Oracle/IPriceOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SRSTKConstant} from "./SRSTKConstant.sol";
import {IPortfolioBalance} from "../automation/IPortfolioBalance.sol";
import {Allowlist} from "../allowlist/Allowlist.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {
    AutomationCompatibleInterface
} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {IMarketPhase} from "../MarketCheck/IMarketPhase.sol";

contract SRSTK is FunctionsClient, ConfirmedOwner, IContractStruct {
    /*//////////////////////////////////////////////////////////////
                            TYPE DECLERATION
    //////////////////////////////////////////////////////////////*/
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    uint256 private s_portfolioBalance;
    uint256 private s_totalContractBalance;
    uint256 private s_depositedAmountUsedForBuy;
    uint256 private s_redeemerAmountUsedForSell;
    uint256 private s_currentMintBatchId;
    uint256 private s_currentBurnBatchId;
    mapping(bytes32 => uint256) private s_requestIdToBatchId;
    mapping(uint256 => bool) private s_batchMintFulfilled;
    mapping(uint256 => bool) private s_batchBurnFulfilled;
    bytes32 private s_latestRequestId;
    bytes32 private s_latestBurnRequestId;
    mapping(address => mapping(bytes32 => IContractStruct.Depositor))
        private s_depositorData;
    mapping(address => bytes32[]) private s_depositorIds;
    mapping(address => mapping(bytes32 => IContractStruct.Redeemer))
        private s_redeemerData;
    mapping(address => bytes32[]) private s_redmerIds;
    mapping(bytes32 => IContractStruct.RequestType) private s_requestIdType;
    mapping(bytes32 => IContractStruct.RequestPhase) private s_requestPhase;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_donId;
    uint32 immutable i_gasLimit;
    uint256 immutable i_precision;
    uint8 immutable i_donHostedSecretsSlotID;
    uint64 immutable i_donHostedSecretsVersion;
    address immutable i_usdcAddress;
    address immutable i_srstkTokenAddr;
    address immutable i_priceOracleAddr;
    address immutable i_portfolioBalance;
    address immutable i_marketPhaseContractAddr;
    AggregatorV3Interface internal immutable i_aggregator;
    /*//////////////////////////////////////////////////////////////
                                EVENT       
    //////////////////////////////////////////////////////////////*/
    event DepositRequested(
        address indexed depositor,
        bytes32 indexed requestId,
        uint256 amountOfTokenToMint,
        uint256 minimumCollateralRequired
    );
    event BurnRequested(
        address indexed redeemer,
        bytes32 indexed requestId,
        uint256 amountOfTokenToBurn,
        uint256 minimumCollateralExpected
    );
    event PortfolioBalance(uint256 newBalance);
    event ClientIdReceived(string clientId, uint256 batchId);
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SRSTK__AmountCannotBeZero();
    error SRSTK__InsufficientBalance();
    error SRSTK__TransactionNotSuccesed();
    error SRSTK__InsufficientReserve();
    error SRSTK__InvalidRequestId();
    error SRSTK__InvalidRequestType();
    error SRSTK__RequestCannotBeProcessed();
    error SRSTK__MakeMintRequestAgain();
    error SRSTK__MarketIsClosed();
    error SRSTK__TokenTranferToContractFailed();
    error SRSTK__UpkeepNotNeeded();
    error SRSTK__InvalidClientId();
    error SSRSTK__TotalDepositedAndRedeemAmountIsZero();
    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireToCheckAmount(uint256 amount) {
        if (amount < SRSTKConstant.MINIMUM_DEPSOIT) {
            revert SRSTK__AmountCannotBeZero();
        }
        _;
    }
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        IContractStruct.RequestData memory config,
        IContractStruct.ExtraInfo memory extra
    ) FunctionsClient(config.router) ConfirmedOwner(extra.owner) {
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
        i_portfolioBalance = extra.portfolioContractAddr;
    }

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/
    function sendMintRequest(
        uint256 amountOfTokenToMint
    ) external requireToCheckAmount(amountOfTokenToMint) returns (bytes32) {
        uint256 minimumCollateral = minimumCollateralNeeded(
            amountOfTokenToMint
        );
        if (minimumCollateral > IERC20(i_usdcAddress).balanceOf(msg.sender)) {
            revert SRSTK__InsufficientBalance();
        }
        uint256 currentCashAvailable = getPortfolioBalance();
        if (currentCashAvailable <= minimumCollateral) {
            revert SRSTK__InsufficientReserve();
        }
        bytes32 priceId = keccak256(
            abi.encodePacked(msg.sender, amountOfTokenToMint, block.timestamp)
        );
        IContractStruct.Depositor memory depositor = IContractStruct.Depositor({
            depositorAddress: msg.sender,
            amountToMint: amountOfTokenToMint,
            priceId: priceId,
            batchId: s_currentMintBatchId,
            redeemed: false,
            collateralPaid: minimumCollateral,
            notionalAmount: 0
        });
        s_depositorData[msg.sender][priceId] = depositor;
        s_depositorIds[msg.sender].push(priceId);
        s_totalContractBalance += minimumCollateral; /// this is the total contract balance
        uint256 notionalAmount = getLimitExposer(depositor.collateralPaid);
        depositor.notionalAmount = notionalAmount;
        s_depositedAmountUsedForBuy += notionalAmount; /// this is the total amount for buying the stocks.
        bool success = IERC20(i_usdcAddress).transferFrom(
            msg.sender,
            address(this),
            minimumCollateral
        );
        if (!success) {
            revert SRSTK__TransactionNotSuccesed();
        }
        emit DepositRequested(
            msg.sender,
            priceId,
            amountOfTokenToMint,
            minimumCollateral
        );
        return priceId;
    }

    function sendBurnRequest(
        uint256 amountOfTokenToBurn
    ) external requireToCheckAmount(amountOfTokenToBurn) returns (bytes32) {
        if (
            IERC20(i_srstkTokenAddr).balanceOf(msg.sender) < amountOfTokenToBurn
        ) {
            revert SRSTK__InsufficientBalance();
        }

        uint256 minCollateralExpected = minimumCollateralNeeded(
            amountOfTokenToBurn
        );
        if (
            minCollateralExpected > IERC20(i_usdcAddress).balanceOf(msg.sender)
        ) {
            revert SRSTK__InsufficientReserve();
        }
        bytes32 priceId = keccak256(
            abi.encodePacked(msg.sender, amountOfTokenToBurn, block.timestamp)
        );

        IContractStruct.Redeemer memory redeemer = IContractStruct.Redeemer({
            redeemed: false,
            priceId: priceId,
            user: msg.sender,
            batchId: s_currentBurnBatchId,
            amountToTokenBurned: amountOfTokenToBurn,
            minCollateralExpected: minCollateralExpected
        });
        s_redeemerAmountUsedForSell += getLimitExposer(redeemer.minCollateralExpected);
        s_redeemerData[msg.sender][priceId] = redeemer;
        s_redmerIds[msg.sender].push(priceId);

        bool success = IERC20(i_srstkTokenAddr).transferFrom(
            msg.sender,
            address(this),
            amountOfTokenToBurn
        );
        if (!success) {
            revert SRSTK__TransactionNotSuccesed();
        }

        emit BurnRequested(
            msg.sender,
            priceId,
            amountOfTokenToBurn,
            minCollateralExpected
        );

        return priceId;
    }

    function redeemUsdc(bytes32 priceId , uint256 requestIdIndex) external {

    }

    function redeemTokens(bytes32 priceId, uint256 requestIdIndex) external {
        /// CEI
        if (s_depositorIds[msg.sender][requestIdIndex] != priceId) {
            revert SRSTK__InvalidRequestId();
        }
        IContractStruct.Depositor storage depositor = s_depositorData[
            msg.sender
        ][priceId];
        if (depositor.redeemed) {
            revert SRSTK__MakeMintRequestAgain();
        }
        if (!s_batchMintFulfilled[depositor.batchId]) {
            revert SRSTK__RequestCannotBeProcessed();
        }

        depositor.redeemed = true;
        depositor.collateralPaid =
            depositor.collateralPaid -
            depositor.notionalAmount;
        bool success = IERC20(i_srstkTokenAddr).transfer(
            msg.sender,
            depositor.amountToMint
        );
        if (!success) {
            revert SRSTK__TransactionNotSuccesed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL GETTER
    //////////////////////////////////////////////////////////////*/
    function getUSDCPrice() external view returns (uint256) {
        return _getUSDCPriceInUSD();
    }

    //// use the modifier for checking the user in allowlist
    function getRequestIntent(
        bytes32 requestID
    ) external view returns (IContractStruct.RequestType) {
        return s_requestIdType[requestID];
    }

    /// add the modifier to check that the address has been added to the Allowlist
    function getUserRequestIDs()
        external
        view
        returns (bytes32[] memory depositorData)
    {
        depositorData = s_depositorIds[msg.sender];
    }

    function getPortfolioBalance() public returns (uint256) {
        uint256 portfolioBalance = IPortfolioBalance(i_portfolioBalance)
            .getbalance();
        s_portfolioBalance = portfolioBalance;
        emit PortfolioBalance(portfolioBalance);
        return portfolioBalance;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/
    function minimumCollateralNeeded(
        uint256 numberOfShares
    ) public view returns (uint256 minCollateralRequired) {
        uint256 assetRequired = _calculateRequiredValue(numberOfShares);
        minCollateralRequired =
            (assetRequired * SRSTKConstant.MIN_COLLATERAL_BPS) /
            SRSTKConstant.BPS_DENOMINATOR;
    }

    function getLimitExposer(
        uint256 collateral
    ) public pure returns (uint256 limitExposer) {
        limitExposer =
            (collateral * SRSTKConstant.BPS_DENOMINATOR) /
            SRSTKConstant.MIN_COLLATERAL_BPS;
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/
    function buyStocks() internal returns (bytes32) {
        string[] memory argsValue = new string[](1);
        argsValue[0] = s_depositedAmountUsedForBuy.toString();
        bytes32 requestId = _makeRequestToDon(
            IContractStruct.RequestConfig({
                source: SRSTKConstant.SRC_BUY,
                args: argsValue,
                bytesArgs: new bytes[](0)
            })
        );
        s_requestPhase[requestId] = IContractStruct.RequestPhase.START;
        return requestId;
    }

    functions sellStocks() internal returns (bytes32) {
        string[] memory argsValue = new string[](1);
        argsValue[0] = s_depositedAmountUsedForBuy.toString();
        bytes32 requestId = _makeRequestToDon(
            IContractStruct.RequestConfig({
                source: SRSTKConstant.SRC_SELL,
                args: argsValue,
                bytesArgs: new bytes[](0)
            })
        );
        s_requestPhase[requestId] = IContractStruct.RequestPhase.START;
        return requestId;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_requestIdType[requestId] == IContractStruct.RequestType.MINT) {
            _handleMintToken(response, requestId);
        } else if (
            s_requestIdType[requestId] == IContractStruct.RequestType.BURN
        ) {
            // _handleBurnToken(response);
        } else {
            revert SRSTK__InvalidRequestType();
        }
        s_requestIdType[requestId] = IContractStruct.RequestType.NONE;
        s_requestPhase[requestId] = IContractStruct.RequestPhase.DONE;
    }

    function _getUSDCPriceInUSD() internal view returns (uint256) {
        (, int256 price, , , ) = i_aggregator.latestRoundData();
        return uint256(price);
    }

    function _calculateRequiredValue(
        uint256 numberOfTokens
    ) internal view returns (uint256 assetRequired) {
        uint256 priceOfRsst = IPriceOracle(i_priceOracleAddr).getPrice();
        assetRequired = priceOfRsst * numberOfTokens;
    }

    function _makeRequestToDon(
        IContractStruct.RequestConfig memory config
    ) internal returns (bytes32) {
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

    function _handleMintToken(
        bytes memory response,
        bytes32 requestId
    ) internal {
        string memory clientId = abi.decode(response, (string));
        if (bytes(clientId).length == 0) {
            revert SRSTK__InvalidClientId();
        }

        uint256 batchId = s_requestIdToBatchId[requestId];
        s_batchMintFulfilled[batchId] = true;
        emit ClientIdReceived(clientId, batchId);
    }

    function _handleBurnToken() internal {}

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) internal returns (bool upkeepNeeded, bytes memory /*performData*/) {
        (bool state, uint256 openingTime, uint256 closeTime) = IMarketPhase(
            i_marketPhaseContractAddr
        ).getMarketPhase();
        bool checkTime = openingTime > block.timestamp &&
            closeTime < block.timestamp &&
            state == true;
            
        upkeepNeeded = checkTime && (s_depositedAmountUsedForBuy > 0);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata performData) external {
        /// CEI
        (bool upkeepNeeded, ) = checkUpkeep(performData);
        if (!upkeepNeeded) {
            revert SRSTK__UpkeepNotNeeded();
        }
        // Double check to ensure we don't send empty requests
        if(s_depositedAmountUsedForBuy == 0 && s_redeemerAmountUsedForSell == 0){
            revert SSRSTK__TotalDepositedAndRedeemAmountIsZero();
        }
        if()
        bytes32 requestId = buyStocks();
        s_latestRequestId = requestId;
        s_requestIdToBatchId[requestId] = s_currentMintBatchId;
        s_currentMintBatchId++; // Advance to the next batch for future depositors
        s_depositedAmountUsedForBuy = 0; // Reset the aggregator so we don't double-buy next upkeep!
        s_requestIdType[requestId] = IContractStruct.RequestType.MINT;
        s_requestPhase[requestId] = IContractStruct.RequestPhase.PENDING;

        bytes32 burnRequestId = sellStocks();
        s_latestBurnRequestId = burnRequestId;
        s_requestIdToBatchId[burnRequestId] = s_currentBurnBatchId;
        s_currentBurnBatchId++; // Advance to the next batch for future redeemers
        s_redeemerAmountUsedForSell = 0; // Reset the aggregator so we don't double-sell next upkeep!
        s_requestIdType[burnRequestId] = IContractStruct.RequestType.BURN;
        s_requestPhase[burnRequestId] = IContractStruct.RequestPhase.PENDING;
    }
}
