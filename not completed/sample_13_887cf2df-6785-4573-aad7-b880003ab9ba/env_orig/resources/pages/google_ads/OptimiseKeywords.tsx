import MainLayout from "@/layouts/MainLayout";
import Stepper from "@/components/ui/stepper";
import { useState, useEffect, useCallback, useRef } from "react";
import { API } from "@/types/api";
import { getOnboardingData, saveOnboardingSelection } from "@/services/onboardingData";
import { getCampaignsList } from "@/services/campaigns";
import { Button } from "@/components/ui/button";
import { ChevronDown, ArrowLeft, Loader2 } from "lucide-react";
import { Checkbox } from "@/components/ui/checkbox";
import { useNavigate, useLocation } from "react-router-dom";
import { toast } from "sonner";
import AddIcon from "@/assets/add.svg";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import SearchFilterComponent from "@/components/SearchFilterComponent";
import SkeletonOptimiseKeywords from "@/components/google_ads/SkeletonOptimiseKeywords";
import SpendCell from "@/components/google_ads/SpendCell";

const steps = [
  { number: 1, title: "Select Account" },
  { number: 2, title: "Select Campaigns" },
  { number: 3, title: "Optimise Keywords" },
];

const mobileSteps = [
    { number: 1, title: "Account" },
    { number: 2, title: "Campaigns" },
    { number: 3, title: "Keywords" },
];

