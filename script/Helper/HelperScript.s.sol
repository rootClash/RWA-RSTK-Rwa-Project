// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";
import {RWAAccessControl} from "../../src/access/RWAAccessControl.sol";
import {mockRouter} from "../../test/mock/mockRouter.sol";
import {RWAAccessControl} from "../../src/access/RWAAccessControl.sol";

contract HelperScript is Script {
    RWAAccessControl public s_accessControl;
    error HelperScript__InvalidNetwork();

    mapping(uint256 => IContractStruct.RequestData) public s_networks;
    mapping(uint256 => IContractStruct.RequestConfig) public s_configs;

    constructor(string memory source) {
        if (block.chainid == 11155111) {
            (
                s_networks[block.chainid],
                s_configs[block.chainid]
            ) = getSepoliaConfig(source);
        } else if (block.chainid == 31337) {
            (
                s_networks[block.chainid],
                s_configs[block.chainid]
            ) = getAnvilConfig(source);
        } else {
            revert HelperScript__InvalidNetwork();
        }
    }

    function getNetworkConfig()
        external
        view
        returns (
            IContractStruct.RequestData memory,
            IContractStruct.RequestConfig memory
        )
    {
        return (s_networks[block.chainid], s_configs[block.chainid]);
    }

    function getSepoliaConfig(string memory source)
        public
        pure
        returns (
            IContractStruct.RequestData memory sepoliaConfig,
            IContractStruct.RequestConfig memory config
        )
    {
        sepoliaConfig = IContractStruct.RequestData({
            donHostedSecretsSlotID: 0,
            donHostedSecretsVersion: 1775119765,
            subscriptionId: 6299,
            gasLimit: 300_000,
            donID: hex"66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000",
            router: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0,
            accessControlAddress: 0x8E0f7731485F2086f5e1F9B9a6D401D3d4b57770
        });
        config = IContractStruct.RequestConfig({
            source: source,
            args: new string[](0),
            bytesArgs: new bytes[](0)
        });
    }

    function getAnvilConfig(string memory source)
        public
        returns (
            IContractStruct.RequestData memory anvilConfig,
            IContractStruct.RequestConfig memory config
        )
    {
        anvilConfig = IContractStruct.RequestData({
            router: address(new mockRouter()),
            accessControlAddress: address(new RWAAccessControl(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38)),
            donHostedSecretsSlotID: 0,
            donHostedSecretsVersion: 0,
            subscriptionId: 1,
            gasLimit: 300_000,
            donID: bytes32("fun-ethereum-sepolia-1")
        });
        config = IContractStruct.RequestConfig({
            source: source,
            args: new string[](0),
            bytesArgs: new bytes[](0)
        });
    }
}
