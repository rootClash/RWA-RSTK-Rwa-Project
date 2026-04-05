# FunctionsRequest
* used for converting the data by encoding in CBOR format
# FunctionClient
*used for interaction with client side by sending the request and receiving the response
## we have to make a Oracle contract that will fetch the Price of the RSST bond stock

## Contract Address of RWAAccessControl: 0x8E0f7731485F2086f5e1F9B9a6D401D3d4b57770
## Owner of the RWAAccessControl: One metioned in .env

### Price Oracle Test should be change  because :
* 1. requestId for every request has been changed.
* 2. no struct for every requestId
* 3. requestId from the setPRice has been Removed

### made change in the PriceOracel Successfuly

##### have not used the "Market" struct of IContractStruct.sol = main purpose to get the status of market

### made change in the IContractStruct.sol in Reddeemer and Depositor

## completed the sendMintRequest

## Redeem
## sendRedeemFunctoion

=> add the js script
## transaction check nhi kiya esko check kro in sendMintFunction --- ✅
## start from adding the automation in PortfolioBalance.sol and test it and add the sendRedeemRequest and js also in chainlink function

* add the automation in the contract ✅ done
-> function in script for the  ✅ done
* test the contract -> kal krunga
* continue withdraw function 
* add the js script  🕧
* test it
* Request Data se source , args , bytesData hataya hun.
## track the user balance => collect everything => buy form the market => and distribute to the user who requested
# test mein 
Error (7920): Identifier not found or not unique.
  --> test/unit/SRSTKTest.t.sol:16:9:
   |
16 |         IPriceOracle.RequestData memory config= s_scriptPriceOracle.s_config(block.chainid);
### solved the above error
* started working on the main contract 

bhai dur nhi hun apne Abhi tk ka main Project se
# error : non contract address issue ....
solved this porblem 😄 
# error : encountered another problem ....
[FAIL: SRSTK__InsufficientCollateral()] test_sendRequest() (gas: 142119)
### solved the above issue and continue with the main contract
## working on the Redeem Token
## finally completed the sendRequest , buyToken , redeemToken functions 
##### now its time to add the sellToken . completed the sendBuyToken 