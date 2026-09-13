import logging
import re
from typing import Any, Dict, List, Optional
from app.adapters.supabase_adapter import supabase_adapter

logger = logging.getLogger(__name__)

# Static catalog fallback for offline / test isolation
DEFAULT_SCHEMES_CATALOG: List[Dict[str, Any]] = [
    {
        "id": "11111111-1111-1111-1111-111111111111",
        "scheme_code": "PMEGP",
        "official_name": "Prime Minister's Employment Generation Programme (PMEGP)",
        "authority": "Khadi and Village Industries Commission (KVIC) / Ministry of MSME",
        "scheme_type": "CENTRAL_SUBSIDY",
        "max_loan_limit": 5000000.0,
        "max_subsidy_pct": 35.0,
        "official_portal_url": "https://www.kviconline.gov.in/pmegpeportal/",
        "target_sectors": ["Manufacturing", "Food Processing", "Agri-Business", "Service", "Textiles", "Engineering"],
        "target_occupations": ["Manufacturer", "Processor", "Artisan", "Mechanic", "Food Processor", "Workshop Owner"],
        "target_business_types": ["manufacturing", "service"],
        "target_categories": ["general", "obc", "sc", "st", "woman", "minority", "ph"],
        "target_states": ["ALL"],
        "search_representation": "PMEGP Prime Minister Employment Generation Programme KVIC MSME credit-linked capital subsidy 15% 25% 35% margin money new unit greenfield manufacturing service food processing machinery equipment",
        "eligibility_rules": {
            "min_age": 18,
            "rural_subsidy_special": 35.0,
            "rural_subsidy_general": 25.0,
            "manufacturing_max_cost": 5000000.0,
            "service_max_cost": 2000000.0,
        },
        "is_active": True,
    },
    {
        "id": "22222222-2222-2222-2222-222222222222",
        "scheme_code": "MUDRA_SHISHU",
        "official_name": "Pradhan Mantri MUDRA Yojana (Shishu)",
        "authority": "MUDRA / Department of Financial Services",
        "scheme_type": "CENTRAL_CREDIT",
        "max_loan_limit": 50000.0,
        "max_subsidy_pct": 0.0,
        "official_portal_url": "https://www.mudra.org.in/",
        "target_sectors": ["Retail", "Trading", "Services", "Micro-Manufacturing", "Food Stall", "Kirana"],
        "target_occupations": ["Shopkeeper", "Vendor", "Artisan", "Tailor", "Driver", "Micro Entrepreneur"],
        "target_business_types": ["manufacturing", "service", "trading"],
        "target_categories": ["ALL"],
        "target_states": ["ALL"],
        "search_representation": "MUDRA Shishu micro credit nano loan up to 50000 collateral free working capital shopkeeper vegetable vendor kirana small business",
        "eligibility_rules": {"min_age": 18, "max_loan": 50000.0},
        "is_active": True,
    },
    {
        "id": "33333333-3333-3333-3333-333333333333",
        "scheme_code": "MUDRA_KISHORE",
        "official_name": "Pradhan Mantri MUDRA Yojana (Kishore)",
        "authority": "MUDRA / Department of Financial Services",
        "scheme_type": "CENTRAL_CREDIT",
        "max_loan_limit": 500000.0,
        "max_subsidy_pct": 0.0,
        "official_portal_url": "https://www.mudra.org.in/",
        "target_sectors": ["Retail", "Trading", "Services", "Manufacturing", "Light Engineering", "Transport"],
        "target_occupations": ["Shopkeeper", "Trader", "Workshop Owner", "Distributor", "Food Processor"],
        "target_business_types": ["manufacturing", "service", "trading"],
        "target_categories": ["ALL"],
        "target_states": ["ALL"],
        "search_representation": "MUDRA Kishore business loan 50000 to 500000 5 lakh collateral free equipment machinery working capital expansion",
        "eligibility_rules": {"min_age": 18, "min_loan": 50001.0, "max_loan": 500000.0},
        "is_active": True,
    },
    {
        "id": "44444444-4444-4444-4444-444444444444",
        "scheme_code": "MUDRA_TARUN",
        "official_name": "Pradhan Mantri MUDRA Yojana (Tarun)",
        "authority": "MUDRA / Department of Financial Services",
        "scheme_type": "CENTRAL_CREDIT",
        "max_loan_limit": 1000000.0,
        "max_subsidy_pct": 0.0,
        "official_portal_url": "https://www.mudra.org.in/",
        "target_sectors": ["Manufacturing", "Processing", "Wholesale", "Service Enterprise", "Agri-Tech"],
        "target_occupations": ["Small Enterprise Owner", "Manufacturer", "Wholesaler", "Commercial Operator"],
        "target_business_types": ["manufacturing", "service", "trading"],
        "target_categories": ["ALL"],
        "target_states": ["ALL"],
        "search_representation": "MUDRA Tarun enterprise loan 500000 to 1000000 10 lakh collateral free growth capital plant equipment",
        "eligibility_rules": {"min_age": 18, "min_loan": 500001.0, "max_loan": 1000000.0},
        "is_active": True,
    },
    {
        "id": "55555555-5555-5555-5555-555555555555",
        "scheme_code": "STANDUP_INDIA",
        "official_name": "Stand-Up India Scheme",
        "authority": "SIDBI / Ministry of Finance",
        "scheme_type": "AFFIRMATIVE_CREDIT",
        "max_loan_limit": 10000000.0,
        "max_subsidy_pct": 0.0,
        "official_portal_url": "https://www.standupmitra.in/",
        "target_sectors": ["Manufacturing", "Services", "Trading", "Agri-Allied"],
        "target_occupations": ["SC Entrepreneur", "ST Entrepreneur", "Woman Entrepreneur", "Founder"],
        "target_business_types": ["manufacturing", "service", "trading"],
        "target_categories": ["sc", "st", "woman"],
        "target_states": ["ALL"],
        "search_representation": "Stand Up India SIDBI bank loan 10 lakh to 1 crore SC ST Woman entrepreneurs greenfield new venture non-farm agri-allied",
        "eligibility_rules": {
            "min_age": 18,
            "min_loan": 1000000.0,
            "max_loan": 10000000.0,
            "eligible_categories": ["sc", "st", "woman"],
        },
        "is_active": True,
    },
    {
        "id": "66666666-6666-6666-6666-666666666666",
        "scheme_code": "PM_SVANIDHI",
        "official_name": "PM Street Vendor's AtmaNirbhar Nidhi (PM SVANidhi)",
        "authority": "Ministry of Housing and Urban Affairs (MoHUA)",
        "scheme_type": "URBAN_MICRO_CREDIT",
        "max_loan_limit": 50000.0,
        "max_subsidy_pct": 7.0,
        "official_portal_url": "https://pmsvanidhi.mohua.gov.in/",
        "target_sectors": ["Street Vending", "Hawking", "Urban Micro Retail", "Food Cart"],
        "target_occupations": ["Street Vendor", "Hawker", "Cart Operator", "Artisan", "Tea Stall Vendor"],
        "target_business_types": ["trading", "service"],
        "target_categories": ["ALL"],
        "target_states": ["ALL"],
        "search_representation": "PM SVANidhi urban street vendor micro credit working capital interest subsidy 7 percent digital transaction cashback",
        "eligibility_rules": {"min_age": 18, "urban_only": True, "max_loan": 50000.0},
        "is_active": True,
    },
]


