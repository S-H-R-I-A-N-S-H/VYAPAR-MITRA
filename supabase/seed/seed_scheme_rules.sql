-- ==============================================================================
-- VYAPAR MITRA: Seed Comprehensive Scheme Rules & Search Representation
-- Matches Step 3, Step 4, Step 6 & Step 7 specifications
-- ==============================================================================

-- 1. Upsert schemes with rich search representation & metadata
INSERT INTO schemes (
    scheme_code, 
    official_name, 
    authority, 
    scheme_type,
    max_loan_limit, 
    max_subsidy_pct, 
    official_portal_url, 
    target_sectors,
    target_occupations,
    target_business_types,
    target_categories,
    target_states,
    search_representation,
    eligibility_rules
)
VALUES
(
    'PMEGP',
    'Prime Minister''s Employment Generation Programme (PMEGP)',
    'Khadi and Village Industries Commission (KVIC) / Ministry of MSME',
    'CENTRAL_SUBSIDY',
    5000000.00,
    35.00,
    'https://www.kviconline.gov.in/pmegpeportal/',
    ARRAY['Manufacturing', 'Food Processing', 'Agri-Business', 'Service', 'Textiles', 'Engineering', 'Artisanal'],
    ARRAY['Manufacturer', 'Processor', 'Artisan', 'Mechanic', 'Food Processor', 'Workshop Owner', 'Service Provider'],
    ARRAY['manufacturing', 'service'],
    ARRAY['general', 'obc', 'sc', 'st', 'woman', 'minority', 'ph', 'ex_servicemen'],
    ARRAY['ALL'],
    'PMEGP Prime Minister Employment Generation Programme KVIC MSME credit-linked capital subsidy 15% 25% 35% margin money new unit greenfield manufacturing service food processing machinery equipment',
    '{"min_age": 18, "rural_subsidy_special": 35.0, "rural_subsidy_general": 25.0, "urban_subsidy_special": 25.0, "urban_subsidy_general": 15.0, "own_contribution_special_pct": 5, "own_contribution_general_pct": 10, "manufacturing_max_cost": 5000000.0, "service_max_cost": 2000000.0, "greenfield_only": true}'::jsonb
),
(
    'MUDRA_SHISHU',
    'Pradhan Mantri MUDRA Yojana (Shishu)',
    'MUDRA / Department of Financial Services, Ministry of Finance',
    'CENTRAL_CREDIT',
    50000.00,
    0.00,
    'https://www.mudra.org.in/',
    ARRAY['Retail', 'Trading', 'Services', 'Micro-Manufacturing', 'Food Stall', 'Kirana', 'Tailoring', 'Handicraft'],
    ARRAY['Shopkeeper', 'Vendor', 'Artisan', 'Tailor', 'Driver', 'Mechanic', 'Micro Entrepreneur', 'Trader'],
    ARRAY['manufacturing', 'service', 'trading'],
    ARRAY['ALL'],
    ARRAY['ALL'],
    'MUDRA Shishu micro credit nano loan up to 50000 collateral free working capital shopkeeper vegetable vendor kirana small business',
    '{"min_age": 18, "max_loan": 50000.00, "collateral_required": false, "no_processing_fee": true}'::jsonb
),
(
    'MUDRA_KISHORE',
    'Pradhan Mantri MUDRA Yojana (Kishore)',
    'MUDRA / Department of Financial Services, Ministry of Finance',
    'CENTRAL_CREDIT',
    500000.00,
    0.00,
    'https://www.mudra.org.in/',
    ARRAY['Retail', 'Trading', 'Services', 'Manufacturing', 'Light Engineering', 'Transport', 'Food Processing'],
    ARRAY['Shopkeeper', 'Trader', 'Workshop Owner', 'Distributor', 'Transport Operator', 'Food Processor'],
    ARRAY['manufacturing', 'service', 'trading'],
    ARRAY['ALL'],
    ARRAY['ALL'],
    'MUDRA Kishore business loan 50000 to 500000 5 lakh collateral free equipment machinery working capital expansion',
    '{"min_age": 18, "min_loan": 50001.00, "max_loan": 500000.00, "collateral_required": false}'::jsonb
),
(
    'MUDRA_TARUN',
    'Pradhan Mantri MUDRA Yojana (Tarun)',
    'MUDRA / Department of Financial Services, Ministry of Finance',
    'CENTRAL_CREDIT',
    1000000.00,
    0.00,
    'https://www.mudra.org.in/',
    ARRAY['Manufacturing', 'Processing', 'Wholesale', 'Service Enterprise', 'Transport', 'Packaging', 'Agri-Tech'],
    ARRAY['Small Enterprise Owner', 'Manufacturer', 'Wholesaler', 'Commercial Operator', 'Processor'],
    ARRAY['manufacturing', 'service', 'trading'],
    ARRAY['ALL'],
    ARRAY['ALL'],
    'MUDRA Tarun enterprise loan 500000 to 1000000 10 lakh collateral free growth capital plant equipment',
    '{"min_age": 18, "min_loan": 500001.00, "max_loan": 1000000.00, "collateral_required": false}'::jsonb
),
(
    'STANDUP_INDIA',
    'Stand-Up India Scheme',
    'SIDBI / Department of Financial Services, Ministry of Finance',
    'AFFIRMATIVE_CREDIT',
    10000000.00,
    0.00,
    'https://www.standupmitra.in/',
    ARRAY['Manufacturing', 'Services', 'Trading', 'Agri-Allied'],
    ARRAY['SC Entrepreneur', 'ST Entrepreneur', 'Woman Entrepreneur', 'Founder', 'Enterprise Owner'],
    ARRAY['manufacturing', 'service', 'trading'],
    ARRAY['sc', 'st', 'woman'],
    ARRAY['ALL'],
    'Stand Up India SIDBI bank loan 10 lakh to 1 crore SC ST Woman entrepreneurs greenfield new venture non-farm agri-allied',
    '{"min_age": 18, "min_loan": 1000000.00, "max_loan": 10000000.00, "eligible_categories": ["sc", "st", "woman"], "greenfield_only": true, "no_bank_default": true}'::jsonb
),
(
    'PM_SVANIDHI',
    'PM Street Vendor''s AtmaNirbhar Nidhi (PM SVANidhi)',
    'Ministry of Housing and Urban Affairs (MoHUA)',
    'URBAN_MICRO_CREDIT',
    50000.00,
    7.00,
    'https://pmsvanidhi.mohua.gov.in/',
    ARRAY['Street Vending', 'Hawking', 'Urban Micro Retail', 'Food Cart', 'Services'],
    ARRAY['Street Vendor', 'Hawker', 'Cart Operator', 'Cobbler', 'Artisan', 'Tea Stall Vendor'],
    ARRAY['trading', 'service'],
    ARRAY['ALL'],
    ARRAY['ALL'],
    'PM SVANidhi urban street vendor micro credit working capital interest subsidy 7 percent digital transaction cashback',
    '{"min_age": 18, "urban_only": true, "initial_loan": 10000.00, "second_tranche": 20000.00, "third_tranche": 50000.00, "interest_subsidy_pct": 7.0}'::jsonb
)
ON CONFLICT (scheme_code) DO UPDATE SET
    official_name = EXCLUDED.official_name,
    authority = EXCLUDED.authority,
    scheme_type = EXCLUDED.scheme_type,
    max_loan_limit = EXCLUDED.max_loan_limit,
    max_subsidy_pct = EXCLUDED.max_subsidy_pct,
    official_portal_url = EXCLUDED.official_portal_url,
    target_sectors = EXCLUDED.target_sectors,
    target_occupations = EXCLUDED.target_occupations,
    target_business_types = EXCLUDED.target_business_types,
    target_categories = EXCLUDED.target_categories,
    target_states = EXCLUDED.target_states,
    search_representation = EXCLUDED.search_representation,
    eligibility_rules = EXCLUDED.eligibility_rules;

