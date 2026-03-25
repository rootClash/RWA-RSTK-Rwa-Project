const fs = require("fs");
require("@chainlink/env-enc").config(); // unlock the secrets first
const { Location, ReturnType, CodeLanguage } = require("@chainlink/functions-toolkit");

const requireConfig = {
    codeLocation: Location.Inline,
    secrets: { alpacaApiKey: process.env.ALPACA_API_KEY, alpacaSecretKey: process.env.ALPACA_SECRET_KEY },
    args : [],
    secretsLocation: Location.DONHosted,
    codeLanguage: CodeLanguage.Javascript,
    expectedReturnType: ReturnType.uint256
}

module.exports = requireConfig