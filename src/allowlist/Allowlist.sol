// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {IAllowlist} from "./IAllowlist.sol";
import {IRWAAccessControl} from "../access/IRWAAccessControl.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {SanctionsList} from "../sanctions/Sanctions.sol";
contract Allowlist is IAllowlist, ReentrancyGuard {
    SanctionsList private immutable i_sanctionsList;
    IRWAAccessControl private immutable i_rwaAccessControl;
    mapping(address => bool) private checkAddress;
    address[] private s_totalAllowedAddress;
    
    event AddressAddedToAllowlist(address indexed allowedAddress);
    error Allowlist__InvalidAllowlistAddress();
    
    constructor(address rwaAccessControl,address sanctionsList) ReentrancyGuard() {
        i_rwaAccessControl = IRWAAccessControl(rwaAccessControl);
        i_sanctionsList = SanctionsList(sanctionsList);
    }
    function allowlist() external view returns (address[] memory){
        require(i_rwaAccessControl.isKYCAgentRole(msg.sender), "Not Authorized To view allowlist");
        return s_totalAllowedAddress;
    }
    function addToAllowList(address allowedAdress) external{
        require(i_rwaAccessControl.isKYCAgentRole(msg.sender), "Not Authorized To add to allowlist");
        require(!i_sanctionsList.isSanctioned(allowedAdress), "Address is sanctioned");
        require(allowedAdress != address(0), "Invalid address");
        require(!checkAddress[allowedAdress], "Address already in allowlist");
        s_totalAllowedAddress.push(allowedAdress);
        checkAddress[allowedAdress] = true;
        emit AddressAddedToAllowlist(allowedAdress);
    }

    function isAllowed(address account) external view returns (bool){
        return checkAddress[account];
    }
}
