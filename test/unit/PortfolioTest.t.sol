// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test,console} from "forge-std/Test.sol";
import {PortfolioBalance} from "../../src/automation/PortfolioBalance.sol";
import {DeployPortfolio} from "../../script/DeployPortfolio.s.sol";
import {HelperScript} from "../../script/Helper/HelperScript.s.sol";
import {IRWAAccessControl} from "../../src/access/IRWAAccessControl.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
import {PortfolioHarness} from "../mock/PortfolioHarness.sol";

contract PortfolioTest is Test {
    DeployPortfolio public s_deployPortfolio;
    PortfolioBalance public s_currenctCashAvailable;
    HelperScript public s_script;
    PortfolioHarness public s_portfolioHarness;
    address public admin = address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
    address public alice = makeAddr("kyc-role");
    IContractStruct.RequestData public s_requestData;
    IContractStruct.RequestConfig public s_requestConfig;
    function setUp() public {
        vm.prank(admin);
        s_deployPortfolio = new DeployPortfolio();
        (s_currenctCashAvailable , s_script) = s_deployPortfolio.run(admin);
        ( s_requestData , s_requestConfig) = s_script.getNetworkConfig();
        s_portfolioHarness = new PortfolioHarness(admin , s_requestData , s_requestConfig);
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
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);

        vm.startPrank(alice);
        bytes32 reuqestId = s_portfolioHarness.expose_sendRequest();
        bytes32 latestRequestId = s_portfolioHarness.getLatestRequestId();
        vm.stopPrank();
        assertEq(reuqestId, latestRequestId);
        console.logBytes32(reuqestId);
    }

    function testRequestIdNotFound() public {
        vm.expectRevert(PortfolioBalance.PortfolioBalance__RequestIdNotFound.selector);
        s_portfolioHarness.expose_fulfillRequest(bytes32("invalidRequestId"), bytes("0x1234"),"");
    }
    
    function testErrorFromOracle() public {
        vm.prank(admin);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);

        vm.startPrank(alice);
        bytes32 reuqestId = s_portfolioHarness.expose_sendRequest();
        vm.stopPrank();

        vm.expectRevert(abi.encodeWithSelector(PortfolioBalance.PortfolioBalance__ErrorFromOracle.selector, bytes("0x1234")));
        s_portfolioHarness.expose_fulfillRequest(reuqestId, bytes(""), bytes("0x1234"));
    }

    function testFulfillRequest() public {
        vm.prank(admin);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);

        vm.startPrank(alice);
        bytes32 reuqestId = s_portfolioHarness.expose_sendRequest();
        vm.stopPrank();

        uint256 newBalance = 1000;
        bytes memory response = abi.encode(newBalance);
        s_portfolioHarness.expose_fulfillRequest(reuqestId, response, bytes(""));
        assertEq(s_portfolioHarness.getbalance(), newBalance);
    }

    function testCheckUpkeep() public {
        vm.prank(admin);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);
        vm.warp(block.timestamp + 43200);
        vm.startPrank(alice);
        (bool upkeepNeeded, ) = s_portfolioHarness.expose_checkUpkeep("");
        vm.stopPrank();
        assertTrue(upkeepNeeded);
    }

    /// * check upkeep test by making performUpkeep test
    /// * make performUpkeep test
    /// * make sure the sendRequest is called after upakeep is performed
    /// * use assert to check the requestID after the performUpkeep is called
    function testPerformUpkeep() public {
        vm.prank(admin);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);

        vm.warp(block.timestamp + 43200);
        vm.startPrank(alice);
        console.logBytes32(s_currenctCashAvailable.getLatestRequestId());
        s_currenctCashAvailable.performUpkeep("");
        vm.stopPrank();
        bytes32 latestRequestId = s_currenctCashAvailable.getLatestRequestId();
        console.logBytes32(latestRequestId);
        assertNotEq(latestRequestId, s_portfolioHarness.getLatestRequestId());
        vm.stopPrank();
    }

    function testFulfillRequestAfterUpkeep() public {
        vm.prank(admin);
        IRWAAccessControl(s_requestData.accessControlAddress).grantKYCAgentRole(alice);
        vm.warp(block.timestamp + 43200);
        vm.startPrank(alice);
        s_currenctCashAvailable.performUpkeep("");
        bytes32 reuqestId = s_currenctCashAvailable.getLatestRequestId();
        console.logBytes32(reuqestId);
        vm.stopPrank();
        bytes memory mockResponse = abi.encode(uint256(15500));
        vm.prank(s_requestData.router);
        s_currenctCashAvailable.handleOracleFulfillment(reuqestId, mockResponse,  bytes(""));
        console.log("Current Cash Available Balance: ", s_currenctCashAvailable.getbalance());

        vm.prank(alice);
        s_currenctCashAvailable.getbalance();
        assertEq(s_currenctCashAvailable.getbalance(), 15500);
    }
}
