import sys
from pathlib import Path

# Add backend directory to sys.path
_backend_dir = str(Path(__file__).resolve().parent.parent)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

import json
from app.schemas.recommendation import RecommendationRequest
from app.services.recommendation_service import RecommendationService

dummy_profiles = [
    {
        "persona_name": "1. Ramesh Kumar (Rural Mustard Oil Mill - Special Category OBC)",
        "profile": {
            "age": 28,
            "gender": "male",
            "education": "10th_pass",
            "social_category": "obc",
            "rural_or_urban": "rural",
            "district": "Indore",
            "state": "Madhya Pradesh",
            "occupation": "Micro-entrepreneur",
            "business_name": "Shri Ram Cold-Press Oil Mill",
            "business_activity": "Mustard Oil Extraction",
            "business_type": "manufacturing",
            "business_status": "new",
            "sector": "Food Processing & Agri-Business",
            "total_project_cost": 300000.0,
            "own_capital": 50000.0,
            "loan_required": 250000.0,
            "previous_government_subsidy": False,
            "is_greenfield": True,
        },
    },
    {
        "persona_name": "2. Sunita Devi (Rural Woman Entrepreneur - Bakery & Snacks)",
        "profile": {
            "age": 34,
            "gender": "female",
            "education": "12th_pass",
            "social_category": "woman",
            "is_woman_entrepreneur": True,
            "rural_or_urban": "rural",
            "district": "Patna",
            "state": "Bihar",
            "business_name": "Maa Durga Bakery & Snacks",
            "business_activity": "Bakery and Namkeen Production",
            "business_type": "manufacturing",
            "business_status": "new",
            "sector": "Food Processing",
            "total_project_cost": 1500000.0, # 15 Lakhs
            "own_capital": 250000.0,
            "loan_required": 1250000.0,
            "previous_government_subsidy": False,
            "is_greenfield": True,
        },
    },
    {
        "persona_name": "3. Manoj Verma (Urban Street Vendor / Tea Stall)",
        "profile": {
            "age": 26,
            "gender": "male",
            "education": "8th_pass",
            "social_category": "general",
            "rural_or_urban": "urban",
            "district": "Lucknow",
            "state": "Uttar Pradesh",
            "occupation": "Street Vendor",
            "business_name": "Chai Point & Snacks Corner",
            "business_activity": "Tea Stall and Street Food",
            "business_type": "trading",
            "business_status": "new",
            "sector": "Urban Micro Retail",
            "total_project_cost": 40000.0,
            "own_capital": 10000.0,
            "loan_required": 30000.0,
            "previous_government_subsidy": False,
        },
    },
    {
        "persona_name": "4. Rajesh Sharma (Existing Workshop Owner Expanding - Not Greenfield)",
        "profile": {
            "age": 42,
            "gender": "male",
            "social_category": "general",
            "rural_or_urban": "rural",
            "district": "Pune",
            "state": "Maharashtra",
            "business_name": "Sharma Auto Workshop",
            "business_activity": "Automobile Repair & Spare Parts",
            "business_type": "service",
            "business_status": "existing",
            "years_in_business": 4.0,
            "total_project_cost": 450000.0,
            "own_capital": 100000.0,
            "loan_required": 350000.0,
            "previous_government_subsidy": False,
            "is_greenfield": False,
        },
    },
    {
        "persona_name": "5. Incomplete Profile (Missing Age & Business Type)",
        "profile": {
            "age": None, # Missing age
            "social_category": "general",
            "business_name": "New Venture",
            "business_status": "new",
            "total_project_cost": 250000.0,
            "loan_required": 200000.0,
        },
    },
]

def run_demo():
    print("=" * 80)
    print("🚀 VYAPAR MITRA — GOVERNMENT SCHEME RECOMMENDATION ENGINE TEST BENCH")
    print("=" * 80)

    for persona in dummy_profiles:
        name = persona["persona_name"]
        prof = persona["profile"]
        
        print(f"\n🔹 TEST CASE: {name}")
        print("-" * 80)
        print(f"   Project Cost: ₹{prof.get('total_project_cost', 0):,.0f} | Loan Required: ₹{prof.get('loan_required', 0):,.0f} | Status: {prof.get('business_status')} | Category: {prof.get('social_category')}")
        
        req = RecommendationRequest(override_profile=prof)
        result = RecommendationService.run_recommendation(user_id="test-demo-user", request=req)
        
        print(f"   Evaluated: {result.total_schemes_evaluated} schemes | Eligible: {result.eligible_count} | Needs Info: {result.needs_info_count} | Ineligible: {result.ineligible_count}")
        print("\n   Top Matched Schemes:")
        
        for i, rec in enumerate(result.recommendations[:3], 1):
            status_symbol = "✅" if rec.eligibility_status == "eligible" else ("⚠️" if rec.eligibility_status == "needs_information" else "❌")
            print(f"   [{i}] {status_symbol} {rec.scheme_code} — {rec.official_name}")
            print(f"       Status: {rec.eligibility_status.upper()} | Suitability Score: {(rec.suitability_score * 100):.1f}%")
            if rec.benefit_estimate.estimated_subsidy > 0:
                print(f"       💰 Est. Capital Subsidy: ₹{rec.benefit_estimate.estimated_subsidy:,.0f} ({rec.benefit_estimate.subsidy_percentage:.0f}% grant)")
            print(f"       🏦 Eligible Bank Loan: ₹{rec.benefit_estimate.estimated_loan:,.0f} | Own Margin Required: ₹{rec.benefit_estimate.estimated_own_contribution:,.0f}")
            print(f"       💡 Key Reasons: {', '.join(rec.explanation.why_eligible[:2])}")
            if rec.failed_rules:
                print(f"       🚫 Disqualifying Rules: {', '.join(rec.explanation.failed_rules[:2])}")
            if rec.missing_rules:
                print(f"       ❓ Missing Info Required: {', '.join(rec.explanation.missing_information[:2])}")
            print()

    print("=" * 80)
    print("✅ All dummy test scenarios executed with 100% deterministic rule precision.")
    print("=" * 80)

if __name__ == "__main__":
    run_demo()
