const requestConfig = require("../config/alpacaConfig.js");
const { simulateScript, decodeResult, SubscriptionManager, SecretsManager, ResponseListener, ReturnType, FulfillmentCode } = require("@chainlink/functions-toolkit");
require("@chainlink/env-enc").config();
const ethers = require("ethers");

async function main() {
    const rpcUrl = process.env.SEPOLIA_RPC_URL;
    const privateKey = process.env.PRIVATE_KEY;
    const routerAddr = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0"
    const donId = "fun-ethereum-sepolia-1"
    const gatewayUrls = [
        "https://01.functions-gateway.testnet.chain.link/",
        "https://02.functions-gateway.testnet.chain.link/",
    ];
    const slotIdNumber = 0; // slot ID where to upload the secrets
    const expirationTimeMinutes = 15; // expiration time in minutes of the secrets
    console.log("Secrets type check:", typeof requestConfig.secrets);
    console.log("Secrets keys:", Object.keys(requestConfig.secrets));
    console.log("Secret values are strings?",
        Object.values(requestConfig.secrets).every(v => typeof v === "string")
    );
    console.log("Started Execution...")
    const { responseBytesHexstring, errorString, capturedTerminalOutput } = await simulateScript({
        source: requestConfig.source,
        args: requestConfig.args,
        secrets: requestConfig.secrets
    });
    console.log("=== Terminal Output ===");
    console.log(capturedTerminalOutput);
    console.log("=== Response ===")
    if (responseBytesHexstring) {
        console.log("Response (hexstring) : ", decodeResult(responseBytesHexstring, requestConfig.expectedReturnType).toString());
    }
    if (errorString) {
        console.log("Error : ", errorString);
    }

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
    console.log("full keys object:", JSON.stringify(keys)) // log the whole object
    console.log("public key after Sending the request", keys.publicKey)
    const encryptedSecretObj = await secretManager.encryptSecrets(requestConfig.secrets)
    console.log(
        `Upload encrypted secret to gateways ${gatewayUrls}. slotId ${slotIdNumber}. Expiration in minutes: ${expirationTimeMinutes}`
    );

    const {version, success} = await secretManager.uploadEncryptedSecretsToDON({
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
