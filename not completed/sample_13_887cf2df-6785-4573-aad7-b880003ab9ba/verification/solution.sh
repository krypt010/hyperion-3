#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

# The script will be run from inside /work/env
TARGET_FILE="resources/pages/keywords/KeywordsPage.tsx"
log "Updating $TARGET_FILE..."

# Correcting the import and the data handling logic
cat <<'EOF' > "$TARGET_FILE"
import MainLayout from "@/layouts/MainLayout";
import { AccountCard } from "@/components/accounts/AccountCard";
import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Upload, ArrowLeft, ChevronDown } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import AddIcon from "@/assets/add.svg";
import SpendCell from "@/components/google_ads/SpendCell";
import { getDashboardKeywords } from "@/services/dashboardKeywords";
import {
  getAnnualSaleData,
  getAvgAnnualSpentData,
  KeywordDashboardCardData,
} from "@/services/keywordDashboardData";
import SearchFilterComponent from "@/components/SearchFilterComponent";
import { toast } from "sonner";
import SkeletonAccountCard from "@/components/accounts/SkeletonAccountCard";
import SkeletonTable from "@/ui/SkeletonTable";
import SkeletonAccountListItem from "@/components/accounts/SkeletonAccountListItem";
import { API } from "@/types/api";

const KeywordsPage: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [annualSaleData, setAnnualSaleData] = useState<KeywordDashboardCardData | null>(null);
  const [avgAnnualSpentData, setAvgAnnualSpentData] = useState<KeywordDashboardCardData | null>(null);
  const [campaignData, setCampaignData] = useState<any[]>([]);
  const [filteredCampaignData, setFilteredCampaignData] = useState<any[]>([]);
  const [expandedCampaigns, setExpandedCampaigns] = useState<Set<string>>(new Set());
  const [selectedKeywords, setSelectedKeywords] = useState<string[]>(() => {
    const stored = localStorage.getItem("selectedKeywordIds");
    return stored ? JSON.parse(stored) : [];
  });
  
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const response = await getDashboardKeywords();
        if (response && response.items) {
          setCampaignData(response.items);
          setFilteredCampaignData(response.items);
          
          const allCampaignIds = response.items.map((c: any) => c.campaignId);
          setExpandedCampaigns(new Set(allCampaignIds));
          
          const allKeywordIds: string[] = [];
          response.items.forEach((c: any) => {
            if (c.items) {
              c.items.forEach((kw: any) => {
                allKeywordIds.push(kw.keywordId);
              });
            }
          });
          setSelectedKeywords(allKeywordIds);
          localStorage.setItem("selectedKeywordIds", JSON.stringify(allKeywordIds));
        }

        const [annual, avgSpent] = await Promise.all([
          getAnnualSaleData(),
          getAvgAnnualSpentData()
        ]);
        setAnnualSaleData(annual);
        setAvgAnnualSpentData(avgSpent);
      } catch (error) {
        console.error("Error fetching data:", error);
        toast.error("Failed to load keyword data.");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handleSearchChange = (searchTerm: string) => {
    const lower = searchTerm.toLowerCase();
    const filtered = campaignData.map(campaign => ({
      ...campaign,
      items: campaign.items.filter((kw: any) => 
        kw.keywordText.toLowerCase().includes(lower) ||
        campaign.campaignName.toLowerCase().includes(lower)
      )
    })).filter(campaign => campaign.items.length > 0);
    setFilteredCampaignData(filtered);
  };

  const toggleKeywordSelection = (keywordId: string) => {
    setSelectedKeywords(prev => {
      const next = prev.includes(keywordId) 
        ? prev.filter(id => id !== keywordId) 
        : [...prev, keywordId];
      localStorage.setItem("selectedKeywordIds", JSON.stringify(next));
      return next;
    });
  };

  const toggleCampaignExpansion = (campaignId: string) => {
    setExpandedCampaigns(prev => {
      const next = new Set(prev);
      if (next.has(campaignId)) next.delete(campaignId);
      else next.add(campaignId);
      return next;
    });
  };

  const handleSelectAll = (checked: boolean | "indeterminate", campaignId: string) => {
    const campaign = campaignData.find(c => c.campaignId === campaignId);
    if (!campaign) return;
    const campaignKeywordIds = campaign.items.map((kw: any) => kw.keywordId);
    
    if (checked === true) {
      setSelectedKeywords(prev => [...new Set([...prev, ...campaignKeywordIds])]);
    } else {
      setSelectedKeywords(prev => prev.filter(id => !campaignKeywordIds.includes(id)));
    }
  };

  return (
    <MainLayout title="Keywords - Revnu" description="Manage your keywords" keywords="keywords, revnu">
      <div className="lg:container lg:max-w-[1800px] mx-auto px-4 py-6">
        <h2 className="text-3xl font-bold tracking-tight">Keywords</h2>
        <p className="text-muted-foreground mt-2">Refine your targeting by removing irrelevant or low-performing keywords</p>
        
        <div className="grid gap-4 mt-6 md:grid-cols-2 lg:grid-cols-7">
          {loading ? (
             <>
               <div className="col-span-1 lg:col-span-2"><SkeletonAccountCard /></div>
               <div className="col-span-1 lg:col-span-5"><SkeletonAccountCard /></div>
             </>
          ) : (
            <>
              <div className="col-span-1 lg:col-span-2">
                {annualSaleData && <AccountCard {...annualSaleData} chartType="bar" cardClassName="bg-card-annual-sale" />}
              </div>
              <div className="col-span-1 lg:col-span-5">
                {avgAnnualSpentData && <AccountCard {...avgAnnualSpentData} chartType="line" />}
              </div>
            </>
          )}
        </div>

        <div className="flex justify-between items-center mt-6">
          <h3 className="text-2xl font-bold">Select keywords to optimize</h3>
          <div className="flex items-center space-x-2">
            <SearchFilterComponent placeholder="Search keyword by name..." inputClassName="pr-9" onSearchChange={handleSearchChange} />
            <Button variant="outline"><Upload className="h-4 w-4 md:mr-2" /><span className="hidden md:inline">Import/Export</span></Button>
          </div>
        </div>

        <div className="mt-4 space-y-6">
          {loading ? (
            <SkeletonTable rows={8} columns={7} />
          ) : filteredCampaignData.length > 0 ? (
            filteredCampaignData.map(campaign => (
              <div key={campaign.campaignId} className="border rounded-lg bg-white overflow-hidden">
                <div 
                  className="flex items-center justify-between p-4 cursor-pointer hover:bg-gray-50"
                  onClick={() => toggleCampaignExpansion(campaign.campaignId)}
                >
                  <div className="flex items-center space-x-3">
                    <img src={AddIcon} alt="" className="h-8 w-8" />
                    <span className="font-bold text-lg">{campaign.campaignName}</span>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className="text-sm text-gray-500">{campaign.items.length} keywords</span>
                    <ChevronDown className={`h-4 w-4 transition-transform ${expandedCampaigns.has(campaign.campaignId) ? 'rotate-180' : ''}`} />
                  </div>
                </div>

                {expandedCampaigns.has(campaign.campaignId) && (
                  <div className="overflow-x-auto border-t">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left">
                            <Checkbox 
                              checked={campaign.items.every((kw: any) => selectedKeywords.includes(kw.keywordId))}
                              onCheckedChange={(checked) => handleSelectAll(checked, campaign.campaignId)}
                            />
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Keyword</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ad Group</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rationale</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conv. Rate</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ROAS</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">CPA</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Spend</th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {campaign.items.map((kw: any) => (
                          <tr key={kw.keywordId} className="hover:bg-gray-50">
                            <td className="px-6 py-4">
                              <Checkbox checked={selectedKeywords.includes(kw.keywordId)} onCheckedChange={() => toggleKeywordSelection(kw.keywordId)} />
                            </td>
                            <td className="px-6 py-4 text-sm font-medium text-blue-600">{kw.keywordText}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.adGroupName}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.rationale}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.conversionRate}%</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.roas}x</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.cpa}</td>
                            <td className="px-6 py-4">
                              <SpendCell spend={kw.spend} spendPercent={kw.spendPercent} />
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            ))
          ) : (
            <div className="text-center py-10 text-gray-500">No keywords found.</div>
          )}
        </div>

        <div className="flex justify-between items-center mt-8 border-t pt-6">
          <Button variant="ghost" onClick={() => navigate(-1)}><ArrowLeft className="h-4 w-4 mr-2" />Back</Button>
          <Link to="/keyword-apply">
            <Button size="lg" className="rounded-full bg-blue-600 hover:bg-blue-700 text-white px-8 shadow-lg">
              Apply Optimization ({selectedKeywords.length})
            </Button>
          </Link>
        </div>
      </div>
    </MainLayout>
  );
};

export default KeywordsPage;
EOF

log "Solution applied successfully."
