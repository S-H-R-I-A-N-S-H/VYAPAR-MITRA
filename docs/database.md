# SIH 26091 — Database Design

**Document:** `docs/database.md`  
**Purpose:** Define the persistent data model for the SIH 26091 MVP, including relationships, ownership, evidence provenance, research, surveys, recommendations, financial scenarios, and future business-performance data.

> **Database principle:** Store structured facts and provenance explicitly. Do not use the database as a dumping ground for raw LLM conversations or unstructured JSON when a stable relational model is more appropriate.

---

# 1. Database Technology

## Recommended database

**Supabase PostgreSQL**

PostgreSQL is the primary relational database.

Supabase provides the managed PostgreSQL infrastructure and authentication integration.

### Why relational data?

The product has strongly connected entities:

```text
Entrepreneur
    ↓
Business
    ↓
Research Project
    ↓
Research Tasks
    ↓
Evidence
    ↓
Primary Surveys
    ↓
Responses
    ↓
Analysis
    ↓
Recommendations
    ↓
Financial Scenarios
    ↓
Actions
```

A relational database makes these relationships explicit and queryable.

---

# 2. Core Database Principles

1. Every user-owned record must have a clear owner or ownership path.
2. Important relationships should use foreign keys.
3. Important business rules should not live only inside JSON.
4. Evidence provenance must be persistent.
5. Source URLs and retrieval dates must be preserved.
6. Financial assumptions and calculated outputs must be distinguishable.
7. AI-generated content must be identifiable as AI-generated.
8. User-entered information must remain distinguishable from external evidence.
9. Historical recommendations should not silently change when new research arrives.
10. Sensitive information should be minimized and protected.
11. Database authorization must be enforced server-side.
12. Schema changes must be version-controlled through migrations.

---

# 3. Entity Relationship Overview

```text
auth.users
    │
    ▼
entrepreneurs
    │
    ├───────────────┐
    ▼               ▼
businesses      entrepreneur_preferences
    │
    ├───────────────┐
    │               │
    ▼               ▼
business_versions  research_projects
                        │
                        ├──────────────┐
                        ▼              ▼
                 research_tasks     evidence
                        │              │
                        │              ├──────────────┐
                        │              ▼              ▼
                        │          conflicts       claims
                        │
                        ▼
                   surveys
                        │
                        ▼
                  survey_responses
                        │
                        ▼
                 response_evidence

research_projects
        │
        ▼
analysis_runs
        │
        ▼
recommendations
        │
        ├───────────────┐
        ▼               ▼
 recommendation_evidence
                     financial_scenarios
                           │
                           ▼
                    financial_results

entrepreneurs
    │
    ▼
businesses
    │
    ▼
business_records
    │
    ▼
performance_metrics
```

The exact final SQL schema should be implemented through migrations after reviewing this model.

---

# 4. Authentication Boundary

Supabase Auth owns authentication identities.

The application should reference the authenticated user using the Supabase user ID.

Conceptually:

```text
auth.users
    │
    └── 1:1
        │
        ▼
entrepreneurs
```

Do not duplicate authentication credentials inside application tables.

The application profile stores product-specific information.

---

# 5. `entrepreneurs`

Represents the application's user profile.

## Core fields

```text
id
user_id
full_name
preferred_language
ui_language
voice_enabled
location_id
available_capital
business_experience
skills
interests
goals
risk_preference
created_at
updated_at
```

### Notes

`user_id` references the authenticated Supabase user.

`preferred_language` controls AI conversation language.

`ui_language` allows the UI language to be different from the AI language if the product eventually supports that choice.

`voice_enabled` represents user preference rather than whether the technical capability exists.

---

# 6. Sensitive Profile Information

Caste/community information may be needed for government-scheme matching.

This data is sensitive and should not be treated as ordinary profile decoration.

Conceptually:

```text
entrepreneur_eligibility_profile
├── entrepreneur_id
├── relevant_category
├── scheme_relevant_attributes
├── consent
├── consent_recorded_at
└── updated_at
```

### Important rule

