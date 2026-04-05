
if (!secrets.alpacaApiKey && !secrets.alpacaSecretKey) {
    throw Error(
        "ALPACA API_KEY and SECRET_KEY must be provided"
    );
}

if (!args || args.length < 1) {
    throw Error("Missing arguments. Expected args[0] for symbol and args[1] for notional.");
}

const notionalAmount = args[0];

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
        "side": "buy",
        "notional": notionalAmount
    }
})
const AlpacaResponseOnBuy = await alpacaRequestOnBuy;
if (AlpacaResponseOnBuy.error) {
    throw new Error("Alpaca Error : " + AlpacaResponseOnBuy.error.message);
}
console.log("Data alpca buy:", JSON.stringify(AlpacaResponseOnBuy.data));
return Functions.encodeString(AlpacaResponseOnBuy.data["client_order_id"]);

