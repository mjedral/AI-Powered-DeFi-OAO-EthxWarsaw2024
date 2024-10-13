import React, { useState } from 'react';
import { useAccount, useBalance, useContractRead } from 'wagmi';
import { Card, CardContent, CardHeader } from '@mui/material';
import { Table, TableBody, TableCell, TableHead, TableRow } from '@mui/material';
import { Button } from '@mui/material';

const assets = [
  { symbol: 'USDC', address: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48' },
  { symbol: 'USDT', address: '0xdAC17F958D2ee523a2206206994597C13D831ec7' },
  { symbol: 'WETH', address: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2' }
];

const LendingProtocolDashboard = () => {
  const [bestAsset, setBestAsset] = useState<any>(null);
  const { address } = useAccount();

  const getSupplyRate = (asset: any) => {
    // This is a placeholder. In a real application, you would fetch this data from the Aave contract
    return Math.random() * 5; // Random number between 0 and 5
  };

  const getUtilizationRate = (asset: any) => {
    // This is a placeholder. In a real application, you would fetch this data from the Aave contract
    return Math.random() * 100; // Random number between 0 and 100
  };

  const simulateAIDecision = () => {
    const randomIndex = Math.floor(Math.random() * assets.length);
    setBestAsset(0);
  };

  return (
    <Card className="w-full max-w-4xl mx-auto">
      <CardHeader className="text-2xl font-bold">
        Lending Protocol Dashboard
      </CardHeader>
      <CardContent>
        <Table>
          <TableHead>
            <TableRow>
              <TableHead>Asset</TableHead>
              <TableHead>Supply Rate</TableHead>
              <TableHead>Utilization Rate</TableHead>
              <TableHead>Your Balance</TableHead>
            </TableRow>
          </TableHead>
          <TableBody>
            {assets.map((asset) => (
              <TableRow key={asset.symbol} className={bestAsset === asset.symbol ? 'border-green-500 border-2' : ''}>
                <TableCell>{asset.symbol}</TableCell>
                <TableCell>{getSupplyRate(asset).toFixed(2)}%</TableCell>
                <TableCell>{getUtilizationRate(asset).toFixed(2)}%</TableCell>
                <TableCell>
                  {/* < address={address} token={asset.address}>
                    {({ data: any }) => data?.formatted || '0.00'}
                  </> */}
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <Button onClick={simulateAIDecision} className="mt-4">
          Simulate AI Decision
        </Button>
      </CardContent>
    </Card>
  );
};

export default LendingProtocolDashboard;