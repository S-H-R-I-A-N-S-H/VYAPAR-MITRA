-- ==============================================================================
-- VYAPAR MITRA: Production Security & Integrity Migration
-- Fixes: CRIT-2 (RLS), CRIT-5 (UNIQUE entrepreneur user_id),
--        HIGH-3 (UNIQUE business version), DB3/DB4/DB5 (missing indexes)
-- ==============================================================================

-- ============================================================
-- 1. UNIQUE Constraints
-- ============================================================

-- FIX CRIT-5: Each auth user can only have ONE entrepreneur profile.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'entrepreneurs_user_id_key'
    ) THEN
        ALTER TABLE entrepreneurs ADD CONSTRAINT entrepreneurs_user_id_key UNIQUE (user_id);
    END IF;
END $$;

-- FIX HIGH-3: Business version numbers must be unique per business.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'business_versions_business_id_version_number_key'
    ) THEN
        ALTER TABLE business_versions
            ADD CONSTRAINT business_versions_business_id_version_number_key
            UNIQUE (business_id, version_number);
    END IF;
END $$;

-- ============================================================
-- 2. Performance Indexes (missing from initial schema)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_entrepreneurs_user_id ON entrepreneurs(user_id);
CREATE INDEX IF NOT EXISTS idx_interview_messages_session_id ON interview_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_interview_messages_session_created ON interview_messages(session_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_entrepreneur_id ON interview_sessions(entrepreneur_id);
CREATE INDEX IF NOT EXISTS idx_businesses_entrepreneur_status ON businesses(entrepreneur_id, status);
CREATE INDEX IF NOT EXISTS idx_research_projects_business_status ON research_projects(business_id, status);

-- ============================================================
-- 3. Row Level Security (RLS)
-- FIX CRIT-2 / DB11: All user-data tables must have RLS enabled.
-- Policies use auth.uid() which Supabase populates from the JWT sub claim.
-- ============================================================

ALTER TABLE entrepreneurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE entrepreneur_eligibility_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE interview_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE research_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE research_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE surveys ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE schemes ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Entrepreneurs
-- ============================================================
DROP POLICY IF EXISTS "entrepreneurs_select_own" ON entrepreneurs;
CREATE POLICY "entrepreneurs_select_own" ON entrepreneurs FOR SELECT USING (user_id = auth.uid()::uuid);

DROP POLICY IF EXISTS "entrepreneurs_insert_own" ON entrepreneurs;
CREATE POLICY "entrepreneurs_insert_own" ON entrepreneurs FOR INSERT WITH CHECK (user_id = auth.uid()::uuid);

DROP POLICY IF EXISTS "entrepreneurs_update_own" ON entrepreneurs;
CREATE POLICY "entrepreneurs_update_own" ON entrepreneurs FOR UPDATE
    USING (user_id = auth.uid()::uuid) WITH CHECK (user_id = auth.uid()::uuid);

-- ============================================================
-- Locations (readable/insertable by any authenticated user)
-- ============================================================
DROP POLICY IF EXISTS "locations_select_authenticated" ON locations;
CREATE POLICY "locations_select_authenticated" ON locations FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "locations_insert_authenticated" ON locations;
CREATE POLICY "locations_insert_authenticated" ON locations FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================================
-- Entrepreneur Eligibility Profile
-- ============================================================
DROP POLICY IF EXISTS "eligibility_select_own" ON entrepreneur_eligibility_profile;
CREATE POLICY "eligibility_select_own" ON entrepreneur_eligibility_profile FOR SELECT
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "eligibility_insert_own" ON entrepreneur_eligibility_profile;
CREATE POLICY "eligibility_insert_own" ON entrepreneur_eligibility_profile FOR INSERT
    WITH CHECK (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "eligibility_update_own" ON entrepreneur_eligibility_profile;
CREATE POLICY "eligibility_update_own" ON entrepreneur_eligibility_profile FOR UPDATE
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

-- ============================================================
-- Businesses
-- ============================================================
DROP POLICY IF EXISTS "businesses_select_own" ON businesses;
CREATE POLICY "businesses_select_own" ON businesses FOR SELECT
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "businesses_insert_own" ON businesses;
CREATE POLICY "businesses_insert_own" ON businesses FOR INSERT
    WITH CHECK (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "businesses_update_own" ON businesses;
CREATE POLICY "businesses_update_own" ON businesses FOR UPDATE
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "businesses_delete_own" ON businesses;
CREATE POLICY "businesses_delete_own" ON businesses FOR DELETE
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

-- ============================================================
-- Business Versions
-- ============================================================
DROP POLICY IF EXISTS "business_versions_select_own" ON business_versions;
CREATE POLICY "business_versions_select_own" ON business_versions FOR SELECT
    USING (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "business_versions_insert_own" ON business_versions;
CREATE POLICY "business_versions_insert_own" ON business_versions FOR INSERT
    WITH CHECK (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Interview Sessions
-- ============================================================
DROP POLICY IF EXISTS "interview_sessions_select_own" ON interview_sessions;
CREATE POLICY "interview_sessions_select_own" ON interview_sessions FOR SELECT
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "interview_sessions_insert_own" ON interview_sessions;
CREATE POLICY "interview_sessions_insert_own" ON interview_sessions FOR INSERT
    WITH CHECK (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

DROP POLICY IF EXISTS "interview_sessions_update_own" ON interview_sessions;
CREATE POLICY "interview_sessions_update_own" ON interview_sessions FOR UPDATE
    USING (entrepreneur_id IN (SELECT id FROM entrepreneurs WHERE user_id = auth.uid()::uuid));

-- ============================================================
-- Interview Messages
-- ============================================================
DROP POLICY IF EXISTS "interview_messages_select_own" ON interview_messages;
CREATE POLICY "interview_messages_select_own" ON interview_messages FOR SELECT
    USING (session_id IN (
        SELECT s.id FROM interview_sessions s JOIN entrepreneurs e ON e.id = s.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "interview_messages_insert_own" ON interview_messages;
CREATE POLICY "interview_messages_insert_own" ON interview_messages FOR INSERT
    WITH CHECK (session_id IN (
        SELECT s.id FROM interview_sessions s JOIN entrepreneurs e ON e.id = s.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Research Projects
-- ============================================================
DROP POLICY IF EXISTS "research_projects_select_own" ON research_projects;
CREATE POLICY "research_projects_select_own" ON research_projects FOR SELECT
    USING (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "research_projects_insert_own" ON research_projects;
CREATE POLICY "research_projects_insert_own" ON research_projects FOR INSERT
    WITH CHECK (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "research_projects_update_own" ON research_projects;
CREATE POLICY "research_projects_update_own" ON research_projects FOR UPDATE
    USING (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Research Questions
-- ============================================================
DROP POLICY IF EXISTS "research_questions_select_own" ON research_questions;
CREATE POLICY "research_questions_select_own" ON research_questions FOR SELECT
    USING (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "research_questions_insert_own" ON research_questions;
CREATE POLICY "research_questions_insert_own" ON research_questions FOR INSERT
    WITH CHECK (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Evidence & Conflicts
-- ============================================================
DROP POLICY IF EXISTS "evidence_select_own" ON evidence;
CREATE POLICY "evidence_select_own" ON evidence FOR SELECT
    USING (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "evidence_insert_own" ON evidence;
CREATE POLICY "evidence_insert_own" ON evidence FOR INSERT
    WITH CHECK (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "conflicts_select_own" ON conflicts;
CREATE POLICY "conflicts_select_own" ON conflicts FOR SELECT
    USING (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Surveys, Questions, Responses
-- ============================================================
DROP POLICY IF EXISTS "surveys_select_own" ON surveys;
CREATE POLICY "surveys_select_own" ON surveys FOR SELECT
    USING (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "surveys_insert_own" ON surveys;
CREATE POLICY "surveys_insert_own" ON surveys FOR INSERT
    WITH CHECK (research_project_id IN (
        SELECT rp.id FROM research_projects rp
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "survey_questions_select_own" ON survey_questions;
CREATE POLICY "survey_questions_select_own" ON survey_questions FOR SELECT
    USING (survey_id IN (
        SELECT sv.id FROM surveys sv
        JOIN research_projects rp ON rp.id = sv.research_project_id
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "survey_questions_insert_own" ON survey_questions;
CREATE POLICY "survey_questions_insert_own" ON survey_questions FOR INSERT
    WITH CHECK (survey_id IN (
        SELECT sv.id FROM surveys sv
        JOIN research_projects rp ON rp.id = sv.research_project_id
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "survey_responses_select_own" ON survey_responses;
CREATE POLICY "survey_responses_select_own" ON survey_responses FOR SELECT
    USING (survey_id IN (
        SELECT sv.id FROM surveys sv
        JOIN research_projects rp ON rp.id = sv.research_project_id
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "survey_responses_insert_own" ON survey_responses;
CREATE POLICY "survey_responses_insert_own" ON survey_responses FOR INSERT
    WITH CHECK (survey_id IN (
        SELECT sv.id FROM surveys sv
        JOIN research_projects rp ON rp.id = sv.research_project_id
        JOIN businesses b ON b.id = rp.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Financial Scenarios & Results
-- ============================================================
DROP POLICY IF EXISTS "financial_scenarios_select_own" ON financial_scenarios;
CREATE POLICY "financial_scenarios_select_own" ON financial_scenarios FOR SELECT
    USING (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "financial_scenarios_insert_own" ON financial_scenarios;
CREATE POLICY "financial_scenarios_insert_own" ON financial_scenarios FOR INSERT
    WITH CHECK (business_id IN (
        SELECT b.id FROM businesses b JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "financial_results_select_own" ON financial_results;
CREATE POLICY "financial_results_select_own" ON financial_results FOR SELECT
    USING (scenario_id IN (
        SELECT fs.id FROM financial_scenarios fs
        JOIN businesses b ON b.id = fs.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

DROP POLICY IF EXISTS "financial_results_insert_own" ON financial_results;
CREATE POLICY "financial_results_insert_own" ON financial_results FOR INSERT
    WITH CHECK (scenario_id IN (
        SELECT fs.id FROM financial_scenarios fs
        JOIN businesses b ON b.id = fs.business_id
        JOIN entrepreneurs e ON e.id = b.entrepreneur_id WHERE e.user_id = auth.uid()::uuid
    ));

-- ============================================================
-- Schemes: public catalog — any authenticated user can read
-- ============================================================
DROP POLICY IF EXISTS "schemes_select_authenticated" ON schemes;
CREATE POLICY "schemes_select_authenticated" ON schemes FOR SELECT USING (auth.role() = 'authenticated');
