// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
import {MockV3Aggregator} from "@chainlink/contracts/src/v0.8/tests/MockV3Aggregator.sol";
import {MockERC20} from "@chainlink/contracts/src/v0.8/vendor/forge-std/src/mocks/MockERC20.sol";


contract TokenScript is IContractStruct {
    mapping(uint256 => IContractStruct.ExtraInfo) public s_networks;
    address constant ANVIL_ADMIN = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    constructor(){
        if(block.chainid == 11155111){
            s_networks[block.chainid] = getSepoliaInfo();
        }else{
            s_networks[block.chainid] = getAnvilInfo();
        }
    }
    function getNetworkConfig()
        external
        view
        returns (
            IContractStruct.ExtraInfo memory
        )
    {
        return s_networks[block.chainid];
    }


    function getSepoliaInfo() internal pure returns (IContractStruct.ExtraInfo memory extraInfo) {
        extraInfo = ExtraInfo({
            aggregator: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E,
            precision: 1e18,
            usdc : address(0), /// make sure to change this,
            srstkTokenAddr : address(0), // change this
            priceOracleAddr : address(0), // change this
            owner : address(0),// change this
            portfolioContractAddr : address(0)
        });
    }
    /// eska es contract ka jo owner hoga wo tokenScriphoga
    function getAnvilInfo() internal returns (IContractStruct.ExtraInfo memory extraInfo) {
        MockERC20 mockERC20 = new MockERC20();
        mockERC20.initialize("USDC", "USDC", 6);
        extraInfo = ExtraInfo({
            aggregator: address(new MockV3Aggregator(8, 1e8)),
            precision: 1e18,
            usdc : address(mockERC20), /// make sure to change this for anvil,
            srstkTokenAddr : address(0),
            priceOracleAddr : address(0), // change this for anvil
            owner : ANVIL_ADMIN,
            portfolioContractAddr : address(0) // change this for anvil
        });
    }
}