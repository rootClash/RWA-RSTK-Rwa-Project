// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {PortfolioBalance} from "../src/automation/PortfolioBalance.sol";
import {
    HelperScript
} from "../script/Helper/HelperScript.s.sol";
import {IContractStruct} from "../src/RSTK/IContractStruct.sol";
import {mockRouter} from "../test/mock/mockRouter.sol";
import {RWAAccessControl} from "../src/access/RWAAccessControl.sol";

contract DeployPortfolio is Script { 
    PortfolioBalance public s_portfolioBalance;
    HelperScript public s_script;
    string public constant SOURCE = "./functions/source/sourcePortfolio.js";
    function run(address owner) public returns (PortfolioBalance,HelperScript) {
        vm.startBroadcast(owner);
        s_script = new HelperScript(SOURCE);
        (
            IContractStruct.RequestData memory network,
            IContractStruct.RequestConfig memory config
        ) = s_script.getNetworkConfig();
        s_portfolioBalance = new PortfolioBalance(msg.sender, network, config);
        vm.stopBroadcast();
        return (s_portfolioBalance , s_script);
    }
}