Only collect information that is genuinely needed for a product function.

Do not expose sensitive eligibility information to:

- unrelated users;
- other entrepreneurs;
- analytics systems unnecessarily;
- AI prompts where it is not relevant.

The exact fields and consent UX must be finalized before implementation.

---

# 7. Location Model

Location is central to the product.

Conceptually:

```text
locations
├── id
├── state
├── district
├── town_or_village
├── pincode
├── latitude
├── longitude
├── source
└── created_at
```

A location can be associated with:

- entrepreneur;
- business;
- research project;
- evidence;
- business/competitor record.

This prevents the system from assuming that every piece of evidence belongs to the entrepreneur's exact location.

---

# 8. `businesses`

Represents a business being considered or operated by the entrepreneur.

## Suggested fields

```text
id
entrepreneur_id
name
status
domain
product_or_service
business_model
description
target_customer
intended_market
scale
created_at
updated_at
started_at
```

### Example statuses

```text
IDEA
VALIDATING
RECOMMENDED
PLANNED
STARTED
OPERATING
PAUSED
CLOSED
```

The exact state machine belongs to application logic.

---

# 9. Business Definition

The entrepreneur may initially provide an ambiguous idea.

Example:

> "I want to start a dairy business."

The system should create progressively refined business definitions.

A separate version table is recommended.

## `business_versions`

```text
id
business_id
version_number
business_definition
assumptions
source
created_by
created_at
confirmed_at
```

Possible `source` values:

```text
USER
AI_DRAFT
AI_REFINED
```

The final confirmed definition should remain historically available.

### Why versions?

If the entrepreneur changes:

> Dairy retail → paneer manufacturing

we should not overwrite the old definition and lose the history of the decision.

---

# 10. Entrepreneur Interview

The AI interview is a major product input.

The system should preserve enough structured information to reproduce how the entrepreneur profile was created.

## `interview_sessions`

```text
id
entrepreneur_id
business_id
status
language
started_at
completed_at
```

## `interview_messages`

```text
id
session_id
role
content
language
created_at
```

Possible roles:

```text
USER
ASSISTANT
SYSTEM
```

### Important

Raw conversation history should not automatically become the application's source of truth.

Important information extracted from the interview should be normalized into structured profile/business fields.

---

# 11. `entrepreneur_factors`

Optional structured representation of factors discovered during interviewing.

```text
id
entrepreneur_id
factor_type
factor
value
source
confidence
created_at
```

Potential factor types:

- skill;
- experience;
- interest;
- goal;
- constraint;
- resource;
- risk preference;
- available infrastructure.

This can help business-opportunity matching without repeatedly processing the entire interview history.

---

# 12. Research Projects

A research project represents one validation cycle for one business.

## `research_projects`

```text
id
business_id
location_id
status
research_scope
started_at
completed_at
created_at
updated_at
```

Possible statuses:

```text
PLANNED
SECONDARY_RESEARCH
PRIMARY_RESEARCH
ANALYSIS
COMPLETED
FAILED
CANCELLED
```

A business may have multiple research projects if the entrepreneur revisits or changes the business.

---

# 13. Research Questions

The AI should not perform vague research.

Each research project should contain explicit questions.

## `research_questions`

```text
id
research_project_id
question
category
priority
status
created_at
resolved_at
```

Potential categories:

- demand;
- customer;
- competition;
- pricing;
- supplier;
- distribution;
- purchasing_power;
- regulation;
- finance;
- risk;
- market_size.

---

# 14. Research Tasks

A research question can generate one or more tasks.

## `research_tasks`

```text
id
research_project_id
research_question_id
task_type
description
assigned_to
status
priority
created_at
completed_at
```

Potential task types:

```text
SECONDARY_RESEARCH
GOVERNMENT_SOURCE_LOOKUP
CUSTOMER_SURVEY
COMPETITOR_RESEARCH
SUPPLIER_RESEARCH
RETAILER_RESEARCH
MANUAL_INTERVIEW
FIELD_OBSERVATION
```

This makes the AI research process actionable.

---

