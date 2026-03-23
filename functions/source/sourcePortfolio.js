/// i have to create this
if(!secrets.alpacaApiKey && !secrets.alpacaSecretKey){
    throw Error(
        "ALPACA API_KEY and SECRET_KEY must be provided"
    );
}
const alpacaRequest = Functions.makeHttpRequest({
    url:`https://paper-api.alpaca.markets/v2/account`,
    headers: { // API keys should be in the 'headers' object
        'APCA-API-KEY-ID': secrets.alpacaApiKey,
        'APCA-API-SECRET-KEY': secrets.alpacaSecretKey,
    },
})
const AlpacaResponse = await alpacaRequest;
if(AlpacaResponse.error){
    throw new Error("Alpaca Error : " + AlpacaResponse.error.message);
}
const lastEquity = AlpacaResponse.data.cash;
return Functions.encodeUint256(Math.round(lastEquity * 1e8));