class SemanticRetriever:
    """
    Retrieves candidate schemes using semantic keywords and profile attributes.
    Returns candidate list (~10-20 schemes) with initial semantic relevance scores.
    """

    @classmethod
    def retrieve_candidates(
        cls,
        profile: Dict[str, Any],
        top_k: int = 20,
    ) -> List[Dict[str, Any]]:
        # 1. Fetch active schemes from DB or fallback
        schemes = cls._fetch_active_schemes()

        # 2. Build user search query string
        tokens = cls._extract_query_tokens(profile)

        # 3. Score schemes for semantic candidate relevance
        scored_candidates = []
        for s in schemes:
            score = cls._compute_relevance_score(s, tokens, profile)
            scheme_copy = dict(s)
            scheme_copy["semantic_score"] = round(score, 4)
            scored_candidates.append(scheme_copy)

        # Sort by candidate relevance
        scored_candidates.sort(key=lambda x: x["semantic_score"], reverse=True)
        return scored_candidates[:top_k]

    @classmethod
    def _fetch_active_schemes(cls) -> List[Dict[str, Any]]:
        client = supabase_adapter.admin_client or supabase_adapter.client
        if client is not None:
            try:
                res = client.table("schemes").select("*").eq("is_active", True).execute()
                if res.data and len(res.data) > 0:
                    return res.data
            except Exception as e:
                logger.warning(f"Failed to fetch schemes from Supabase ({e}); using built-in catalog.")

        return DEFAULT_SCHEMES_CATALOG

    @classmethod
    def _extract_query_tokens(cls, profile: Dict[str, Any]) -> List[str]:
        query_parts = [
            str(profile.get("business_name") or ""),
            str(profile.get("business_activity") or ""),
            str(profile.get("business_type") or ""),
            str(profile.get("sector") or ""),
            str(profile.get("occupation") or ""),
            str(profile.get("rural_or_urban") or ""),
            str(profile.get("social_category") or ""),
        ]
        text = " ".join(query_parts).lower()
        # Clean words
        words = re.findall(r"\b[a-zA-Z0-9_\-]{3,}\b", text)
        return list(set(words))

    @classmethod
    def _compute_relevance_score(
        cls,
        scheme: Dict[str, Any],
        tokens: List[str],
        profile: Dict[str, Any],
    ) -> float:
        search_repr = str(scheme.get("search_representation") or "").lower()
        official_name = str(scheme.get("official_name") or "").lower()
        authority = str(scheme.get("authority") or "").lower()
        sectors = [str(x).lower() for x in (scheme.get("target_sectors") or [])]
        occupations = [str(x).lower() for x in (scheme.get("target_occupations") or [])]
        biz_types = [str(x).lower() for x in (scheme.get("target_business_types") or [])]

        combined_doc = f"{search_repr} {official_name} {authority} {' '.join(sectors)} {' '.join(occupations)} {' '.join(biz_types)}"

        if not tokens:
            return 0.50

        matches = sum(1 for t in tokens if t in combined_doc)
        token_score = matches / max(1, len(tokens))

        # Sector / Business type bonus
        p_biz_type = str(profile.get("business_type") or "").lower()
        if p_biz_type and p_biz_type in biz_types:
            token_score += 0.20

        p_sector = str(profile.get("sector") or "").lower()
        if p_sector and any(p_sector in s for s in sectors):
            token_score += 0.15

        # Normalization to [0.1, 1.0]
        return max(0.10, min(1.0, token_score))