# 15. Evidence

Evidence is one of the most important entities in the system.

## `evidence`

Conceptually:

```text
id
research_project_id
research_question_id
task_id
evidence_type
source_name
source_url
source_type
publication_date
accessed_at
geography
claim
extracted_value
unit
context
limitations
quality_score
confidence_score
created_by
created_at
```

Possible `evidence_type`:

```text
SECONDARY
PRIMARY
USER_PROVIDED
SYSTEM_DERIVED
```

Possible `source_type`:

```text
GOVERNMENT
OFFICIAL_INSTITUTION
TRUSTED_WEB
LOCAL_SURVEY
INTERVIEW
FIELD_OBSERVATION
ENTREPRENEUR
```

---

# 16. Evidence Provenance

Important evidence should answer:

> Where did this information come from?

Therefore, do not store only:

```text
"Demand is high."
```

Store something closer to:

```text
Claim:
Demand appears strong.

Source:
Official/local source

Geography:
Target locality

Date:
...

Evidence:
...

Limitations:
...

Confidence:
...

Research question:
...
```

This is essential for traceable recommendations.

---

# 17. Evidence Quality

A useful evidence model should separate:

### Source quality

How trustworthy is the source?

### Relevance

How directly does the source answer the question?

### Recency

How current is the information?

### Geographic fit

Does it actually apply to the target locality?

### Method quality

For primary research:

- sample size;
- respondent relevance;
- survey quality;
- geographic coverage.

These dimensions can later contribute to an evidence-quality score.

The exact scoring formula should be documented before implementation.

---

# 18. Claims

For more advanced traceability, a normalized claim model can be introduced.

## `claims`

```text
id
research_project_id
claim
category
status
confidence
created_at
```

Then:

```text
claim
  ↓
supported_by
  ↓
evidence
```

This is useful when multiple evidence items support the same conclusion.

The MVP can initially keep claims inside evidence/analysis structures if a separate claim table would create unnecessary complexity. Introduce it when traceability requirements justify it.

---

# 19. Evidence Conflicts

Conflicts must be stored explicitly.

## `evidence_conflicts`

```text
id
research_project_id
claim_or_question
description
severity
status
resolution
confidence_impact
created_at
resolved_at
```

## `evidence_conflict_items`

```text
id
conflict_id
evidence_id
position
```

Example:

```text
Conflict:
"Local demand"

Evidence A:
Government/secondary source → high demand

Evidence B:
Local survey → low purchase intent

System:
Conflict detected
Confidence reduced
Additional validation recommended
```

The system should preserve the conflicting evidence rather than deleting one side.

---

# 20. Surveys

## `surveys`

Represents an AI-generated research instrument.

```text
id
research_project_id
research_task_id
survey_type
title
description
language
status
created_by
created_at
```

Potential survey types:

```text
CUSTOMER
COMPETITOR
SUPPLIER
RETAILER
DISTRIBUTOR
OTHER
```

---

# 21. Survey Questions

## `survey_questions`

```text
id
survey_id
question
question_type
options
required
order_index
research_purpose
created_at
```

Potential question types:

```text
TEXT
NUMBER
SINGLE_CHOICE
MULTIPLE_CHOICE
RATING
YES_NO
PRICE
```

The exact types can expand later.

---

# 22. Survey Responses

## `survey_responses`

Represents one completed response/interview.

```text
id
survey_id
respondent_type
location_id
collection_method
collected_by
consent_status
created_at
```

Potential collection methods:

```text
IN_APP
MANUAL_ENTRY
```

The MVP does not require external Google Forms integration.

---

# 23. Survey Answers

## `survey_answers`

```text
id
response_id
question_id
answer
numeric_value
created_at
```

For sensitive data, only store what is required for analysis.

---

# 24. Response Evidence

Survey responses can become evidence.

## `response_evidence`

```text
id
response_id
evidence_id
created_at
```

This creates:

```text
Survey response
      ↓
Evidence
      ↓
Research analysis
      ↓
Recommendation
```

This is important because a recommendation should be traceable to actual primary responses.

