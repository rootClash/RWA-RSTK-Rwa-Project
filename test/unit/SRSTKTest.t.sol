// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test,console} from "forge-std/Test.sol";
import {SRSTK} from "../../src/RSTK/SRSTK.sol";
import {DeploySRSTK} from "../../script/DeploySRSTK.s.sol";
import {RSTKToken} from "../../src/RSTK/token/RSTKToken.sol";
import {PriceOracle} from "../../src/Oracle/PriceOracle.sol";
import {PortfolioBalance} from "../../src/automation/PortfolioBalance.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
import {HelperScript} from "../../script/Helper/HelperScript.s.sol";
import {TokenScript} from "../../script/Helper/TokenScript.s.sol";
import {FunctionsSubscriptions} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsSubscriptions.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {IRWAAccessControl} from "../../src/access/IRWAAccessControl.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPriceOracle} from "../../src/Oracle/IPriceOracle.sol";

contract SRSTKTest is Test {
    SRSTK public s_srstk;
    DeploySRSTK public s_deploySRSTK;
    RSTKToken public s_rstkToken;
    PriceOracle public s_priceOracle;
    PortfolioBalance public s_portfolioBalance;
    HelperScript public s_helperScript;
    TokenScript public s_tokenScript;
    IContractStruct.RequestConfig public s_requestConfig;
    IContractStruct.RequestData public s_requestData;
    IContractStruct.ExtraInfo public s_extraInfo;
    ERC20Mock public s_mockERC20;

    string public constant SOURCE = "./functions/source/sourcePortfolio.js";
    address public USER = makeAddr("user");
    address public alice = makeAddr("alice");
    function setUp() public {
        s_helperScript = new HelperScript(SOURCE);
        s_tokenScript = new TokenScript();
        ( s_requestData  , s_requestConfig) = s_helperScript.getNetworkConfig();
        s_extraInfo = s_tokenScript.getNetworkConfig();
        console.log("source : ",s_requestConfig.source);
        s_priceOracle = new PriceOracle(s_extraInfo.owner,s_requestData,s_requestConfig);
        s_portfolioBalance = new PortfolioBalance(s_extraInfo.owner,s_requestData,s_requestConfig);
        s_rstkToken = new RSTKToken(s_requestData.accessControlAddress);
        vm.startPrank(s_extraInfo.owner);
        s_mockERC20 = new ERC20Mock();
        s_mockERC20.mint(USER,100e18);
        vm.stopPrank();
        s_extraInfo.srstkTokenAddr = address(s_rstkToken);
        s_extraInfo.priceOracleAddr = address(s_priceOracle);
        s_extraInfo.portfolioContractAddr = address(s_portfolioBalance);
        s_extraInfo.usdc = address(s_mockERC20);
        s_deploySRSTK = new DeploySRSTK();
        //// value is zero by now ... 
        console.log("srstk address : " , s_extraInfo.srstkTokenAddr);
        console.log("price oracle address : " , s_extraInfo.priceOracleAddr);
        console.log("portfolio contract address : " , s_extraInfo.portfolioContractAddr);
        console.log("owner address : " , s_extraInfo.owner);
        console.log("usdc address : " , s_extraInfo.usdc);
        s_srstk = s_deploySRSTK.run(s_requestConfig.source,s_extraInfo.srstkTokenAddr,s_extraInfo.priceOracleAddr,s_extraInfo.portfolioContractAddr,s_extraInfo.usdc);
        console.log("address : ",address(s_srstk));
    }

    function test_sendRequest() public {
        uint256 value = 150e6;
        uint256 usdcValue = 1;
        // set the kyc agent
        vm.prank(s_extraInfo.owner);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);
        // increased the time
        vm.warp(block.timestamp + 3600);
        /// alice set the price
        vm.prank(alice);
        IPriceOracle(s_extraInfo.priceOracleAddr).setPrice(usdcValue);
        /// user approved the amount
        vm.startPrank(USER);
        IERC20(s_extraInfo.usdc).approve(address(s_srstk), value);
        uint256 minimumCollateral = s_srstk.minimumCollateralNeeded(1);
        console.log("Minimum collateral : " , minimumCollateral);
        s_srstk.sendMintRequest(value);
        vm.stopPrank();
        uint256[] memory userData  = s_srstk.getUserRequestID(USER);
        for(uint256 i = 0; i < userData.length;i++){
            console.log("User ",userData[i]);
        }

        assertEq(IPriceOracle(s_extraInfo.priceOracleAddr).getPrice(),usdcValue * 10 ** 8);
        assertTrue(IRWAAccessControl(s_requestData.accessControlAddress).isKYCAgentRole(alice));
    }

}