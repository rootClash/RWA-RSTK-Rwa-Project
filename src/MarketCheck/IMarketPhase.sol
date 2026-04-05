// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMarketPhase {
    function setUpkeepInterval(uint256 newInterval) external;
    function getMarketPhase() external view returns (bool ,uint256 , uint256);
}