---

# 25. Analysis Runs

An analysis should be treated as a versioned operation.

## `analysis_runs`

```text
id
research_project_id
analysis_type
input_snapshot
model_name
prompt_version
status
started_at
completed_at
created_at
```

Potential analysis types:

```text
MARKET
DEMAND
COMPETITION
SWOT
RISK
FEASIBILITY
CONFLICT
FINANCIAL
FINAL_RECOMMENDATION
```

### Why version analysis?

If the AI model or prompt changes later, the team should know which version produced an earlier recommendation.

---

# 26. Analysis Results

## `analysis_results`

```text
id
analysis_run_id
category
finding
reasoning_summary
confidence
created_at
```

Important findings should reference evidence.

---

# 27. Analysis Evidence Links

## `analysis_evidence`

```text
id
analysis_result_id
evidence_id
relationship
created_at
```

Possible relationships:

```text
SUPPORTS
CONTRADICTS
CONTEXT
```

This creates a traceable chain:

```text
Evidence
   ↓
Analysis finding
   ↓
Recommendation
```

---

# 28. Recommendations

## `recommendations`

```text
id
business_id
research_project_id
analysis_run_id
recommendation_type
title
summary
recommendation
confidence
status
created_at
```

Potential types:

```text
BUSINESS_GO
BUSINESS_CAUTION
BUSINESS_PIVOT
BUSINESS_REJECT
FINANCIAL
MARKET
NEXT_ACTION
```

The exact recommendation taxonomy can evolve.

---

# 29. Recommendation Evidence

## `recommendation_evidence`

```text
id
recommendation_id
evidence_id
relationship
created_at
```

Possible relationships:

```text
SUPPORTS
CONTRADICTS
CONTEXT
```

This allows the UI to show:

> "Why are we recommending this?"

and then display the relevant evidence.

---

# 30. Recommended Actions

## `recommended_actions`

```text
id
recommendation_id
business_id
title
description
priority
status
due_date
created_at
completed_at
```

This allows the final executive summary to transition from:

> Analysis

to:

> **What should I do next?**

---

# 31. Financial Scenarios

Financial planning should support multiple scenarios.

## `financial_scenarios`

```text
id
business_id
research_project_id
name
description
scenario_type
created_by
created_at
updated_at
```

Potential types:

```text
BASE
CONSERVATIVE
OPTIMISTIC
CUSTOM
```

---

# 32. Financial Assumptions

## `financial_assumptions`

```text
id
scenario_id
project_cost
own_capital
loan_amount
interest_rate
tenure_months
expected_monthly_revenue
monthly_fixed_cost
monthly_variable_cost
other_monthly_cost
tax_assumption
created_at
updated_at
```

This is an initial conceptual model.

The exact financial model should be finalized before implementation.

---

# 33. Financial Results

## `financial_results`

```text
id
scenario_id
monthly_revenue
monthly_expenses
monthly_profit
monthly_cash_available
emi
total_interest
total_repayment
break_even_months
affordability_status
created_at
```

### Important

These values should be generated by deterministic backend code.

The LLM can explain them but should not be the source of arithmetic.

---

# 34. Financial Calculation Audit

For important calculations, consider preserving calculation inputs and formula versions.

## `financial_calculation_runs`

```text
id
scenario_id
formula_version
input_snapshot
result_snapshot
created_at
```

This helps reproduce:

> "Why did the system calculate this repayment?"

and protects against silent formula changes.

---

# 35. Government Schemes

Government scheme information should eventually become structured data.

## `government_schemes`

```text
id
name
authority
description
official_url
scheme_type
status
last_verified
created_at
updated_at
```

Additional structured eligibility information can be normalized into related tables.

---

# 36. Scheme Eligibility Rules

## `scheme_rules`

```text
id
scheme_id
rule_type
field
operator
value
description
version
effective_from
effective_until
created_at
```

Examples:

```text
AGE >= X
PROJECT_COST <= Y
LOCATION = ...
BUSINESS_TYPE IN (...)
CATEGORY IN (...)
```

