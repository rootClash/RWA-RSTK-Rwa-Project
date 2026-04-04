const fs = require("fs");
const requestConfig = require("../config/alpacaConfig.js");
const { simulateScript, decodeResult, SubscriptionManager, SecretsManager, ResponseListener, ReturnType, FulfillmentCode } = require("@chainlink/functions-toolkit");
require("@chainlink/env-enc").config();
const ethers = require("ethers");
const { fileURLToPath } = require("url");

async function main() {
    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const privateKey = process.env.PRIVATE_KEY;
    const routerAddr = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"
    const donId = "fun-ethereum-sepolia-1"
    const gatewayUrls = [
        "https://01.functions-gateway.testnet.chain.link/",
        "https://02.functions-gateway.testnet.chain.link/",
    ];
    const slotIdNumber = 0; 
    const expirationTimeMinutes = 1240; 
    console.log("Secrets type check:", typeof requestConfig.secrets);
    console.log("Secrets keys:", Object.keys(requestConfig.secrets));
    console.log("Secret values are strings?",
        Object.values(requestConfig.secrets).every(v => typeof v === "string")
    );
    console.log("Started Execution...")
    const sourceArg = [
        { source: fs.readFileSync("./functions/source/source.js", "utf8"), args: [],fileType : "standard" },
        { source: fs.readFileSync("./functions/source/sourcePortfolio.js", "utf8"), args: [],fileType : "standard" },
        { source: fs.readFileSync("./functions/source/sourceBuy.js", "utf8"), args: ["56.84"] , fileType : "standard"},
        { source: fs.readFileSync("./functions/source/sourceSell.js", "utf8"), args: ["1"],fileType : "standard" },
        { source: fs.readFileSync("./functions/source/sourceMarketPhase.js", "utf8"), args: [] ,fileType : "abi"},
    ]

    const SimulationParameter = sourceArg.map(item =>
        simulateScript({
            source: item.source,
            args: item.args || requestConfig.args,
            secrets: requestConfig.secrets
        }))
    const results = await Promise.all(SimulationParameter);
    results.forEach((result, index) => {
        if (result.errorString) {
            console.error(`Simulation ${index} failed:`, result.errorString)
        } else {
            console.log("=== Terminal Output ===");
            console.log(result.capturedTerminalOutput);
            console.log("=== Response ===")
            if (result.responseBytesHexstring) {
                if(sourceArg[index].fileType === "abi") {
                    const abiCoder = ethers.utils.defaultAbiCoder;
                    const decoded = abiCoder.decode(
                        ["bool", "uint256", "uint256"],
                        result.responseBytesHexstring
                    );

                    const isOpen = decoded[0];
                    const nextOpen = decoded[1].toNumber();           
                    const nextClose = decoded[2].toNumber();

                    console.log("Is market open:", isOpen);
                    console.log("Next open:     ", nextOpen);
                    console.log("Next close:    ", nextClose);
                }else{
                    console.log("Response (hexstring) : ", decodeResult(result.responseBytesHexstring, requestConfig.expectedReturnType).toString());
                }
            }
        }
    })
    const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);
    const signer = wallet.connect(provider);

    console.log("Started encrypting the script and uploading to Don ....")
    const secretManager = new SecretsManager({
        signer,
        functionsRouterAddress: routerAddr,
        donId
    })
    await secretManager.initialize()
    const keys = await secretManager.fetchKeys()
    console.log("full keys object:", JSON.stringify(keys)) 
    console.log("public key after Sending the request", keys.donPublicKey)
    const encryptedSecretObj = await secretManager.encryptSecrets(requestConfig.secrets)
    console.log(
        `Upload encrypted secret to gateways ${gatewayUrls}. slotId ${slotIdNumber}. Expiration in minutes: ${expirationTimeMinutes}`
    );

    const { version, success } = await secretManager.uploadEncryptedSecretsToDON({
        encryptedSecretsHexstring: encryptedSecretObj.encryptedSecrets,
        gatewayUrls,
        slotId: slotIdNumber,
        minutesUntilExpiration: expirationTimeMinutes
    });
    if (!success) {
        console.log("Message Could not able to Encrypt")
    }

    console.log(
        `\n✅ Secrets uploaded properly to gateways ${gatewayUrls}! Gateways response: `,
        version.toString()
    );

    const donHostIdVersionNumber = parseInt(version)
    console.log("The Don Host ID Version is  : ", donHostIdVersionNumber);
}

main().catch((error) => {
    console.log(error);
    process.exitCode = 1
})
