// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {SRSTK} from "../../src/RSTK/SRSTK.sol";
import {TokenScript} from "../../script/Helper/TokenScript.s.sol";
import {SRSTKConstant} from "../../src/RSTK/SRSTKConstant.sol";
import {HelperScript} from "../../script/Helper/HelperScript.s.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
contract SRSTKTest is Test {
    SRSTK public s_srstk;
    TokenScript public s_tokenScript;
    HelperScript public s_scriptPriceOracle;
    // string public constant SOURCE = "./functions/source/sourcePortfolio.js";
    function setUp() public {
        s_tokenScript = new TokenScript();
        s_scriptPriceOracle = new HelperScript("");
        (IContractStruct.RequestData memory config  , IContractStruct.RequestConfig memory config2)= s_scriptPriceOracle.getNetworkConfig();
        IContractStruct.ExtraInfo memory aggregator = s_tokenScript.getNetworkConfig();
        s_srstk = new SRSTK(
            config,
            aggregator
        );
    }

}