import React from 'react';
const SpendCell: React.FC<{ spend: number; spendPercent: number }> = ({ spend }) => <div>${spend}</div>;
export default SpendCell;