-- 2. Clean and Insert Scheme Rules
DELETE FROM scheme_rules;

-- 2.1 PMEGP Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age to apply for PMEGP.', 1, true
FROM schemes WHERE scheme_code = 'PMEGP';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'business_status', 'equals', '"new"'::jsonb, 'eligibility', 
    'PMEGP applies only to new (greenfield) enterprise units. Existing units are not eligible for first assistance.', 2, true
FROM schemes WHERE scheme_code = 'PMEGP';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'previous_government_subsidy', 'equals', 'false'::jsonb, 'eligibility', 
    'Applicant must not have availed any central/state government subsidy previously for the same activity.', 3, true
FROM schemes WHERE scheme_code = 'PMEGP';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'total_project_cost', '<=', '5000000'::jsonb, 'eligibility', 
    'Total project cost must not exceed ₹50 Lakhs (Manufacturing) or ₹20 Lakhs (Service).', 4, true
FROM schemes WHERE scheme_code = 'PMEGP';

-- 2.2 MUDRA Shishu Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age for MUDRA loan.', 1, true
FROM schemes WHERE scheme_code = 'MUDRA_SHISHU';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'loan_required', '<=', '50000'::jsonb, 'eligibility', 
    'MUDRA Shishu tier covers loan amounts up to ₹50,000.', 2, true
