// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {SRSTK} from "../src/RSTK/SRSTK.sol";
import {TokenScript} from "../script/Helper/TokenScript.s.sol";
import {HelperScript} from "../script/Helper/HelperScript.s.sol";
import {IContractStruct} from "../src/RSTK/IContractStruct.sol";

contract DeploySRSTK is Script {
    SRSTK public s_srstk;
    HelperScript public s_scriptPriceOracle;
    TokenScript public s_tokenScript;
    function run(string memory source,address srstkTokenAddr,address priceOracleAddr,address portfolioContractAddr,address usdcAddress,address marketPhaseContractAddr) public returns(SRSTK){
        s_scriptPriceOracle = new HelperScript(source);
        (IContractStruct.RequestData memory config  , )= s_scriptPriceOracle.getNetworkConfig();
        s_tokenScript = new TokenScript();
        IContractStruct.ExtraInfo memory extraInfo = s_tokenScript.getNetworkConfig();
        extraInfo.srstkTokenAddr = srstkTokenAddr;
        extraInfo.priceOracleAddr = priceOracleAddr;
        extraInfo.portfolioContractAddr = portfolioContractAddr;
        extraInfo.usdc = usdcAddress;
        extraInfo.marketPhaseContractAddr = marketPhaseContractAddr;
        vm.startBroadcast();
        s_srstk = new SRSTK(
            config,
            extraInfo
        );
        vm.stopBroadcast();
        return s_srstk;
    
    }
}