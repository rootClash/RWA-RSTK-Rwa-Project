// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Allowlist} from "../src/allowlist/Allowlist.sol";
import {Script} from "forge-std/Script.sol";

contract DeployAllowlist is Script{
    function run(address rwaAccessControl,address sanctionsList) public returns(Allowlist){
        vm.startBroadcast();
        Allowlist allowlist = new Allowlist(rwaAccessControl,sanctionsList);
        vm.stopBroadcast();
        return allowlist;
    }
}