Do not allow an LLM to invent these rules during runtime.

Rules should be derived from authoritative scheme information and reviewed by the team.

---

# 37. Scheme Match Results

## `scheme_matches`

```text
id
business_id
entrepreneur_id
scheme_id
eligibility_status
confidence
reason
checked_at
```

Possible statuses:

```text
LIKELY_ELIGIBLE
POTENTIALLY_ELIGIBLE
NOT_ELIGIBLE
INSUFFICIENT_INFORMATION
```

The system should avoid claiming official approval.

---

# 38. Business Records — Future Logbook

The long-term digital logbook needs structured business transactions.

## `business_records`

```text
id
business_id
record_type
amount
currency
description
recorded_at
source
created_at
```

Potential record types:

```text
SALE
EXPENSE
PURCHASE
OTHER_INCOME
OTHER_EXPENSE
```

---

# 39. Record Source

The `source` field can distinguish:

```text
MANUAL
VOICE
IMPORT
SYSTEM
```

For voice entries, the raw audio should not automatically be stored forever. Store only what is necessary unless there is a clear product reason to retain audio.

---

# 40. Performance Metrics

Long-term analysis can aggregate business records.

## `performance_metrics`

```text
id
business_id
period_start
period_end
revenue
expenses
profit
cash_flow
customer_count
other_metrics
created_at
```

These can support:

> Prediction → Reality

analysis.

---

# 41. Predictions

The original feasibility assumptions should be preserved.

## `business_predictions`

```text
id
business_id
research_project_id
metric
period
predicted_value
unit
confidence
created_at
```

Then compare against actual performance.

```text
Prediction
      ↓
Actual business record
      ↓
Variance
      ↓
Insight
```

---

# 42. Prediction vs Reality

## `prediction_comparisons`

```text
id
prediction_id
actual_metric_reference
predicted_value
actual_value
variance
variance_percentage
interpretation
created_at
```

This supports the long-term product differentiator.

---

# 43. AI Context Snapshots

AI calls should be reproducible enough for debugging.

For important AI operations, store metadata such as:

```text
model
prompt_version
task_type
input_reference_ids
output_schema_version
created_at
```

Avoid storing sensitive raw prompts/responses unnecessarily.

The database should reference structured records whenever possible.

---

# 44. Do Not Store Everything as JSON

JSON is useful for flexible information, but it should not replace relational design.

### Good JSON candidates

- flexible AI metadata;
- model-specific response details;
- variable survey options;
- raw provider metadata;
- evolving research configuration.

### Bad JSON candidates

Do not store the entire application in:

```text
user_data JSON
```

or:

```text
business_data JSON
```

when the application needs to query:

- businesses;
- research projects;
- evidence;
- financial scenarios;
- recommendations;
- transactions.

Important queryable data should have real columns and relationships.

---

# 45. Data Ownership

The application should be able to answer:

> Which entrepreneur owns this record?

Examples:

```text
recommendation
    → research_project
        → business
            → entrepreneur
```

This ownership path is essential for authorization.

---

# 46. Row-Level Security

Supabase Row-Level Security (RLS) should protect user-owned data.

Conceptually:

```text
Authenticated user
       ↓
Can access
       ↓
Own entrepreneur record
       ↓
Own businesses
       ↓
Own research
       ↓
Own evidence
       ↓
Own surveys/responses
       ↓
Own recommendations
       ↓
Own financial scenarios
```

Users must not be able to access another entrepreneur's records by changing an ID in a request.

Server-side authorization remains necessary even when RLS is enabled.

---

# 47. Public vs Private Data

Not every piece of information has the same privacy level.

### Private

- entrepreneur profile;
- financial information;
- caste/community information;
- interview history;
- business records;
- survey data;
- private recommendations.

### Potentially shareable/aggregate

- anonymized market statistics;
- aggregated survey findings;
- public government information;
- public business information.

The product should not expose raw respondent information unnecessarily.

---

# 48. Survey Respondent Privacy

The MVP should collect only information needed to answer the research question.

Avoid collecting unnecessary:

