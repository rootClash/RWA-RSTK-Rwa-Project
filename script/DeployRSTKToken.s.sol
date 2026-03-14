// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {RSTKToken} from "../src/RSTK/token/RSTKToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRSTKToken is Script{
    function run(address rwaAccessControl) public returns(RSTKToken){
        vm.startBroadcast();
        RSTKToken rstkToken = new RSTKToken(rwaAccessControl);
        vm.stopBroadcast();
        return rstkToken;
    }
}