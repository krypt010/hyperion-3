export interface KeywordDashboardCardData {
  title: string;
  value: string | number;
  change: number;
  trend: 'up' | 'down';
  chartData: any[];
}

export const getAnnualSaleData = async (): Promise<KeywordDashboardCardData> => ({
  title: "Annual Sale", value: "$0", change: 0, trend: 'up', chartData: []
});

export const getAvgAnnualSpentData = async (): Promise<KeywordDashboardCardData> => ({
  title: "Avg Annual Spent", value: "$0", change: 0, trend: 'up', chartData: []
});