const OptimiseKeywords: React.FC = () => {
  const [keywords, setKeywords] = useState<API.OnboardingData.Keyword[]>([]);
  const [selectedKeywords, setSelectedKeywords] = useState<string[]>([]);
  const [expandedCampaigns, setExpandedCampaigns] = useState<Set<string>>(new Set());
  const navigate = useNavigate();
  const location = useLocation();
  const [campaignNames, setCampaignNames] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [searchKeyword, setSearchKeyword] = useState(() => localStorage.getItem("searchKeyword") || "");

  const [campaigns, setCampaigns] = useState<API.GoogleAdsCampaigns.Campaign[]>([]);
  const [selectedCampaigns, setSelectedCampaigns] = useState<Record<string, API.GoogleAdsCampaigns.Campaign>>({});
  const [campaignPage, setCampaignPage] = useState(1);
  const [hasMoreCampaigns, setHasMoreCampaigns] = useState(true);
  const [loadingCampaigns, setLoadingCampaigns] = useState(false);
  const dropdownContentRef = useRef<HTMLDivElement>(null);

  const getKeywordId = (keyword: API.OnboardingData.Keyword) => keyword.keywordId;

  const accountId = localStorage.getItem("selectedAccountId");

  useEffect(() => {
    const initializeFromLocalStorage = async () => {
      const campaignIdsString = localStorage.getItem("selectedCampaignIds");

      if (campaignIdsString && accountId) {
        try {
          const preselectedCampaignIds = JSON.parse(campaignIdsString);
          if (!Array.isArray(preselectedCampaignIds) || preselectedCampaignIds.length === 0) {
            setLoading(false);
            return;
          }

          const data = await getOnboardingData(preselectedCampaignIds, accountId, searchKeyword);
          
          const allKeywords: API.OnboardingData.Keyword[] = [];
          const names: Record<string, string> = {};
          const initialSelected: Record<string, API.GoogleAdsCampaigns.Campaign> = {};
          const initialExpanded = new Set<string>();

          data.items.forEach(campaignData => {
            allKeywords.push(...campaignData.items);
            names[campaignData.campaignId] = campaignData.campaignName;
            initialSelected[campaignData.campaignId] = {
              campaignId: campaignData.campaignId,
              campaignName: campaignData.campaignName,
              campaignType: '', campaignStatus: '', impressions: 0, clicks: 0, cost: 0,
              avgCpv: 0, avgCpm: 0, optimizationScore: 0, budget: 0,
            };
            initialExpanded.add(campaignData.campaignId);
          });

          // Filter out duplicate keywords based on keywordId
          const uniqueKeywords = Array.from(new Map(allKeywords.map(keyword => [keyword.keywordId, keyword])).values());

          setKeywords(uniqueKeywords); // Use uniqueKeywords
          setCampaignNames(names);
          setSelectedCampaigns(initialSelected);
          setExpandedCampaigns(initialExpanded);

        } catch (error) {
          console.error("Error initializing from localStorage:", error);
          toast.error("Failed to load pre-selected campaigns.");
          localStorage.removeItem("selectedCampaignIds");
        } finally {
          setLoading(false);
        }
      } else {
        setLoading(false);
      }
    };

    initializeFromLocalStorage();
  }, [accountId, searchKeyword]);


  const loadCampaigns = useCallback(async (page: number) => {
    if (!accountId) {
      toast.error("Account ID not found. Redirecting...");
      navigate("/accounts");
      return;
    }
    setLoadingCampaigns(true);
    try {
      const data = await getCampaignsList(accountId, page, 20);
      if (page === 1) {
        setCampaigns(data.items);
      } else {
        setCampaigns(prev => [...prev, ...data.items]);
      }
      setHasMoreCampaigns(data.currentPage < Math.ceil(data.total / data.pageSize));
      setCampaignPage(page);
    } catch (error) {
      console.error("Error fetching campaigns:", error);
      toast.error("Failed to load campaigns.");
    } finally {
      setLoadingCampaigns(false);
    }
  }, [accountId, navigate]);

  useEffect(() => {
    loadCampaigns(1);
  }, [loadCampaigns]);

  useEffect(() => {
    const handler = setTimeout(() => {
      localStorage.setItem("searchKeyword", searchKeyword);
    }, 500);

    return () => clearTimeout(handler);
  }, [searchKeyword]);

  const handleCampaignSelectionChange = async (campaign: API.GoogleAdsCampaigns.Campaign, checked: boolean) => {
    const newSelectedCampaigns = { ...selectedCampaigns };
    let newKeywords = [...keywords];
    const newCampaignNames = { ...campaignNames };

    setLoading(true);

    const updateLocalStorage = (id: string, shouldAdd: boolean) => {
        try {
            const campaignIdsString = localStorage.getItem("selectedCampaignIds");
            const currentIds = campaignIdsString ? JSON.parse(campaignIdsString) : [];
            const idSet = new Set<string>(currentIds);

            if (shouldAdd) {
                idSet.add(id);
            } else {
                idSet.delete(id);
            }
            localStorage.setItem("selectedCampaignIds", JSON.stringify(Array.from(idSet)));
        } catch (error) {
            console.error("Failed to update localStorage:", error);
            toast.error("Could not save selection state.");
        }
    };

    if (checked) {
      newSelectedCampaigns[campaign.campaignId] = campaign;
      if (accountId) {
        try {
          const data = await getOnboardingData([campaign.campaignId], accountId, searchKeyword);
          if (data.items.length > 0) {
            newKeywords.push(...data.items[0].items);
            newCampaignNames[campaign.campaignId] = data.items[0].campaignName;
            setExpandedCampaigns(prev => new Set(prev).add(campaign.campaignId));
            updateLocalStorage(campaign.campaignId, true);
          }
        } catch (error) {
          console.error("Error fetching keywords for campaign:", campaign.campaignId, error);
          toast.error(`Failed to load keywords for ${campaign.campaignName}`);
          delete newSelectedCampaigns[campaign.campaignId];
        }
      }
    } else {
      delete newSelectedCampaigns[campaign.campaignId];
      const keywordsToRemove = newKeywords.filter(kw => kw.campaignId === campaign.campaignId).map(getKeywordId);
      newKeywords = newKeywords.filter(kw => kw.campaignId !== campaign.campaignId);
      setSelectedKeywords(prev => prev.filter(id => !keywordsToRemove.includes(id)));
      delete newCampaignNames[campaign.campaignId];
      updateLocalStorage(campaign.campaignId, false);
    }

    setSelectedCampaigns(newSelectedCampaigns);
    setKeywords(newKeywords);
    setCampaignNames(newCampaignNames);
    setLoading(false);
  };

  const handleScroll = (event: React.UIEvent<HTMLDivElement>) => {
    const target = event.currentTarget;
    if (target.scrollHeight - target.scrollTop <= target.clientHeight + 100 && hasMoreCampaigns && !loadingCampaigns) {
      loadCampaigns(campaignPage + 1);
    }
  };

  const handleSelectAll = (checked: boolean | "indeterminate", campaignId: string) => {
    const campaignKeywords = keywords.filter(kw => kw.campaignId === campaignId);
    if (checked === true) {
      setSelectedKeywords(prev => [...new Set([...prev, ...campaignKeywords.map(getKeywordId)])]);
    } else {
      setSelectedKeywords(prev => prev.filter(id => !campaignKeywords.map(getKeywordId).includes(id)));
    }
  };

  const toggleKeywordSelection = (keyword: API.OnboardingData.Keyword) => {
    const keywordId = getKeywordId(keyword);
    setSelectedKeywords(prev =>
      prev.includes(keywordId)
        ? prev.filter(id => id !== keywordId)
        : [...prev, keywordId]
    );
  };

  const toggleCampaignExpansion = (campaignId: string) => {
    setExpandedCampaigns(prev => {
      const newSet = new Set(prev);
      newSet.has(campaignId) ? newSet.delete(campaignId) : newSet.add(campaignId);
      return newSet;
    });
  };

  const keywordsByCampaign = keywords.reduce((acc, keyword) => {
    (acc[keyword.campaignId] = acc[keyword.campaignId] || []).push(keyword);
    return acc;
  }, {} as Record<string, API.OnboardingData.Keyword[]>);

  const handleApplyToGoogleAds = async () => {
    if (!accountId) {
      toast.error("Account ID not found.");
      return;
    }
    const campaignIds = Object.keys(selectedCampaigns);
    if (campaignIds.length === 0) {
      toast.error("No campaigns selected.");
      return;
    }

    const payload = {
      campaign_ids: campaignIds,
      account_id: accountId,
    };

    try {
      await saveOnboardingSelection(payload);
      toast.success("Selection saved successfully");
      localStorage.removeItem("searchKeyword");
      localStorage.removeItem("selectedCampaignIds");
      navigate("/accounts");
    } catch (error: any) {
      console.error("Error saving selection:", error);
      toast.error("Error saving selection: " + (error.response?.data?.message || error.message));
    }
  };

  return (
    <MainLayout withSidebar={false}>
      <div className="mx-auto">
        <div className="mx-auto">
          <div className="md:hidden">
              <Stepper steps={mobileSteps} currentStep={3} className="mb-10 md" />
          </div>
          <div className="hidden md:block bg-[#F7F7F7] px-8 py-4 lg:px-20 lg:py-6">
            <div className="max-w-2xl mx-auto">
            <Stepper steps={steps} currentStep={3} className="" />
            </div>
          </div>
          <div className="lg:container min-h-[68vh] mx-auto px-4 lg:max-w-[1800px]">
            <div className="text-center mb-8 mt-8">
              <h1 className="text-3xl md:text-4xl font-bold tracking-tight">Optimize your keywords</h1>
              <p className="text-gray-500 mt-2 text-base md:text-lg">
                Refine your targeting by removing irrelevant or low-performing keywords
              </p>
            </div>

            <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4 space-y-4 md:space-y-0">
              <SearchFilterComponent
                placeholder="Search keyword by name..."
                className="w-full min-w-[27%] md:max-w-xs"
                inputClassName="w-full min-w-[27%] pl-4 pr-10 py-3 bg-gray-100 border-transparent rounded-full focus:ring-2 focus:ring-primary/50 focus:border-primary"
                onSearchChange={setSearchKeyword}
                showFilterButton={true}
              />
              <div className="flex items-center justify-end space-x-2">
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="outline" className="flex items-center space-x-2">
                      <span>
                        {`${Object.keys(selectedCampaigns).length} Campaign(s) selected`}
                      </span>
                      <ChevronDown className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent ref={dropdownContentRef} onScroll={handleScroll} className="max-h-60 overflow-y-auto">
                    {campaigns.map(campaign => (
                      <DropdownMenuItem key={campaign.campaignId} onSelect={(e) => e.preventDefault()} className={`${campaign.campaignStatus === 'REMOVED' ? 'remove-state' : 'active-state'}`}>
                        <div className="flex items-center space-x-2">
                          <Checkbox
                            id={`campaign-${campaign.campaignId}`}
                            checked={!!selectedCampaigns[campaign.campaignId]}
                            onCheckedChange={(checked) => handleCampaignSelectionChange(campaign, !!checked)}
                          />
                          <label htmlFor={`campaign-${campaign.campaignId}`}>{campaign.campaignName}</label>
                        </div>
                      </DropdownMenuItem>
                    ))}
                    {loadingCampaigns && (
                      <DropdownMenuItem disabled className="flex justify-center items-center">
                        <Loader2 className="h-4 w-4 animate-spin" />
                      </DropdownMenuItem>
                    )}
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </div>

            {loading ? (
              <SkeletonOptimiseKeywords />
            ) : Object.keys(keywordsByCampaign).length > 0 ? (
              Object.entries(keywordsByCampaign).map(([campaignId, campaignKeywords]) => {
                const isCampaignExpanded = expandedCampaigns.has(campaignId);
                const selectedCount = campaignKeywords.filter(kw => selectedKeywords.includes(getKeywordId(kw))).length;
                const totalCount = campaignKeywords.length;

                return (
                  <div key={campaignId} className="rounded-lg">
                    <div className="flex items-center justify-between p-2 cursor-pointer mb-2" onClick={() => toggleCampaignExpansion(campaignId)}>
                      <div className="flex items-center space-x-3">
                        <img src={AddIcon} alt="Google Ads" className="h-[36px] w-[36px]" />
                        <span className="font-bold text-lg">{campaignNames[campaignId] || `Campaign ${campaignId}`}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className="text-sm text-gray-500">{selectedCount}/{totalCount} keywords</span>
                        <ChevronDown className={`h-4 w-4 transition-transform ${isCampaignExpanded ? 'rotate-180' : ''}`} />
                      </div>
                    </div>

                    {isCampaignExpanded && (
                      <>
                        <div className="hidden md:block overflow-x-auto max-h-[400px] overflow-y-auto">
                          <table className="min-w-full divide-y divide-gray-200">
                            <thead className="bg-gray-50 rounded-t-lg">
                              <tr>
                                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                  <div className="flex items-center">
                                    <Checkbox
                                      checked={totalCount > 0 && selectedCount === totalCount}
                                      onCheckedChange={(checked) => handleSelectAll(checked, campaignId)}
                                    />
                                    <span className="ml-3">Keyword</span>
                                  </div>
                                </th>
                                {['Rationale', 'Conv. Rate', 'ROAS', 'CPA', 'Spend'].map(header => (
                                  <th key={header} scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                    <div className="flex items-center">{header}</div>
                                  </th>
                                ))}
                              </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-gray-200">
                              {campaignKeywords.map(keyword => (
                                <tr key={getKeywordId(keyword)} className="hover:bg-white hover:shadow-lg hover:rounded-lg">
                                  <td className="px-6 py-4 whitespace-nowrap">
                                    <div className="flex items-center">
                                      <Checkbox checked={selectedKeywords.includes(getKeywordId(keyword))} onCheckedChange={() => toggleKeywordSelection(keyword)} />
                                      <span className="text-sm font-medium text-blue-500 ml-2">{keyword.keywordText}</span>
                                    </div>
                                  </td>
                                  <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">{keyword.rationale}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{keyword.conversionRate}%</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{keyword.roas}x</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${keyword.cpa}</td>
                                  <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                    <SpendCell spend={keyword.spend} spendPercent={keyword.spendPercent} />
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                        <div className="md:hidden space-y-3 p-4 bg-white">
                          {campaignKeywords.map(keyword => (
                            <div key={getKeywordId(keyword)} className="border-b last:border-b-0 pb-3 last:pb-0">
                              <div className="flex items-start justify-between mb-2">
                                <div className="flex items-center space-x-3">
                                  <Checkbox checked={selectedKeywords.includes(getKeywordId(keyword))} onCheckedChange={() => toggleKeywordSelection(keyword)} />
                                  <span className="font-bold text-base text-blue-500 ml-2">{keyword.keywordText}</span>
                                </div>
                                <SpendCell spend={keyword.spend} spendPercent={keyword.spendPercent} />
                              </div>
                              <div className="text-gray-500">RATIONALE</div>
                              <p className="text-sm text-gray-600 mb-2">{keyword.rationale}</p>
                              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-sm">
                                <div className="text-gray-500">CONV. RATE</div>
                                <div className="text-right font-medium text-gray-800">{keyword.conversionRate}%</div>
                                <div className="text-gray-500">ROAS</div>
                                <div className="text-right font-medium text-gray-800">{keyword.roas}x</div>
                                <div className="text-gray-500">CPA</div>
                                <div className="text-right font-medium text-gray-800">${keyword.cpa}</div>
                              </div>
                            </div>
                          ))}
                        </div>
                      </>
                    )}
                  </div>
                );
              })
            ) : (
              <div className="text-center py-10 text-gray-500">Please select a campaign to see keywords.</div>
            )}
          </div>
          <div className="flex justify-between items-center mt-8 border-t pt-6 pb-6 sticky bottom-0 bg-white">
            <div className="lg:container w-full flex justify-between items-center px-4 lg:max-w-[1800px]">
              <Button variant="ghost" onClick={() => navigate(-1)} className="border-none !border-none shadow-none"><ArrowLeft className="h-4 w-4 mr-2" /> Back</Button>
              <Button size="lg" className="rounded-full bg-blue-500 hover:bg-blue-600 text-white px-6"
                disabled={selectedKeywords.length === 0}
                onClick={handleApplyToGoogleAds}>Apply to Google Ads</Button>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
};

export default OptimiseKeywords;