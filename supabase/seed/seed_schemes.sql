-- ==============================================================================
-- VYAPAR MITRA: Seed Government Schemes Catalog
-- ==============================================================================

INSERT INTO schemes (scheme_code, official_name, authority, max_loan_limit, max_subsidy_pct, official_portal_url, eligibility_rules)
VALUES
(
    'PMEGP',
    'Prime Minister''s Employment Generation Programme',
    'Khadi and Village Industries Commission (KVIC) / MSME',
    5000000.00,
    35.00,
    'https://www.kviconline.gov.in/pmegpeportal/',
    '{"min_age": 18, "rural_subsidy_special": 35.0, "rural_subsidy_general": 25.0, "own_contribution_special_pct": 5, "own_contribution_general_pct": 10}'::jsonb
),
(
    'MUDRA_SHISHU',
    'Pradhan Mantri MUDRA Yojana - Shishu',
    'MUDRA / Department of Financial Services',
    50000.00,
    0.00,
    'https://www.mudra.org.in/',
    '{"max_amount": 50000.00, "collateral_required": false, "target_segment": "micro_startups"}'::jsonb
),
(
    'MUDRA_KISHORE',
    'Pradhan Mantri MUDRA Yojana - Kishore',
    'MUDRA / Department of Financial Services',
    500000.00,
    0.00,
    'https://www.mudra.org.in/',
    '{"min_amount": 50001.00, "max_amount": 500000.00, "collateral_required": false}'::jsonb
),
(
    'MUDRA_TARUN',
    'Pradhan Mantri MUDRA Yojana - Tarun',
    'MUDRA / Department of Financial Services',
    1000000.00,
    0.00,
    'https://www.mudra.org.in/',
    '{"min_amount": 500001.00, "max_amount": 1000000.00, "collateral_required": false}'::jsonb
),
(
    'STANDUP_INDIA',
    'Stand-Up India Scheme',
    'SIDBI / Ministry of Finance',
    10000000.00,
    0.00,
    'https://www.standupmitra.in/',
    '{"min_amount": 1000000.00, "max_amount": 10000000.00, "eligible_categories": ["sc", "st", "woman"], "greenfield_only": true}'::jsonb
)
ON CONFLICT (scheme_code) DO NOTHING;
