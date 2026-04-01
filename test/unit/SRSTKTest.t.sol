// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
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
import {MockERC20} from "@chainlink/contracts/src/v0.8/vendor/forge-std/src/mocks/MockERC20.sol";

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
    string public constant SOURCE = "./functions/source/sourcePortfolio.js";
    address public USER = makeAddr("user");
    function setUp() public {
        s_helperScript = new HelperScript(SOURCE);
        s_tokenScript = new TokenScript();
        ( s_requestData  , s_requestConfig) = s_helperScript.getNetworkConfig();
        s_extraInfo = s_tokenScript.getNetworkConfig();
        s_priceOracle = new PriceOracle(s_extraInfo.owner,s_requestData,s_requestConfig);
        s_portfolioBalance = new PortfolioBalance(s_extraInfo.owner,s_requestData,s_requestConfig);
        s_rstkToken = new RSTKToken(s_requestData.accessControlAddress);
        s_deploySRSTK = new DeploySRSTK();  
        s_deploySRSTK.run(SOURCE,s_extraInfo.srstkTokenAddr,s_extraInfo.priceOracleAddr,s_extraInfo.portfolioContractAddr);
        vm.startPrank(address(s_tokenScript));
        IERC20(s_extraInfo.usdc)._mint(USER , 100e6);
        vm.stopPrank();
    }

    function testSendRequest() public {
        


    }

}