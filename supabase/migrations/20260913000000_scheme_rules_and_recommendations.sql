-- ==============================================================================
-- VYAPAR MITRA: Scheme Rules, Extended Profiles & Recommendation Tables Migration
-- Matches specifications in Step 3, Step 4, Step 5 & Step 17
-- ==============================================================================

-- 1. Extend Schemes Table with Metadata
ALTER TABLE schemes 
    ADD COLUMN IF NOT EXISTS scheme_type VARCHAR(50) DEFAULT 'CENTRAL',
    ADD COLUMN IF NOT EXISTS target_sectors TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS target_occupations TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS target_states TEXT[] DEFAULT '{"ALL"}',
    ADD COLUMN IF NOT EXISTS target_categories TEXT[] DEFAULT '{"ALL"}',
    ADD COLUMN IF NOT EXISTS target_business_types TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS source_document_url TEXT,
    ADD COLUMN IF NOT EXISTS source_document_version VARCHAR(50) DEFAULT '1.0',
    ADD COLUMN IF NOT EXISTS search_representation TEXT;

-- Ensure eligibility_rules is valid JSONB
ALTER TABLE schemes ALTER COLUMN eligibility_rules SET DATA TYPE JSONB USING eligibility_rules::jsonb;

-- 2. Extend Entrepreneurs Table
ALTER TABLE entrepreneurs
    ADD COLUMN IF NOT EXISTS age INT,
    ADD COLUMN IF NOT EXISTS education VARCHAR(50),
    ADD COLUMN IF NOT EXISTS rural_or_urban VARCHAR(20) DEFAULT 'rural',
    ADD COLUMN IF NOT EXISTS occupation VARCHAR(100),
    ADD COLUMN IF NOT EXISTS experience_years NUMERIC(4, 1) DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS annual_income NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS previous_government_subsidy BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS previous_government_loan BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS previously_used_schemes TEXT[] DEFAULT '{}';

-- 3. Extend Sensitive Eligibility Profile
ALTER TABLE entrepreneur_eligibility_profile
    ADD COLUMN IF NOT EXISTS is_woman_entrepreneur BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS disability_category VARCHAR(50),
    ADD COLUMN IF NOT EXISTS minority_category VARCHAR(50),
    ADD COLUMN IF NOT EXISTS ex_serviceman_status BOOLEAN DEFAULT FALSE;

-- 4. Extend Businesses Table
ALTER TABLE businesses
    ADD COLUMN IF NOT EXISTS business_activity VARCHAR(150),
    ADD COLUMN IF NOT EXISTS business_type VARCHAR(100), -- manufacturing, service, trading
    ADD COLUMN IF NOT EXISTS business_status VARCHAR(50) DEFAULT 'new', -- new, existing, expansion
    ADD COLUMN IF NOT EXISTS sector VARCHAR(100),
    ADD COLUMN IF NOT EXISTS years_in_business NUMERIC(4, 1) DEFAULT 0.0,
    ADD COLUMN IF NOT EXISTS annual_turnover NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS number_of_employees INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS is_greenfield BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS total_project_cost NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS own_capital NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS loan_required NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS existing_loans BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS existing_loan_amount NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS monthly_emi NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS working_capital_requirement NUMERIC(15, 2) DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS machinery_equipment_cost NUMERIC(15, 2) DEFAULT 0.00;

-- 5. Scheme Rules Table (Atomic, Generic & Deterministic)
CREATE TABLE IF NOT EXISTS scheme_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    operator VARCHAR(30) NOT NULL, -- equals, not_equals, >, >=, <, <=, in, not_in, contains, contains_any, contains_all, between, exists
    expected_value JSONB NOT NULL,
    rule_type VARCHAR(30) DEFAULT 'eligibility', -- eligibility, subsidy_modifier, loan_modifier, condition
    error_message TEXT NOT NULL,
    priority INT DEFAULT 1,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scheme_rules_scheme ON scheme_rules(scheme_id);
CREATE INDEX IF NOT EXISTS idx_scheme_rules_field ON scheme_rules(field_name);

-- 6. Recommendation Runs Table
CREATE TABLE IF NOT EXISTS recommendation_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entrepreneur_id UUID REFERENCES entrepreneurs(id) ON DELETE SET NULL,
    business_id UUID REFERENCES businesses(id) ON DELETE SET NULL,
    profile_snapshot JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rec_runs_entrepreneur ON recommendation_runs(entrepreneur_id);
CREATE INDEX IF NOT EXISTS idx_rec_runs_business ON recommendation_runs(business_id);

-- 7. Scheme Recommendations Table
CREATE TABLE IF NOT EXISTS scheme_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recommendation_run_id UUID NOT NULL REFERENCES recommendation_runs(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    eligibility_status VARCHAR(50) NOT NULL, -- eligible, conditionally_eligible, needs_information, ineligible
    semantic_score NUMERIC(5, 4) DEFAULT 0.0000,
    eligibility_score NUMERIC(5, 4) DEFAULT 0.0000,
    final_score NUMERIC(5, 4) DEFAULT 0.0000,
    matched_rules JSONB DEFAULT '[]'::jsonb,
    failed_rules JSONB DEFAULT '[]'::jsonb,
    missing_rules JSONB DEFAULT '[]'::jsonb,
    estimated_subsidy NUMERIC(15, 2) DEFAULT 0.00,
    estimated_loan NUMERIC(15, 2) DEFAULT 0.00,
    explanation JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scheme_recs_run ON scheme_recommendations(recommendation_run_id);
CREATE INDEX IF NOT EXISTS idx_scheme_recs_scheme ON scheme_recommendations(scheme_id);

-- 8. Row Level Security (RLS) Policies
ALTER TABLE scheme_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE recommendation_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheme_recommendations ENABLE ROW LEVEL SECURITY;

-- Read-only public access for scheme rules (catalog rules are open)
CREATE POLICY "Allow public read access on scheme_rules" 
    ON scheme_rules FOR SELECT USING (true);

-- Recommendation runs viewable by authenticated owner through entrepreneur profile linkage
CREATE POLICY "Users can view their own recommendation runs" 
    ON recommendation_runs FOR SELECT 
    USING (
        auth.uid() IS NOT NULL AND 
        entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can create their own recommendation runs" 
    ON recommendation_runs FOR INSERT 
    WITH CHECK (
        auth.uid() IS NOT NULL AND 
        entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid())
    );

CREATE POLICY "Users can view their own recommendations" 
    ON scheme_recommendations FOR SELECT 
    USING (
        recommendation_run_id IN (
            SELECT r.id FROM recommendation_runs r
            JOIN entrepreneurs e ON r.entrepreneur_id = e.id
            WHERE e.user_id = auth.uid()
        )
    );
