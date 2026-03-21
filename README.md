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

