// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {PriceOracle} from "../src/Oracle/PriceOracle.sol";
import {Script, console} from "forge-std/Script.sol";
import {
    HelperScript
} from "../script/Helper/HelperScript.s.sol";
import {mockRouter} from "../test/mock/mockRouter.sol";
import {IContractStruct} from "../src/RSTK/IContractStruct.sol";

contract DeployPriceOracle is Script {
    PriceOracle public s_priceOracle;
    HelperScript public s_scriptPriceOracle;
    mockRouter public s_mockRouter;
    string public constant SOURCE = "./functions/source/source.js";
    function run(address accessControlAddr) public returns (PriceOracle) {
        s_scriptPriceOracle = new HelperScript(SOURCE);
        (
            IContractStruct.RequestData memory network,
            IContractStruct.RequestConfig memory config
        ) = s_scriptPriceOracle.getNetworkConfig();
        vm.startBroadcast();
        if (block.chainid == 31337) {
            s_mockRouter = new mockRouter();
            network.router = address(s_mockRouter);
            network.accessControlAddress = address(accessControlAddr);
        }
        ////// change the address of the owner
        s_priceOracle = new PriceOracle(msg.sender, network, config);
        vm.stopBroadcast();
        console.log(
            "The address of the PriceOracle : ",
            address(s_priceOracle)
        );
        return s_priceOracle;
    }
}
