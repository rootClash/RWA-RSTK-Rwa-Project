// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {RWAAccessControl} from "../src/access/RWAAccessControl.sol";
import {Allowlist} from "../src/allowlist/Allowlist.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRWAAccessControl is Script{
    function run(address admin) public returns(RWAAccessControl){
        vm.startBroadcast();
        RWAAccessControl rwaAccessControl = new RWAAccessControl(admin);
        vm.stopBroadcast();
        return rwaAccessControl;
    }
}