- names;
- phone numbers;
- addresses;
- personal identifiers.

If respondent identity is not required, the system should support anonymous responses.

---

# 49. Timestamps

Important records should have:

```text
created_at
updated_at
```

Time-sensitive evidence should additionally preserve:

```text
publication_date
accessed_at
```

Business records should preserve the actual event/transaction date separately from database creation time.

---

# 50. Soft Deletion / Historical Integrity

Important evidence and analysis should generally not be hard-deleted merely because newer research exists.

Instead, consider:

```text
status
archived_at
```

This helps preserve historical recommendations.

For user-requested deletion of personal data, a proper deletion/anonymization policy must be implemented separately.

---

# 51. Database Migrations

All schema changes must be version-controlled.

Recommended:

```text
supabase/
└── migrations/
    ├── 001_initial_schema.sql
    ├── 002_research.sql
    ├── 003_surveys.sql
    ├── 004_finance.sql
    └── ...
```

Never manually change production schema without recording the change as a migration.

---

# 52. Seed Data

The repository should eventually contain controlled seed data for:

- development users;
- sample businesses;
- sample evidence;
- sample survey responses;
- sample government schemes;
- test financial scenarios.

Seed data should never contain real personal information.

---

# 53. Test Database

Automated tests should use isolated test data.

Important test cases:

### Ownership

User A cannot access User B's business.

### Evidence

Evidence retains correct research-project relationship.

### Conflicts

Two contradictory evidence items can be associated with one conflict.

### Surveys

Survey responses map to the correct question.

### Finance

Given identical inputs, calculations are deterministic.

### Recommendations

Recommendation evidence links point to valid evidence.

### State

A business cannot accidentally jump into an invalid lifecycle state.

---

# 54. Database Indexing

Indexes should be added based on real query patterns.

Likely important indexes include:

```text
entrepreneurs.user_id

businesses.entrepreneur_id
businesses.status

research_projects.business_id
research_projects.status

research_questions.research_project_id

research_tasks.research_project_id
research_tasks.status

evidence.research_project_id
evidence.research_question_id

surveys.research_project_id

survey_responses.survey_id

recommendations.business_id
recommendations.research_project_id

financial_scenarios.business_id

business_records.business_id
business_records.recorded_at
```

Do not blindly index every column.

---

# 55. Database Query Principle

The Flutter app should not perform arbitrary database operations everywhere.

Preferred flow:

```text
Flutter
   ↓
Repository/API layer
   ↓
FastAPI
   ↓
Application service
   ↓
Supabase/PostgreSQL
```

Direct Supabase access from Flutter can be used for carefully selected safe operations if the architecture explicitly allows it, but critical business workflows should pass through controlled backend services.

---

# 56. Research Snapshot Principle

A recommendation should be reproducible from the research state that produced it.

Therefore an analysis should preserve references to:

- research project;
- evidence set;
- analysis version;
- model/prompt version;
- financial scenario;
- recommendation version.

This prevents:

> "The evidence changed, so we no longer know why the old recommendation existed."

---

# 57. Versioning Principle

The following should be version-aware:

- business definition;
- research project;
- analysis;
- recommendation;
- financial formulas;
- scheme rules;
- AI prompt versions.

This creates an auditable history.

---

# 58. Recommended MVP Database Subset

Do not build every future table immediately.

### Phase 1 — Foundation

- `entrepreneurs`
- `locations`
- `businesses`
- `business_versions`
- `entrepreneur_factors`

### Phase 2 — Research

- `research_projects`
- `research_questions`
- `research_tasks`
- `evidence`
- `evidence_conflicts`
- `evidence_conflict_items`

### Phase 3 — Primary Research

- `surveys`
- `survey_questions`
- `survey_responses`
- `survey_answers`
- `response_evidence`

### Phase 4 — Analysis

- `analysis_runs`
- `analysis_results`
- `analysis_evidence`
- `recommendations`
- `recommendation_evidence`
- `recommended_actions`

### Phase 5 — Finance

