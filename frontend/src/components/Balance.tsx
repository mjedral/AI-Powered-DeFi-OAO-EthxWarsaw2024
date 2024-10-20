import React from 'react';
import { useBalance } from 'wagmi';

interface BalanceProps {
    address?: any;
    token: string;
}

export const Balance: React.FC<BalanceProps> = ({ address, token }) => {
    const { data: balance } = useBalance({
        address,
        token: token !== 'ETH' && token.startsWith('0x') ? (token as `0x${string}`) : undefined,
    });

    return <span>{balance?.formatted} {balance?.symbol}</span>;
};
