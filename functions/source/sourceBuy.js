if(!secrets.alpacaApiKey && !secrets.alpacaSecretKey){
    throw Error(
        "ALPACA API_KEY and SECRET_KEY must be provided"
    );
}

const alpacaRequest = Functions.makeHttpRequest({
    url:`https://paper-api.alpaca.markets/v3/clock?markets=NYSE`,
    headers: { // API keys should be in the 'headers' object
        'APCA-API-KEY-ID': secrets.alpacaApiKey,
        'APCA-API-SECRET-KEY': secrets.alpacaSecretKey,
    },
})

const alpacaRequestOnBuy = Functions.makeHttpRequest({
    
})

const AlpacaResponse = await alpacaRequest;
if(AlpacaResponse.error){
    throw new Error("Alpaca Error : " + AlpacaResponse.error.message);
}
console.log("Data:", JSON.stringify(AlpacaResponse.data["clocks"][0]["is_market_day"]));

const state = AlpacaResponse.data["clocks"][0]["is_market_day"];
if(state == false){
    return Functions.encodeUint256(0);
}
const marketPhase = AlpacaResponse.data["clocks"][0]["phase"];
console.log("market Phase : ",marketPhase);
const phase = marketPhase === "open" ? 1 : -1;
if(phase == -1){
    return Functions.encodeUint256(phase);
}


return Functions.encodeUint256(phase);

