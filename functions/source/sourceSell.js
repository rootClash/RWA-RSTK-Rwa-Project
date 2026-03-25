
if (!secrets.alpacaApiKey && !secrets.alpacaSecretKey) {
    throw Error(
        "ALPACA API_KEY and SECRET_KEY must be provided"
    );
}

if (!args || args.length === 0) {
    throw Error("Missing arguments. Expected args[0] for symbol and args[1] for notional.");
}

const quantity = args[0];

const alpacaRequest = Functions.makeHttpRequest({
    url: `https://paper-api.alpaca.markets/v3/clock?markets=NYSE`,
    headers: { // API keys should be in the 'headers' object
        'APCA-API-KEY-ID': secrets.alpacaApiKey,
        'APCA-API-SECRET-KEY': secrets.alpacaSecretKey,
    },
})



const AlpacaResponse = await alpacaRequest;

if (AlpacaResponse.error) {
    throw new Error("Alpaca Error : " + AlpacaResponse.error.message);
}
console.log("Data:", JSON.stringify(AlpacaResponse.data["clocks"][0]["is_market_day"]));

const state = AlpacaResponse.data["clocks"][0]["is_market_day"];
if (state == false) {
    return Functions.encodeUint256(0);
}
const marketPhase = AlpacaResponse.data["clocks"][0]["phase"];
console.log("market Phase : ", marketPhase);
const phase = marketPhase === "core" ? 1 : 0;

if (phase == 0) {
    return Functions.encodeUint256(phase);
}
const alpacaRequestOnBuy = Functions.makeHttpRequest({
    url: `https://paper-api.alpaca.markets/v2/orders`,
    headers: { // API keys should be in the 'headers' object
        'APCA-API-KEY-ID': secrets.alpacaApiKey,
        'APCA-API-SECRET-KEY': secrets.alpacaSecretKey,
    },
    method: "POST",
    data: {
        "type": "market",
        "time_in_force": "day",
        "symbol": "RSST",
        "side": "sell",
        "qty": quantity
    }
})
const AlpacaResponseOnBuy = await alpacaRequestOnBuy;
if (AlpacaResponseOnBuy.error) {
    throw new Error("Alpaca Error : " + AlpacaResponseOnBuy.error.message);
}
console.log("Data alpca buy:", JSON.stringify(AlpacaResponseOnBuy.data));
return Functions.encodeUint256(phase);

