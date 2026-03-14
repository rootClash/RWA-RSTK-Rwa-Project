// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRWAAccessControl} from "./IRWAAccessControl.sol";
import {
    AccessControlDefaultAdminRules
} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

/// @title RWAAccessControl contract
/// @author hackFlu
/// @dev a contract to set the access control
contract RWAAccessControl is IRWAAccessControl, AccessControlDefaultAdminRules {
    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLE
    //////////////////////////////////////////////////////////////*/
    bytes32 public constant KYC_AGENT_ROLE = keccak256("KYC_AGENT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    uint48 public constant THREE_DAYS = 3 * 24 * 60 * 60;

    /*//////////////////////////////////////////////////////////////
                                  ERROR
    //////////////////////////////////////////////////////////////*/
    error RWAAccessControl__InvalidAddress();
    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier validAddress(address account) {
        if (account == address(0)) revert RWAAccessControl__InvalidAddress();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address admin) AccessControlDefaultAdminRules(THREE_DAYS, admin) {
        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(KYC_AGENT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /*//////////////////////////////////////////////////////////////
                                FUNCTION
    //////////////////////////////////////////////////////////////*/

    function grantPauserRole(address account) external validAddress(account) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(PAUSER_ROLE, account);
        emit RoleAssigned("Pause Role", account);
    }

    function grantUpgraderRole(address account) external validAddress(account) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(UPGRADER_ROLE, account);
        emit RoleAssigned("Upgradeable Role", account);
    }

    function grantMinterRole(address account) external validAddress(account) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
        emit RoleAssigned("Minter Role", account);
    }

    function grantBurnerRole(address account) external validAddress(account) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BURNER_ROLE, account);
        emit RoleAssigned("Burner role", account);
    }

    function grantKYCAgentRole(address account) external validAddress(account) onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(KYC_AGENT_ROLE, account);
        emit RoleAssigned("KYCAgent Role", account);
    }

    function isAdmin(address account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isUpgrader(address account) external view returns (bool) {
        return hasRole(UPGRADER_ROLE, account);
    }

    function isMinter(address account) external view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    function isBurner(address account) external view returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    function isPauser(address account) external view returns (bool) {
        return hasRole(PAUSER_ROLE, account);
    }
    function isKYCAgentRole(address account) external view returns (bool) {
        return hasRole(KYC_AGENT_ROLE, account);
    }
}
