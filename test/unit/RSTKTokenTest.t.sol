// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {RSTKToken} from "../../src/RSTK/token/RSTKToken.sol";
import {IRWAAccessControl} from "../../src/access/IRWAAccessControl.sol";
import {
    DeployRWAAccessControl
} from "../../script/DeployRWAAccessControl.s.sol";
contract RSTKTokenTest is Test {
    RSTKToken public rstkToken;
    IRWAAccessControl public rwaAccessControl;
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public minter = makeAddr("minter");
    address public burner = makeAddr("burner");
    address public pauser = makeAddr("pauser");
    function setUp() public {
        DeployRWAAccessControl deployRWAAccessControl = new DeployRWAAccessControl();
        // admin is the default account for now
        rwaAccessControl = deployRWAAccessControl.run(admin);
        rstkToken = new RSTKToken(address(rwaAccessControl));
    }

    event Paused(address account);


    function testMint() public {
        uint256 amount = 1e18;
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true, address(rwaAccessControl));
        emit IRWAAccessControl.RoleAssigned("Minter Role", minter);
        rwaAccessControl.grantMinterRole(minter);
        vm.stopPrank();
        vm.startPrank(minter);
        bool success = rwaAccessControl.isMinter(minter);
        rstkToken.mint(alice, amount);
        vm.stopPrank();
        assertTrue(success, "Not a minter");
        assertEq(rstkToken.totalSupply(), amount);
        assertEq(rstkToken.balanceOf(alice), amount);
    }

    function testBurn() public {
        uint256 amount = 1e18;
        vm.startPrank(admin);
        rwaAccessControl.grantMinterRole(minter);
        rwaAccessControl.grantBurnerRole(burner);
        vm.stopPrank();
        vm.startPrank(minter);
        bool success = rwaAccessControl.isMinter(minter);
        rstkToken.mint(alice, amount);
        vm.stopPrank();
        vm.startPrank(burner);
        bool successBurner = rwaAccessControl.isBurner(burner);
        rstkToken.burn(alice, amount);
        vm.stopPrank();
        assertTrue(success, "Not a minter");
        assertTrue(successBurner, "Not a burner");
        assertEq(rstkToken.totalSupply(), 0);
        assertEq(rstkToken.balanceOf(alice), 0);
        assertEq(successBurner, true);
        assertEq(success, true);
    }

    function testPause() public {
        uint256 amount = 1e18;
        vm.startPrank(admin);
        rwaAccessControl.grantMinterRole(minter);
        rwaAccessControl.grantPauserRole(pauser);
        vm.stopPrank();

        vm.startPrank(minter);
        bool success = rwaAccessControl.isMinter(minter);
        rstkToken.mint(alice, amount);
        vm.stopPrank();

        vm.startPrank(pauser);
        bool successPauser = rwaAccessControl.isPauser(pauser);
        vm.expectEmit(false, false, false ,true , address(rstkToken));
        emit Paused(pauser);
        rstkToken.pause();
        vm.stopPrank();
        assertTrue(success, "Not a minter");
        assertTrue(successPauser, "Not a pauser");

        assertEq(rstkToken.totalSupply(), amount);
        assertEq(rstkToken.balanceOf(alice), amount);
    }


    function testPauserWithoutRole() public {
        vm.startPrank(alice);
        vm.expectRevert("Not Authorized To pause");
        rstkToken.pause();
        vm.stopPrank();
    }

    function testPauserAfterPause() public {
        uint256 amount = 1e18;

        vm.startPrank(admin);
        rwaAccessControl.grantMinterRole(minter);
        rwaAccessControl.grantPauserRole(pauser);
        vm.stopPrank();

        vm.startPrank(minter);
        bool success = rwaAccessControl.isMinter(minter);
        rstkToken.mint(alice, amount);
        vm.stopPrank();

        vm.startPrank(pauser);
        rstkToken.pause();
        vm.stopPrank();
        vm.startBroadcast(minter);
        vm.expectRevert();
        rstkToken.transfer(alice, amount); 
        vm.stopPrank();
    }

    function testUpauseAfterPause() public {
        uint256 amount = 1e18;

        vm.startPrank(admin);
        rwaAccessControl.grantMinterRole(minter);
        rwaAccessControl.grantPauserRole(pauser);
        vm.stopPrank();

        vm.startPrank(minter);
        rstkToken.mint(alice, amount);
        vm.stopPrank();

        vm.startPrank(pauser);
        rstkToken.pause();
        vm.stopPrank();

        vm.startPrank(pauser);
        rstkToken.unpause();
        vm.stopPrank();

        vm.startPrank(minter);
        rstkToken.mint(minter, amount);
        rstkToken.transfer(alice, amount); 
        vm.stopPrank();
    }
}
