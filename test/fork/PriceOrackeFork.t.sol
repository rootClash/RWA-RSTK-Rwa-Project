// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployPriceOracle} from "../../script/DeployPriceOracle.sol";
import {PriceOracle} from "../../src/Oracle/PriceOracle.sol";
import {
    ScriptForPriceOracle
} from "../../script/Helper/ScriptForPriceOracle.s.sol";
import {IPriceOracle} from "../../src/Oracle/IPriceOracle.sol";
import {IRWAAccessControl} from "../../src/access/IRWAAccessControl.sol";
import {
    IFunctionsSubscriptions
} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsSubscriptions.sol";

contract PriceOracleForkTest is Test {
    PriceOracle public s_priceOracle;
    DeployPriceOracle public s_deployPriceOracle;
    ScriptForPriceOracle public s_scriptPriceOracle;
    address alice = makeAddr("kyc-role");
    uint256 forkID;
    string rpcURL = vm.envString("SEPOLIA_RPC_URL");
    address mainAdmin = vm.envAddress("PUBLIC_KEY");
    address accessControlAddress;
    address routerAddr;
    uint64 subscriptionId;

    function setUp() public {
        forkID = vm.createSelectFork(rpcURL);
        vm.selectFork(forkID);
        s_scriptPriceOracle = new ScriptForPriceOracle();
        s_deployPriceOracle = new DeployPriceOracle();
        s_priceOracle = s_deployPriceOracle.run(address(0));
        (, // 1 - string source        (dynamic, still counts as slot)
            , // 2 - uint8  donHostedSecretsSlotID
            , // 3 - uint64 donHostedSecretsVersion
            subscriptionId, // 4 - uint64 subscriptionId  ← capture
            , // 5 - uint32 gasLimit
            , // 6 - bytes32 donID
            routerAddr, // 7 - address router         ← capture
            accessControlAddress // 8 - address accessControlAddress ← capture
        ) = s_scriptPriceOracle.s_networks(block.chainid);
        vm.label(address(s_priceOracle), "PriceOracle");
        vm.label(mainAdmin, "MainAdmin");
        vm.label(alice, "Alice");
    }

    function testForkedPriceOracle() public view {
        assertEq(vm.activeFork(), forkID);
    }

    function testSendRequestWithFork() public {
        vm.startPrank(address(mainAdmin));
        IRWAAccessControl(accessControlAddress).grantKYCAgentRole(alice);
        IFunctionsSubscriptions(routerAddr).addConsumer(
            subscriptionId,
            address(s_priceOracle)
        );
        vm.stopPrank();

        vm.startPrank(alice);
        s_priceOracle.sendRequest();
        bytes32 latestRequestId = s_priceOracle.getLatestRequestId();
        vm.stopPrank();

        // call the fullfilment function
        vm.startPrank(address(routerAddr));
        s_priceOracle.handleOracleFulfillment(latestRequestId, abi.encode(bytes32(uint256(200))), "");
        vm.stopPrank();
        vm.prank(alice);
        uint256 price = s_priceOracle.getPrice();
        console.log("Price for the latest request ID:", price);
        console.logBytes32(latestRequestId);
        assertTrue(
            latestRequestId != bytes32(0),
            "Latest request ID should not be zero after sending a request."
        );
    }
}
