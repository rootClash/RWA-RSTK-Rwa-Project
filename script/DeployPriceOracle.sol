// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {PriceOracle} from "../src/Oracle/PriceOracle.sol";
import {Script, console} from "forge-std/Script.sol";
import {
    HelperScript
} from "../script/Helper/HelperScript.s.sol";
import {mockRouter} from "../test/mock/mockRouter.sol";
import {IContractStruct} from "../src/RSTK/IContractStruct.sol";
import {RWAAccessControl} from "../src/access/RWAAccessControl.sol";

contract DeployPriceOracle is Script {
    PriceOracle public s_priceOracle;
    HelperScript public s_scriptPriceOracle;
    mockRouter public s_mockRouter;
    string public constant SOURCE = "./functions/source/source.js";
    function run(address owner) public returns (PriceOracle, HelperScript) {
        s_scriptPriceOracle = new HelperScript(SOURCE);
        (
            IContractStruct.RequestData memory network,
            IContractStruct.RequestConfig memory config
        ) = s_scriptPriceOracle.getNetworkConfig();
        vm.startBroadcast(owner);
        s_priceOracle = new PriceOracle(owner, network, config);
        vm.stopBroadcast();
        console.log(
            "The address of the PriceOracle : ",
            address(s_priceOracle)
        );
        return (s_priceOracle , s_scriptPriceOracle);
    }
}
