// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {PortfolioBalance} from "../../src/automation/PortfolioBalance.sol";
import {IContractStruct} from "../../src/RSTK/IContractStruct.sol";

contract PortfolioHarness is PortfolioBalance {
    constructor(address owners , IContractStruct.RequestData memory requestData , IContractStruct.RequestConfig memory config) PortfolioBalance(owners , requestData , config){}

    function expose_sendRequest() public returns(bytes32){
        bytes32 requestId = sendRequest();
        return requestId;
    }
    function expose_checkUpkeep(bytes calldata checkData) public returns(bool , bytes memory){
        return checkUpkeep(checkData);
    }

    function expose_fulfillRequest(bytes32 requestId , bytes memory response , bytes memory err) public {
        fulfillRequest(requestId , response , err);
    }
}