FROM schemes WHERE scheme_code = 'MUDRA_SHISHU';

-- 2.3 MUDRA Kishore Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age for MUDRA loan.', 1, true
FROM schemes WHERE scheme_code = 'MUDRA_KISHORE';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'loan_required', 'between', '[50001, 500000]'::jsonb, 'eligibility', 
    'MUDRA Kishore tier covers loan amounts between ₹50,001 and ₹5,00,000.', 2, true
FROM schemes WHERE scheme_code = 'MUDRA_KISHORE';

-- 2.4 MUDRA Tarun Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age for MUDRA loan.', 1, true
FROM schemes WHERE scheme_code = 'MUDRA_TARUN';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'loan_required', 'between', '[500001, 1000000]'::jsonb, 'eligibility', 
    'MUDRA Tarun tier covers loan amounts between ₹5,00,001 and ₹10,00,000.', 2, true
FROM schemes WHERE scheme_code = 'MUDRA_TARUN';

-- 2.5 Stand-Up India Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age.', 1, true
FROM schemes WHERE scheme_code = 'STANDUP_INDIA';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'target_category', 'in', '["sc", "st", "woman"]'::jsonb, 'eligibility', 
    'Stand-Up India is exclusively reserved for SC, ST, or Woman entrepreneurs.', 2, true
FROM schemes WHERE scheme_code = 'STANDUP_INDIA';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'business_status', 'equals', '"new"'::jsonb, 'eligibility', 
    'Stand-Up India requires the venture to be a greenfield (new) enterprise.', 3, true
FROM schemes WHERE scheme_code = 'STANDUP_INDIA';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'loan_required', 'between', '[1000000, 10000000]'::jsonb, 'eligibility', 
    'Stand-Up India facilitates bank loans between ₹10 Lakhs and ₹1 Crore.', 4, true
FROM schemes WHERE scheme_code = 'STANDUP_INDIA';

-- 2.6 PM SVANidhi Rules
INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'age', '>=', '18'::jsonb, 'eligibility', 
    'Applicant must be at least 18 years of age.', 1, true
FROM schemes WHERE scheme_code = 'PM_SVANIDHI';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'rural_or_urban', 'equals', '"urban"'::jsonb, 'eligibility', 
    'PM SVANidhi is designated for urban street vendors and micro-retailers in municipal areas.', 2, true
FROM schemes WHERE scheme_code = 'PM_SVANIDHI';

INSERT INTO scheme_rules (scheme_id, field_name, operator, expected_value, rule_type, error_message, priority, is_mandatory)
SELECT 
    id, 'loan_required', '<=', '50000'::jsonb, 'eligibility', 
    'PM SVANidhi covers initial working capital micro-loans up to ₹50,000.', 3, true
FROM schemes WHERE scheme_code = 'PM_SVANIDHI';
