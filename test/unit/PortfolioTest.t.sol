// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test} from "forge-std/Test.sol";
import {PortfolioBalance} from "../../src/automation/PortfolioBalance.sol";
import {DeployPortfolio} from "../../script/DeployPortfolio.s.sol";
import {HelperScript} from "../../script/Helper/HelperScript.s.sol";
import {IRWAAccessControl} from "../../src/access/IRWAAccessControl.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";

contract PortfolioTest is Test, PortfolioBalance {
    DeployPortfolio public s_deployPortfolio;
    PortfolioBalance public s_currenctCashAvailable;
    HelperScript public s_script;
    address public admin = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    address public alice = makeAddr("kyc-role");
    IContractStruct.RequestData public network;
    constructor() PortfolioBalance(admin , network , config){}
    function setUp() public {
        vm.prank(admin);
        s_deployPortfolio = new DeployPortfolio();
        (s_currenctCashAvailable , s_script) = s_deployPortfolio.run(admin);
        ( network , ) = s_script.getNetworkConfig();
    }

    function testContructor() public {
        assertEq(s_currenctCashAvailable.getbalance(), 0);
    }
    /**
     * 1. to test the subscriptionId
     * 2. the result from the chainlink is correct
     * 3. that "sendRequest" is called on the specific time  (chainlink automation test)
     */
    function testSendRequestForPortfolio() public {
        vm.prank(admin);
        IRWAAccessControl(network.accessControlAddress).grantKYCAgentRole(alice);

        vm.startPrank(alice);
        bytes32 reuqestId = s_currenctCashAvailable.sendRequest();
        bytes32 latestRequestId = s_currenctCashAvailable.getLatestRequestId();
        vm.stopPrank();
        assertEq(reuqestId, latestRequestId);
    }
}