- `financial_scenarios`
- `financial_assumptions`
- `financial_results`
- `financial_calculation_runs`
- `government_schemes`
- `scheme_rules`
- `scheme_matches`

### Future

- `business_records`
- `performance_metrics`
- `business_predictions`
- `prediction_comparisons`

---

# 59. Database Anti-Patterns to Avoid

## One giant table

Do not create:

```text
everything
```

with dozens of unrelated columns.

## One giant JSON document

Do not store the whole entrepreneur/business state as one JSON blob.

## LLM-generated schema

Do not allow an AI coding agent to repeatedly redesign the database based on its current interpretation.

## Missing foreign keys

Relationships should be explicit.

## No timestamps

Time matters heavily for research and business performance.

## Overwriting historical analysis

Research is iterative; historical decisions need traceability.

## Mixing user data and public evidence

Keep entrepreneur-owned information distinct from externally sourced evidence.

## Storing secrets

Never put API keys in database rows unless a dedicated secure secret-management design explicitly requires it.

---

# 60. Data Flow Example

For:

> "I want to start a ₹5 lakh bakery in Indore."

The database flow is approximately:

```text
Entrepreneur
   ↓
Business
   ↓
Business Version
   ↓
Research Project
   ↓
Research Questions
   ↓
Research Tasks
   ↓
Secondary Evidence
   ↓
Information Gaps
   ↓
Survey
   ↓
Survey Questions
   ↓
Survey Responses
   ↓
Primary Evidence
   ↓
Conflict Detection
   ↓
Analysis Run
   ↓
Analysis Results
   ↓
Recommendation
   ↓
Financial Scenario
   ↓
Financial Result
   ↓
Recommended Actions
```

---

# 61. No-Idea Entrepreneur Data Flow

For an entrepreneur without a fixed idea:

```text
Entrepreneur
   ↓
Interview
   ↓
Entrepreneur Factors
   ↓
Location
   ↓
Opportunity Research
   ↓
Candidate Opportunities
   ↓
Entrepreneur selects one
   ↓
Business created
   ↓
Normal validation pipeline
```

Candidate opportunities may initially be generated as an AI result. Once the entrepreneur chooses one, it becomes a real `business` record.

---

# 62. Database Rules for AI Agents

Any AI coding agent modifying the database must:

1. Read `product.md`.
2. Read `architecture.md`.
3. Read this document.
4. Search the existing schema before creating a new table.
5. Prefer extending an existing entity over duplicating it.
6. Use migrations.
7. Add foreign keys where appropriate.
8. Add RLS policies for user-owned data.
9. Never weaken authorization to make a feature work.
10. Never store secrets in ordinary application tables.
11. Never replace structured financial fields with LLM-generated text.
12. Preserve evidence provenance.
13. Preserve historical analysis where required.
14. Add/modify tests for important database behavior.
15. Update this document when the schema meaningfully changes.
16. Never drop or rename production data structures without a migration and documented decision.
17. Never invent a column simply because it makes a prompt easier.
18. Check whether a field is sensitive before exposing it to AI context.

---

# 63. Database Completion Criteria for SIH MVP

The database layer is sufficiently complete when:

- an authenticated entrepreneur can be created;
- location can be stored;
- an entrepreneur can have one or more businesses;
- business definitions can be versioned;
- research projects can be created;
- research questions/tasks can be tracked;
- secondary evidence can be stored with provenance;
- primary survey responses can be stored;
- evidence conflicts can be represented;
- analysis results can reference evidence;
- recommendations can reference evidence;
- financial scenarios and assumptions can be stored;
- financial results are reproducible;
- scheme information can be associated with a business/entrepreneur;
- user ownership is enforced;
- migrations can reproduce the database;
- test/seed data can reproduce the SIH demo.

---

# 64. Final Database Principle

> **The database should remember what happened, where the evidence came from, what the system believed at that time, what the entrepreneur decided, and how the business eventually performed.**

That historical continuity is what allows the product to eventually evolve from:

> **AI feasibility assistant**

into:

> **AI business companion that learns from prediction → reality.**
