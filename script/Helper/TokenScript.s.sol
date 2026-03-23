// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
contract TokenScript is IContractStruct {
    mapping(uint256 => IContractStruct.ExtraInfo) public s_networks;
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

    function getAnvilInfo() internal pure returns (IContractStruct.ExtraInfo memory extraInfo) {
        extraInfo = ExtraInfo({
            aggregator: address(0),
            precision: 1e18,
            usdc : address(0), /// make sure to change this for anvil,
            srstkTokenAddr : address(0),
            priceOracleAddr : address(0), // change this for anvil
            owner : address(0),//// change this
            portfolioContractAddr : address(0) // change this for anvil
        });
    }
}