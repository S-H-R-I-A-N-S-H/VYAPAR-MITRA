-- ==============================================================================
-- VYAPAR MITRA: Core Relational Database Schema
-- Matches specifications in docs/database.md and docs/architecture.md
-- ==============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Locations
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    town_or_village VARCHAR(150) NOT NULL,
    pincode VARCHAR(10),
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    source VARCHAR(50) DEFAULT 'USER_SELECTED',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Entrepreneurs (Profile)
CREATE TABLE IF NOT EXISTS entrepreneurs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL, -- references auth.users
    full_name VARCHAR(150) NOT NULL,
    preferred_language VARCHAR(10) DEFAULT 'hi',
    ui_language VARCHAR(10) DEFAULT 'hi',
    voice_enabled BOOLEAN DEFAULT TRUE,
    location_id UUID REFERENCES locations(id) ON DELETE SET NULL,
    available_capital NUMERIC(15, 2) DEFAULT 0.00,
    skills TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',
    goals TEXT,
    risk_preference VARCHAR(30) DEFAULT 'moderate',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Sensitive Scheme-Eligibility Profile (Optional & Consented)
CREATE TABLE IF NOT EXISTS entrepreneur_eligibility_profile (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entrepreneur_id UUID NOT NULL REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    category VARCHAR(50) DEFAULT 'general',
    gender VARCHAR(30),
    consent_given BOOLEAN DEFAULT FALSE,
    consent_recorded_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Businesses
CREATE TABLE IF NOT EXISTS businesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entrepreneur_id UUID NOT NULL REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    status VARCHAR(50) DEFAULT 'IDEA', -- IDEA, VALIDATING, RECOMMENDED, PLANNED, OPERATING
    domain VARCHAR(100) NOT NULL,
    product_or_service VARCHAR(200) NOT NULL,
    business_model TEXT,
    description TEXT,
    target_customer TEXT,
    intended_market TEXT,
    scale VARCHAR(50) DEFAULT 'micro',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Business Versions (Traceability of refined assumptions)
CREATE TABLE IF NOT EXISTS business_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    version_number INT NOT NULL DEFAULT 1,
    business_definition TEXT NOT NULL,
    assumptions JSONB DEFAULT '{}',
    source VARCHAR(50) DEFAULT 'USER', -- USER, AI_DRAFT, AI_REFINED
    created_at TIMESTAMPTZ DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ
);

-- 6. Guided Interview Sessions & Messages
CREATE TABLE IF NOT EXISTS interview_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entrepreneur_id UUID NOT NULL REFERENCES entrepreneurs(id) ON DELETE CASCADE,
    business_id UUID REFERENCES businesses(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    language VARCHAR(10) DEFAULT 'hi',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS interview_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES interview_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- USER, ASSISTANT, SYSTEM
    content TEXT NOT NULL,
    language VARCHAR(10) DEFAULT 'hi',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Research Projects, Questions, and Tasks
CREATE TABLE IF NOT EXISTS research_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    location_id UUID REFERENCES locations(id) ON DELETE SET NULL,
    status VARCHAR(50) DEFAULT 'PLANNED',
    research_scope VARCHAR(50) DEFAULT 'local_5km',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS research_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    research_project_id UUID NOT NULL REFERENCES research_projects(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    category VARCHAR(50) NOT NULL,
    priority INT DEFAULT 1,
    status VARCHAR(30) DEFAULT 'open',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- 8. Evidence & Conflicts
CREATE TABLE IF NOT EXISTS evidence (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    research_project_id UUID NOT NULL REFERENCES research_projects(id) ON DELETE CASCADE,
    claim TEXT NOT NULL,
    extracted_value VARCHAR(100),
    unit VARCHAR(30),
    source_name VARCHAR(200) NOT NULL,
    source_url TEXT,
    source_type VARCHAR(50) NOT NULL, -- GOVERNMENT, TRUSTED_WEB, FIELD_PRIMARY, LOCAL_SURVEY
    geography VARCHAR(100),
    confidence_score NUMERIC(3, 2) DEFAULT 0.50,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS conflicts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    research_project_id UUID NOT NULL REFERENCES research_projects(id) ON DELETE CASCADE,
    secondary_evidence_id UUID REFERENCES evidence(id) ON DELETE CASCADE,
    primary_evidence_id UUID REFERENCES evidence(id) ON DELETE CASCADE,
    topic VARCHAR(100) NOT NULL,
    discrepancy_explanation TEXT NOT NULL,
    impact_on_confidence VARCHAR(30) DEFAULT 'medium_risk',
    suggested_action TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Surveys & Field Responses
CREATE TABLE IF NOT EXISTS surveys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    research_project_id UUID NOT NULL REFERENCES research_projects(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    target_respondent_type VARCHAR(50) DEFAULT 'customer',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS survey_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type VARCHAR(30) DEFAULT 'multiple_choice',
    options JSONB DEFAULT '[]',
    sort_order INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS survey_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    survey_id UUID NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
    respondent_identifier VARCHAR(100),
    answers JSONB NOT NULL,
    collector_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Financial Scenarios & Deterministic Results
CREATE TABLE IF NOT EXISTS financial_scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    business_id UUID NOT NULL REFERENCES businesses(id) ON DELETE CASCADE,
    scenario_name VARCHAR(100) DEFAULT 'Base Scenario',
    total_project_cost NUMERIC(15, 2) NOT NULL,
    own_capital NUMERIC(15, 2) NOT NULL,
    loan_amount NUMERIC(15, 2) NOT NULL,
    interest_rate_pct NUMERIC(5, 2) NOT NULL,
    tenure_months INT NOT NULL,
    monthly_revenue_est NUMERIC(15, 2) NOT NULL,
    monthly_operating_cost_est NUMERIC(15, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS financial_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_id UUID NOT NULL REFERENCES financial_scenarios(id) ON DELETE CASCADE,
    monthly_emi NUMERIC(15, 2) NOT NULL,
    total_interest NUMERIC(15, 2) NOT NULL,
    total_repayment NUMERIC(15, 2) NOT NULL,
    monthly_net_profit NUMERIC(15, 2) NOT NULL,
    monthly_cash_flow_after_emi NUMERIC(15, 2) NOT NULL,
    debt_service_coverage_ratio NUMERIC(5, 2) NOT NULL,
    is_affordable BOOLEAN NOT NULL,
    affordability_risk_level VARCHAR(30) NOT NULL,
    affordability_rationale TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Government Schemes Catalog
CREATE TABLE IF NOT EXISTS schemes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scheme_code VARCHAR(50) UNIQUE NOT NULL,
    official_name VARCHAR(250) NOT NULL,
    authority VARCHAR(150) NOT NULL,
    max_loan_limit NUMERIC(15, 2),
    max_subsidy_pct NUMERIC(5, 2) DEFAULT 0.00,
    official_portal_url TEXT,
    eligibility_rules JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_businesses_entrepreneur ON businesses(entrepreneur_id);
CREATE INDEX IF NOT EXISTS idx_research_business ON research_projects(business_id);
CREATE INDEX IF NOT EXISTS idx_evidence_research ON evidence(research_project_id);
CREATE INDEX IF NOT EXISTS idx_surveys_research ON surveys(research_project_id);
CREATE INDEX IF NOT EXISTS idx_financial_scenarios_business ON financial_scenarios(business_id);
