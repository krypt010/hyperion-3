set -euo pipefail

# Logging function
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

log "Starting solution script..."

# 1. Locate KeywordsPage.tsx
TARGET_FILE=$(find . -name "KeywordsPage.tsx" | grep "pages/keywords" | head -n 1)
if [ -z "$TARGET_FILE" ]; then
    log "KeywordsPage.tsx not found, falling back to resources/pages/keywords/KeywordsPage.tsx"
    TARGET_FILE="resources/pages/keywords/KeywordsPage.tsx"
fi

log "Found target file at: $TARGET_FILE"

# 2. Overwrite with corrected logic
log "Implementing fixed data parsing and UI grouping..."

cat <<'EOF' > "$TARGET_FILE"
import MainLayout from "@/layouts/MainLayout";
import { AccountCard } from "@/components/accounts/AccountCard";
import React, { useState, useEffect, useCallback, useRef } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Upload, ArrowLeft, ChevronDown, Loader2 } from "lucide-react";
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
import SkeletonTable from "@/components/ui/SkeletonTable";
import SkeletonAccountListItem from "@/components/accounts/SkeletonAccountListItem";
import { API } from "@/types/api";

const KeywordsPage: React.FC = () => {
  const [keywords, setKeywords] = useState<API.OnboardingData.Keyword[]>([]);
  const [filteredKeywords, setFilteredKeywords] = useState<API.OnboardingData.Keyword[]>([]);
  const [annualSaleData, setAnnualSaleData] = useState<KeywordDashboardCardData | null>(null);
  const [avgAnnualSpentData, setAvgAnnualSpentData] = useState<KeywordDashboardCardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [campaignNames, setCampaignNames] = useState<Record<string, string>>({});
  const [expandedCampaigns, setExpandedCampaigns] = useState<Set<string>>(new Set());
  const [selectedKeywords, setSelectedKeywords] = useState<string[]>(() => {
    const stored = localStorage.getItem("selectedKeywordIds");
    return stored ? JSON.parse(stored).filter((id: any) => id !== null) : [];
  });

  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const response = await getDashboardKeywords();
        
        // The API returns { items: [ { campaignId, campaignName, items: [keywords...] } ] }
        if (response && response.items) {
          const allKeywords: API.OnboardingData.Keyword[] = [];
          const names: Record<string, string> = {};
          const initialExpanded = new Set<string>();

          response.items.forEach((campaign: any) => {
            if (campaign.items) {
              allKeywords.push(...campaign.items);
              names[campaign.campaignId] = campaign.campaignName;
              initialExpanded.add(campaign.campaignId);
            }
          });

          // Deduplicate keywords by ID
          const uniqueKeywords = Array.from(
            new Map(allKeywords.map((kw) => [kw.keywordId, kw])).values()
          );

          setKeywords(uniqueKeywords);
          setFilteredKeywords(uniqueKeywords);
          setCampaignNames(names);
          setExpandedCampaigns(initialExpanded);

          // Initialize selection if empty
          const allIds = uniqueKeywords.map(kw => kw.keywordId);
          setSelectedKeywords(allIds);
          localStorage.setItem("selectedKeywordIds", JSON.stringify(allIds));
        }

        const [annual, avgSpent] = await Promise.all([
          getAnnualSaleData(),
          getAvgAnnualSpentData(),
        ]);
        setAnnualSaleData(annual);
        setAvgAnnualSpentData(avgSpent);
      } catch (error) {
        console.error("Error fetching dashboard keywords:", error);
        toast.error("Failed to load keyword data.");
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, []);

  const handleSearchChange = (searchTerm: string) => {
    const lower = searchTerm.toLowerCase();
    const filtered = keywords.filter(
      (kw) =>
        kw.keywordText.toLowerCase().includes(lower) ||
        kw.adGroupName.toLowerCase().includes(lower)
    );
    setFilteredKeywords(filtered);
  };

  const toggleKeywordSelection = (keywordId: string) => {
    setSelectedKeywords((prev) => {
      const newSelection = prev.includes(keywordId)
        ? prev.filter((id) => id !== keywordId)
        : [...prev, keywordId];
      localStorage.setItem("selectedKeywordIds", JSON.stringify(newSelection));
      return newSelection;
    });
  };

  const toggleCampaignExpansion = (campaignId: string) => {
    setExpandedCampaigns((prev) => {
      const newSet = new Set(prev);
      if (newSet.has(campaignId)) newSet.delete(campaignId); 
      else newSet.add(campaignId);
      return newSet;
    });
  };

  const handleSelectAll = (checked: boolean | "indeterminate", campaignId: string) => {
    const campaignKeywords = filteredKeywords.filter(kw => kw.campaignId === campaignId);
    const campaignIds = campaignKeywords.map(kw => kw.keywordId);
    
    if (checked === true) {
      setSelectedKeywords(prev => [...new Set([...prev, ...campaignIds])]);
    } else {
      setSelectedKeywords(prev => prev.filter(id => !campaignIds.includes(id)));
    }
  };

  const keywordsByCampaign = filteredKeywords.reduce((acc, keyword) => {
    if (!acc[keyword.campaignId]) acc[keyword.campaignId] = [];
    acc[keyword.campaignId].push(keyword);
    return acc;
  }, {} as Record<string, API.OnboardingData.Keyword[]>);

  return (
    <MainLayout
      title="Keywords - Revnu"
      description="Manage your keywords"
      keywords="keywords, revnu"
    >
      <div className="lg:container lg:max-w-[1800px] mx-auto px-4 py-6">
        <h2 className="text-3xl font-bold tracking-tight">Keywords</h2>
        <p className="text-muted-foreground mt-2">
          Refine your targeting by removing irrelevant or low-performing keywords
        </p>
        
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

        <div className="flex justify-between items-center mt-8">
          <h3 className="text-2xl font-bold">Keyword Optimization</h3>
          <div className="flex items-center space-x-2">
            <SearchFilterComponent
              placeholder="Search keyword..."
              onSearchChange={handleSearchChange}
            />
            <Button variant="outline">
              <Upload className="h-4 w-4 md:mr-2" />
              <span className="hidden md:inline">Import/Export</span>
            </Button>
          </div>
        </div>

        <div className="mt-6 space-y-4">
          {loading ? (
            <SkeletonTable rows={5} columns={6} />
          ) : Object.keys(keywordsByCampaign).length > 0 ? (
            Object.entries(keywordsByCampaign).map(([campaignId, campaignKeywords]) => (
              <div key={campaignId} className="border rounded-lg bg-white overflow-hidden shadow-sm">
                <div 
                  className="flex items-center justify-between p-4 cursor-pointer hover:bg-gray-50"
                  onClick={() => toggleCampaignExpansion(campaignId)}
                >
                  <div className="flex items-center space-x-3">
                    <img src={AddIcon} alt="" className="h-8 w-8" />
                    <span className="font-bold">{campaignNames[campaignId] || `Campaign ${campaignId}`}</span>
                  </div>
                  <div className="flex items-center space-x-4">
                    <span className="text-sm text-gray-500">{campaignKeywords.length} keywords</span>
                    <ChevronDown className={`h-4 w-4 transition-transform ${expandedCampaigns.has(campaignId) ? 'rotate-180' : ''}`} />
                  </div>
                </div>
                
                {expandedCampaigns.has(campaignId) && (
                  <div className="overflow-x-auto border-t">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left w-10">
                            <Checkbox 
                              checked={campaignKeywords.every(k => selectedKeywords.includes(k.keywordId))}
                              onCheckedChange={(checked) => handleSelectAll(checked, campaignId)}
                            />
                          </th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Keyword</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Ad Group</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rationale</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Conv. Rate</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Spend</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {campaignKeywords.map(kw => (
                          <tr key={kw.keywordId} className="hover:bg-gray-50">
                            <td className="px-6 py-4">
                              <Checkbox 
                                checked={selectedKeywords.includes(kw.keywordId)}
                                onCheckedChange={() => toggleKeywordSelection(kw.keywordId)}
                              />
                            </td>
                            <td className="px-6 py-4 text-sm font-medium text-blue-600">{kw.keywordText}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.adGroupName}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.rationale}</td>
                            <td className="px-6 py-4 text-sm text-gray-500">{kw.conversionRate}%</td>
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
            <div className="text-center py-20 bg-gray-50 rounded-lg border-2 border-dashed">
              No keywords found.
            </div>
          )}
        </div>

        <div className="flex justify-between items-center mt-8 border-t pt-6">
          <Button variant="ghost" onClick={() => navigate(-1)}>
            <ArrowLeft className="h-4 w-4 mr-2" /> Back
          </Button>
          <Link to="/keyword-apply">
            <Button size="lg" className="rounded-full px-8 bg-blue-600 hover:bg-blue-700 text-white shadow-lg">
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

log "KeywordsPage.tsx fixed successfully."
exit 0