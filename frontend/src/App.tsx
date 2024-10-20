import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract } from 'wagmi';
import { Box, Typography, Container, Paper, Button } from '@mui/material';
import { Table, TableBody, TableCell, TableContainer, TableHead, TableRow } from '@mui/material';
import { ethers } from 'ethers';
import aaveDataProviderABI from '../../js-scripts/abi/aaveDataProviderAbi.json';
import lendingPromptABI from '../../js-scripts/abi/lendingPromptAbi.json';
import aaveSupplyABI from '../../js-scripts/abi/aaveSupplyAbi.json';
import { Balance } from './components/Balance'; // Dodaj ten import na górze pliku

const AAVE_DATA_PROVIDER = '0x501B4c19dd9C2e06E94dA7b6D5Ed4ddA013EC741';
const AAVE_SUPPLY_CONTRACT = '0x...'; // Adres kontraktu AaveSupply
const LENDING_PROMPT_ADDRESS = '0xe4DC4aFe063491eFB3b5930118f8937bd1c8Ef59';

const assets = [
  { symbol: 'WETH', address: '0x1BDD24840e119DC2602dCC587Dd182812427A5Cc' },
  { symbol: 'USDC', address: '0x5fd84259d66Cd46123540766Be93DFE6D43130D7' },
  { symbol: 'USDT', address: '0x94b008aA00579c1307B0EF2c499aD98a8ce58e58' }
];


const LendingProtocolDashboard = () => {
  const { address } = useAccount();
  const [aiDecision, setAiDecision] = useState<string | null>(null);

  const getReserveData = (asset: string) => {
    return useReadContract({
      address: AAVE_DATA_PROVIDER,
      abi: aaveDataProviderABI,
      functionName: 'getReserveData',
      args: [asset],
    });
  };

  const formatLargeNumber = (number: bigint) => {
    return ethers.formatUnits(number, 18);
  };

  const formatPercentage = (number: bigint, scale: bigint) => {
    const percentage = (Number(number) / Number(scale)) * 100;
    return `${percentage.toFixed(2)}%`;
  };

  const { data: aiResult } = useReadContract({
    address: LENDING_PROMPT_ADDRESS,
    abi: lendingPromptABI,
    functionName: 'getLatestAIDecision',
  });

  useEffect(() => {
    if (aiResult) {
      setAiDecision(ethers.toUtf8String(aiResult as string));
    }
  }, [aiResult]);

  const { writeContract: supplyLiquidity } = useWriteContract();

  const handleSupply = (asset: string, amount: string) => {
    supplyLiquidity({
      address: AAVE_SUPPLY_CONTRACT,
      abi: aaveSupplyABI,
      functionName: 'supply',
      args: [asset, ethers.parseUnits(amount, 18), address],
    });
  };

  return (
    <Box sx={{ bgcolor: '#f7f8fa', minHeight: '100vh', py: 6 }}>
      <Container maxWidth="lg">
        <Typography variant="h4" fontWeight="bold" mb={4}>
          Lending Protocol Dashboard
        </Typography>
        <Paper sx={{ borderRadius: 2, overflow: 'hidden', boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)' }}>
          <TableContainer>
            <Table>
              <TableHead>
                <TableRow sx={{ bgcolor: 'background.paper' }}>
                  <TableCell>Asset</TableCell>
                  <TableCell align="right">Supply APY</TableCell>
                  <TableCell align="right">Utilization</TableCell>
                  <TableCell align="right">Your Balance</TableCell>
                  <TableCell align="right">Action</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {assets.map((asset) => {
                  const { data: reserveData } = getReserveData(asset.address);
                  if (reserveData && Array.isArray(reserveData)) {
                    const [, , totalAToken, totalStableDebt, totalVariableDebt, liquidityRate] = reserveData;

                    const totalDebt = (totalStableDebt ?? 0n) + (totalVariableDebt ?? 0n);
                    const availableLiquidity = (totalAToken ?? 0n) >= totalDebt ? (totalAToken ?? 0n) - totalDebt : totalDebt - (totalAToken ?? 0n);
                    const utilization = totalDebt * BigInt(1e18) / (availableLiquidity + totalDebt);

                    return (
                      <TableRow
                        key={asset.symbol}
                        sx={{
                          '&:last-child td, &:last-child th': { border: 0 },
                          bgcolor: aiDecision === asset.symbol ? 'rgba(0, 255, 0, 0.05)' : 'inherit',
                        }}
                      >
                        <TableCell component="th" scope="row">
                          <Typography variant="subtitle1" fontWeight="medium">
                            {asset.symbol}
                          </Typography>
                        </TableCell>
                        <TableCell align="right">{formatPercentage(liquidityRate || 0n, BigInt(1e27))}</TableCell>
                        <TableCell align="right">{formatPercentage(utilization, BigInt(1e18))}</TableCell>
                        <TableCell align="right">
                          <Balance address={address} token={asset.address} />
                        </TableCell>
                        <TableCell align="right">
                          <Button
                            variant="contained"
                            size="small"
                            onClick={() => handleSupply(asset.address, '100')}
                          >
                            Supply
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  } else {
                    console.error('Nieprawidłowe dane rezerwy dla', asset.symbol);
                  }
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
        <Typography variant="h6" mt={4}>
          AI Recommendation: {aiDecision || 'Loading...'}
        </Typography>
      </Container>
    </Box>
  );
};

export default LendingProtocolDashboard;
