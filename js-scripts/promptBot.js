require('dotenv').config({ path: '../.env' });
const { ethers } = require('ethers');
const abiAaveDataProvider = require('../js-scripts/abi/aaveDataProviderAbi.json');  // ABI Aave Data Provider
const abiLendingPrompt = require('../js-scripts/abi/lendingPromptAbi.json');        // ABI LendingPrompt
// const abiAILendingAggregator = require('../out/AILendingAggregator.sol/AILendingAggregator.json');  // nieaktulane - potrzebny deploy na op sepolia

const AAVE_DATA_PROVIDER = '0x501B4c19dd9C2e06E94dA7b6D5Ed4ddA013EC741';
const aggregatorAddress = '0xFB4FD631C9e4DED88526aD454e5FFBFADe55c3D7';
const lendingPromptAddress = '0xe4DC4aFe063491eFB3b5930118f8937bd1c8Ef59';
const USDC_OP_SEPOLIA = '0x5fd84259d66Cd46123540766Be93DFE6D43130D7';

// Połączenie z siecią
const provider = new ethers.AlchemyProvider("optimism-sepolia", process.env.API_KEY);
console.log('key', process.env.PRIVATE_KEY_JS)
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY_JS, provider);

// Inicjalizacja kontraktów
const aaveDataProvider = new ethers.Contract(AAVE_DATA_PROVIDER, abiAaveDataProvider, wallet);
const lendingPrompt = new ethers.Contract(lendingPromptAddress, abiLendingPrompt, wallet);
// const aggregator = new ethers.Contract(aggregatorAddress, abiAILendingAggregator, wallet);

// Formatowanie dużych liczb
function formatLargeNumber(number) {
    return ethers.formatUnits(number, 18); // Przyjęcie 18 miejsc po przecinku
}

function formatPercentage(number, scale) {
    const percentage = (Number(number) / Number(scale)) * 100; // Konwersja BigInt na number
    return `${percentage.toFixed(2)}%`;
}

// Funkcja do uzyskania promptu z danych Aave
async function getPrompt() {
    const reserveData = await aaveDataProvider.getReserveData(USDC_OP_SEPOLIA);
    const [totalAToken, totalStableDebt, totalVariableDebt, liquidityRate, variableBorrowRate, stableBorrowRate, averageStableBorrowRate] = [
        reserveData[2], reserveData[3], reserveData[4], reserveData[5], reserveData[6], reserveData[7], reserveData[8]
    ];

    const totalDebt = totalStableDebt + totalVariableDebt;
    const availableLiquidity = totalAToken >= totalDebt ? totalAToken - totalDebt : totalDebt - totalAToken;
    const aaveUtilization = totalDebt * BigInt(1e18) / (availableLiquidity + totalDebt);

    const prompt = `IMPORTANT: Please answer only with one word - name of asset USDC, USDT or WETH using capital letters. 
    I want to forecast the supply rate changes in the Aave protocol for these 3 assets based on the following data. 
    Please provide a prediction for the next 7 days.
    USDC: Total Liquidity / Total Supply: ${formatLargeNumber(totalAToken)}, 
    Utilization Rate: ${formatPercentage(aaveUtilization, BigInt(1e18))}, 
    Total Stable Debt: ${formatLargeNumber(totalStableDebt)}, 
    Total Variable Debt: ${formatLargeNumber(totalVariableDebt)}, 
    Supply Rate: ${formatPercentage(liquidityRate, 10 ** 27)}, 
    Variable Borrow Rate: ${formatPercentage(variableBorrowRate, 10 ** 27)}, 
    Stable Borrow Rate: ${formatPercentage(stableBorrowRate, 10 ** 27)}, 
    Average Stable Borrow Rate: ${formatPercentage(averageStableBorrowRate, 10 ** 27)}. 
    Based on these data, please provide an estimate of the future supply rate over the next 3 days.`;

    return prompt;
}

async function sendTransaction(prompt) {
    const modelId = 11;


    const _value = ethers.parseEther("0.0100550149");


    const data = lendingPrompt.interface.encodeFunctionData("calculateAIResult", [modelId, prompt]);


    const gasLimit = await provider.estimateGas({
        to: lendingPromptAddress,
        value: _value,
        data: data
    });

    // const maxPriorityFeePerGas = ethers.parseUnits("3", "gwei");
    // const maxFeePerGas = ethers.parseUnits("3", "gwei");

    const nonce = await provider.getTransactionCount(wallet.address, "latest") + 1;


    const tx = {
        to: lendingPromptAddress,
        value: _value,
        data: data,
        nonce: nonce,
        gasLimit: gasLimit,
        maxPriorityFeePerGas: 300000000,
        maxFeePerGas: 300000000,
        chainId: 11155420
    };

    try {

        const signedTx = await wallet.sendTransaction(tx);

        // const txResponse = await provider.broadcastTransaction(signedTx);
        // console.log("TX RESPONSE", txResponse)

        const receipt = await signedTx.wait();
        console.log('Transaction was mined in block', receipt.blockNumber);
    } catch (error) {
        console.error("Transaction failed", error);
    }
}

// Funkcja do interakcji z LendingPrompt (pierwsza część)
async function firstPart(prompt) {
    const fee = await lendingPrompt.estimateFee(11);
    console.log(`Estimated Fee: ${fee.toString()}`);

    const result = lendingPrompt.requests(372);

    const { sender, modelId, input, output } = await result;

    console.log("Sender: ", sender);
    console.log("Model ID: ", modelId);
    console.log("Output: ", ethers.toUtf8String(output));

    // await lendingPrompt.setCallbackGasLimit(11, 5000000);
    // await sendTransaction(prompt);
    // await lendingPrompt.calculateAIResult(11, prompt, { value: ethers.parseEther("0.0100550149") });
}

// Funkcja do interakcji z AILendingAggregator (druga część)
async function secondPart(prompt) {
    // await aggregator.checkResultAndSetPlatform(11, prompt);
}

// Główna funkcja - odpowiednik run()
async function main() {
    const prompt = await getPrompt();
    console.log(`Generated Prompt: ${prompt}`);

    // Pierwsza część - interakcja z LendingPrompt
    await firstPart(prompt);

    // Czekanie (przykładowo 10 minut)
    // console.log("Waiting for 10 minutes...");
    // await new Promise(r => setTimeout(r, 600000));

    // // Druga część - interakcja z AILendingAggregator
    // await secondPart(prompt);
}

// Uruchomienie skryptu
main().catch((error) => {
    console.error(error);
    process.exit(1);
});
