let ethers = await import("npm:ethers@6.10.0");
if (!secrets.alpacaApiKey && !secrets.alpacaSecretKey) {
    throw Error(
        "ALPACA API_KEY and SECRET_KEY must be provided"
    );
}

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

const marketPhase = AlpacaResponse.data["clocks"][0]["next_market_open"];
const marketClose = AlpacaResponse.data["clocks"][0]["next_market_close"];
console.log("value : type " , typeof marketPhase);
console.log("market Phase : ", marketPhase);
console.log("market close : ",marketClose);
const nextOpenUnix = Math.floor(new Date(marketPhase).getTime() / 1000);
const nextCloseUnix = Math.floor(new Date(marketClose).getTime() / 1000);
console.log("market time of open : ",nextOpenUnix)
console.log("market time of close : ", nextCloseUnix)
const encoded = ethers.AbiCoder.defaultAbiCoder().encode(
    ["bool", "uint256", "uint256"],
    [state, nextOpenUnix, nextCloseUnix]
);
return ethers.getBytes(encoded);