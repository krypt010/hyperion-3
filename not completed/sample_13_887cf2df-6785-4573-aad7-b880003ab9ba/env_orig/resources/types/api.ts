export namespace API {
  export namespace OnboardingData {
    export interface Keyword {
      campaignId: string;
      adgroupId: string;
      keywordId: string;
      keywordText: string;
      campaignName: string;
      adGroupName: string;
      rationale: string;
      conversionRate: number;
      roas: number;
      cpa: number;
      spend: number;
      spendPercent: number;
    }
    export interface CampaignData {
      campaignId: string;
      campaignName: string;
      total: number;
      items: Keyword[];
    }
    export interface Response {
      items: CampaignData[];
    }
  }

  export namespace GoogleAdsCampaigns {
    export interface Campaign {
      campaignId: string;
      campaignName: string;
      campaignType: string;
      campaignStatus: string;
      impressions: number;
      clicks: number;
      cost: number;
      avgCpv: number;
      avgCpm: number;
      optimizationScore: number;
      budget: number;
    }
    export interface Response {
      items: Campaign[];
      total: number;
      currentPage: number;
      pageSize: number;
    }
  }
}