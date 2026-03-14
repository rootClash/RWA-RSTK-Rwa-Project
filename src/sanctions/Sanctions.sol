// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}
contract Sanactions {
    address constant SANCTIONS_CONTRACT = 0x40C57923924B5c5c5455c48D93317139ADDaC8fb;

    function checkSan(address to) external returns(bool){
        SanctionsList sanctionsList = SanctionsList(SANCTIONS_CONTRACT);
        bool isToSanctioned = sanctionsList.isSanctioned(to);
        return isToSanctioned;
    }
}