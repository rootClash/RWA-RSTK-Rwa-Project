// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DeployPriceOracle} from "../../script/DeployPriceOracle.sol";
import {PriceOracle} from "../../src/Oracle/PriceOracle.sol";
import {RWAAccessControl} from "../../src/access/RWAAccessControl.sol";
import {
    HelperScript
} from "../../script/Helper/HelperScript.s.sol";
import {IPriceOracle} from "../../src/Oracle/IPriceOracle.sol";
contract PriceOracleTest is Test {
    PriceOracle public s_priceOracle;
    DeployPriceOracle public s_deployPriceOracle;
    RWAAccessControl public s_accessControl;
    HelperScript public s_scriptPriceOracle;
    address public admin = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address alice = makeAddr("kyc-role");
    string public constant SOURCE = "./functions/source/source.js";
    function setUp() public {
        s_accessControl = new RWAAccessControl(admin);
        s_scriptPriceOracle = new HelperScript(SOURCE);
        s_deployPriceOracle = new DeployPriceOracle();
        s_priceOracle = s_deployPriceOracle.run(address(s_accessControl));
    }

    /*//////////////////////////////////////////////////////////////
                                SETPRICE
    //////////////////////////////////////////////////////////////*/
    function testSetPrice() public {
        uint256 expectedPrice = 100;
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.startPrank(alice);
        vm.warp(3600);
        vm.expectEmit(false, false, false, true, address(s_priceOracle));
        emit PriceOracle.PriceUpdated(expectedPrice, block.timestamp);
        s_priceOracle.setPrice(expectedPrice);
        vm.stopPrank();
        uint256 actualPrice = s_priceOracle.getPrice();
        assertEq(
            expectedPrice * 10 ** 8,
            actualPrice,
            "The price should be set correctly in the PriceOracle contract."
        );
    }

    function testPriceAlreadyExist() public {
        uint256 expectedPrice = 100;
        bytes32 requestId = keccak256(abi.encodePacked("testRequestId"));
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.warp(3600);
        vm.prank(alice);
        s_priceOracle.setPrice(expectedPrice);

        vm.prank(alice);
        vm.expectRevert(
            PriceOracle.PriceOracle__HeartbeatNotReached.selector
        );
        s_priceOracle.setPrice(expectedPrice);
    }

    /*//////////////////////////////////////////////////////////////
                        SENDREQUEST
    //////////////////////////////////////////////////////////////*/
    function testSendRequest() public {
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.prank(alice);
        s_priceOracle.sendRequest();
        console.logBytes32(s_priceOracle.getLatestRequestId());
        bytes32 requestId = s_priceOracle.getLatestRequestId();
        console.log(
            "The current Price is : ",
            s_priceOracle.getPrice()
        );
        assertEq(s_priceOracle.getPrice(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                        FULFILLREQUEST
    //////////////////////////////////////////////////////////////*/
    function testFulfillRequestSuccess() public {
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.prank(alice);
        s_priceOracle.sendRequest();
        bytes32 requestId = s_priceOracle.getLatestRequestId();

        uint256 simulatedPrice = 50000;
        bytes memory response = abi.encode(simulatedPrice);
        bytes memory err = "";

        address _router = address(s_deployPriceOracle.s_mockRouter());

        vm.expectEmit(false, false, false, true, address(s_priceOracle));
        emit PriceOracle.PriceFetchedAndUpdated(
            requestId,
            simulatedPrice,
            block.timestamp
        );

        vm.prank(_router);
        s_priceOracle.handleOracleFulfillment(requestId, response, err);

        assertEq(s_priceOracle.getPrice(), simulatedPrice);
    }

    function testFulfillRequestRevertsOnWrongRequestId() public {
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.prank(alice);
        s_priceOracle.sendRequest();

        bytes32 wrongRequestId = keccak256(abi.encodePacked("wrongId"));
        bytes memory response = abi.encode(uint256(50000));
        bytes memory err = "";
        address router = address(s_deployPriceOracle.s_mockRouter());

        vm.prank(router);
        vm.expectRevert(PriceOracle.PriceOracle__RequestIdNotFound.selector);
        s_priceOracle.handleOracleFulfillment(wrongRequestId, response, err);
    }

    function testFulfillRequestRevertsOnError() public {
        vm.prank(address(admin));
        s_accessControl.grantKYCAgentRole(alice);

        vm.prank(alice);
        s_priceOracle.sendRequest();
        bytes32 requestId = s_priceOracle.getLatestRequestId();

        bytes memory response = "";
        bytes memory err = "API limit reached";
        address router = address(s_deployPriceOracle.s_mockRouter());

        vm.prank(router);
        vm.expectRevert(
            bytes(string(abi.encodePacked("Error from oracle: ", string(err))))
        );
        s_priceOracle.handleOracleFulfillment(requestId, response, err);
    }

    /*//////////////////////////////////////////////////////////////
                        UNAUTHORIZED ACCESS
    //////////////////////////////////////////////////////////////*/
    function testSetPriceRevertsIfNotAuthorized() public {
        uint256 expectedPrice = 100;
        address bob = makeAddr("bob");
        vm.prank(bob);
        vm.expectRevert();
        s_priceOracle.setPrice(expectedPrice);
    }

    function testSendRequestRevertsIfNotAuthorized() public {
        address bob = makeAddr("bob");

        vm.prank(bob);
        vm.expectRevert(); // Expect an AccessControl revert or a custom error from the oracle
        s_priceOracle.sendRequest();
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/
    function testGetPriceForNonExistentRequest() view public {
        uint256 price = s_priceOracle.getPrice();
        assertEq(price, 0, "Price should be 0 for a non-existent request ID.");
    }

    function testGetLatestRequestIdBeforeAnyRequest() view public {
        bytes32 requestId = s_priceOracle.getLatestRequestId();
        assertEq(
            requestId,
            bytes32(0),
            "Latest request ID should be bytes32(0) initially."
        );
    }
}
