// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRWAAccessControl {
    event RoleAssigned(string name, address indexed role);

    // Added (address account) to match your contract implementation
    function grantPauserRole(address account) external;
    function grantUpgraderRole(address account) external;
    function grantMinterRole(address account) external;
    function grantBurnerRole(address account) external;
    function grantKYCAgentRole(address account) external;

    function isAdmin(address account) external view returns (bool);
    function isMinter(address account) external view returns (bool);
    function isUpgrader(address account) external view returns (bool);
    function isBurner(address account) external view returns (bool);
    function isPauser(address account) external view returns (bool);
    function isKYCAgentRole(address account) external view returns (bool);
}
