// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {SRSTK} from "../../src/RSTK/SRSTK.sol";
import {TokenScript} from "../../script/Helper/TokenScript.s.sol";
import {SRSTKConstant} from "../../src/RSTK/SRSTKConstant.sol";
import {ScriptForPriceOracle} from "../../script/Helper/ScriptForPriceOracle.s.sol";
contract SRSTKTest is Test {
    SRSTK public s_srstk;
    TokenScript public s_tokenScript;
    ScriptForPriceOracle public s_scriptPriceOracle;

    function setUp() public {
        s_tokenScript = new TokenScript();
        s_scriptPriceOracle = new ScriptForPriceOracle();
        IPriceOracle.RequestData memory config= s_scriptPriceOracle.s_config(block.chainid);
        IContractStruct.ExtraInfo memory aggregator = s_tokenScript.s_networks(block.chainid);
        s_srstk = new SRSTK(
            config,
            aggregator
        );
    }

}