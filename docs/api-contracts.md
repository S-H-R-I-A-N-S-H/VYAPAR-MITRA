# API Contracts

## SIH 26091 — AI-Powered Business Advisory Assistant

**Purpose:** Define the communication contract between the Flutter client and the Python/FastAPI backend so frontend, backend, AI, database, and external-service agents can work independently without breaking each other.

---

## 1. API Philosophy

The API is the stable boundary between the Flutter application and backend services.

### Core rules

1. Flutter does not contain business-critical secrets.
2. Flutter does not directly perform sensitive AI, financial, research, or government-data orchestration.
3. FastAPI owns application/business logic.
4. Supabase remains the managed authentication/database/storage layer.
5. Gemini, BHASHINI, Mappls/MapmyIndia, web search, and government sources are accessed through controlled backend/provider layers where credentials or orchestration are required.
6. AI-generated output must use structured schemas whenever the frontend depends on specific fields.
7. Financial calculations that affect recommendations must be deterministic; the LLM explains results rather than inventing them.
8. Every research claim that reaches a recommendation should be traceable to evidence.
9. Long-running research must use asynchronous jobs rather than blocking a normal HTTP request.
10. API contracts are versioned and documented before implementation.

---

# 2. System Boundary

```text
Flutter App
    |
    | HTTPS / JSON
    v
FastAPI Backend
    |
    +--> Supabase Auth
    +--> Supabase PostgreSQL
    +--> Supabase Storage
    +--> Gemini
    +--> BHASHINI
    +--> Mappls / MapmyIndia
    +--> Web Search / Trusted Sources
    +--> Government Data / Scheme Sources
```

Flutter should know **what** operation it wants, not **how** providers are orchestrated.

Example:

```text
Flutter:
POST /api/v1/research/projects

Backend:
create project
 -> generate research questions
 -> collect secondary evidence
 -> normalize evidence
 -> detect conflicts
 -> prepare analysis
```

The frontend should not need to know which search provider, model call, parser, or database query was used internally.

---

# 3. Base API

## Production

```text
https://<production-api-domain>/api/v1
```

## Local development

```text
http://localhost:<port>/api/v1
```

The exact production domain and port are deployment decisions and must not be hard-coded into source files.

---

# 4. Versioning

All public endpoints begin with:

```text
/api/v1/
```

Example:

```text
/api/v1/profile
/api/v1/businesses
/api/v1/research/projects
/api/v1/finance/scenarios
```

Breaking changes create a new API version.

```text
/api/v1/...
/api/v2/...
```

Do not silently change the meaning or required structure of an existing endpoint.

---

# 5. Transport and Data Format

Default:

```text
HTTPS
Content-Type: application/json
Accept: application/json
```

Dates/times should use ISO 8601.

Example:

```text
2026-09-12T10:30:00Z
```

Identifiers should be UUIDs where practical.

Example:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000"
}
```

Do not expose database implementation details unnecessarily.

---

# 6. Authentication

Supabase Auth is the identity provider.

Flutter authenticates the user through Supabase Auth and sends the resulting access token to FastAPI.

Header:

```http
Authorization: Bearer <access_token>
```

FastAPI must validate the token before accessing protected resources.

### Public endpoints

Only endpoints explicitly designed as public may omit authentication.

### Protected endpoints

Most application endpoints require authentication.

Examples:

```text
GET  /profile
POST /businesses
POST /research/projects
GET  /recommendations
POST /finance/scenarios
```

---

# 7. Authorization

Authentication answers:

> Who is this user?

Authorization answers:

> Is this user allowed to access this resource?

FastAPI must enforce ownership and role/business rules.

Example:

```text
User A requests User B's research project
        |
        v
      403 Forbidden
```

Do not rely only on Flutter to hide unauthorized data.

Supabase Row Level Security (RLS) should provide a second protection layer for database access.

---

# 8. Standard Success Envelope

For operations where a consistent envelope is useful:

```json
{
  "success": true,
  "data": {},
  "meta": {}
}
```

`meta` is optional.

Example:

```json
{
  "success": true,
  "data": {
    "id": "business-id",
    "name": "Spice Processing Unit"
  },
  "meta": {
    "request_id": "request-id"
  }
}
```

Simple endpoints may return the resource directly if the project adopts that convention consistently. Do not mix conventions randomly within the same API family.

---

# 9. Standard Error Format

All predictable API errors should follow a common structure.

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "One or more fields are invalid.",
    "details": [],
    "request_id": "request-id"
  }
}
```

### Recommended HTTP statuses

| Status | Meaning |
|---|---|
| 200 | Successful request |
| 201 | Resource created |
| 202 | Accepted for asynchronous processing |
| 204 | Successful request with no response body |
| 400 | Malformed/invalid request |
| 401 | Missing or invalid authentication |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict |
| 422 | Validation failure |
| 429 | Rate limit exceeded |
| 500 | Unexpected server error |
| 502/503 | External dependency/service problem |

The frontend should use `error.code` for predictable UI behaviour instead of matching human-readable error messages.

---

# 10. Request IDs

Every API request should receive a request ID.

Example header:

```text
X-Request-ID: abc123
```

The ID should appear in logs and error responses.

This allows:

```text
Flutter error
    -> request ID
    -> FastAPI log
    -> provider call
    -> database operation
```

to be traced during debugging.

---

# 11. Pagination

List endpoints should support pagination.

Example:

```text
GET /businesses?limit=20&offset=0
```

Response:

```json
{
  "success": true,
  "data": [],
  "meta": {
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

Cursor pagination may be introduced later for large datasets.

---

# 12. Profile and Onboarding APIs

## GET `/profile`

Returns the entrepreneur profile.

```json
{
  "id": "user-id",
  "name": "Example User",
  "preferred_language": "hi",
  "ui_language": "hi",
  "voice_enabled": true,
  "location_id": "location-id",
  "available_capital": 500000,
  "experience": [],
  "skills": [],
  "interests": [],
  "goals": [],
  "risk_preference": "moderate"
}
```

Sensitive eligibility information should not be returned unless the user is authorized and the field is required.

---

## PATCH `/profile`

Updates editable onboarding/profile information.

Example:

```json
{
  "preferred_language": "hi",
  "ui_language": "hi",
  "voice_enabled": true,
  "available_capital": 500000,
  "skills": ["food_processing"],
  "goals": ["income_growth"]
}
```

The backend validates allowed values.

---

# 13. Location APIs

## POST `/locations`

Stores or resolves a user's location.

Example:

```json
{
  "state": "Madhya Pradesh",
  "district": "Indore",
  "town": "Example Town",
  "pincode": "000000",
  "latitude": 22.7,
  "longitude": 75.8,
  "source": "user"
}
```

The API should distinguish:

```text
user-provided
GPS-derived
map-provider-derived
research-derived
```

Location data must not automatically be treated as exact if the source is approximate.

---

## GET `/locations/{location_id}`

Returns normalized location information.

---

# 14. Interview APIs

The interview helps understand the entrepreneur before recommending business opportunities.

## POST `/interviews`

Creates an interview session.

```json
{
  "language": "hi",
  "mode": "chat"
}
```

Response:

```json
{
  "id": "interview-id",
  "status": "active"
}
```

---

## POST `/interviews/{interview_id}/messages`

Adds an entrepreneur message.

```json
{
  "role": "user",
  "content": "I have experience making snacks.",
  "language": "hi"
}
```

The backend may return structured extracted factors alongside the conversational response.

```json
{
  "reply": {
    "text": "That experience could be useful..."
  },
  "extracted_factors": [
    {
      "factor": "experience",
      "value": "snack making",
      "confidence": 0.91
    }
  ],
  "next_question": "What equipment do you already have?"
}
```

The conversational wording is AI-generated; the stored factor structure is application data.

---

## POST `/interviews/{interview_id}/complete`

Marks the interview complete and prepares inputs for opportunity discovery.

---

# 15. Business APIs

## POST `/businesses`

Creates a business/idea.

```json
{
  "name": "Example Food Business",
  "domain": "food_processing",
  "product_service": "Millet snacks",
  "description": "Local millet-based snack business",
  "target_customer": "local consumers"
}
```

---

## GET `/businesses`

Returns the user's businesses.

---

## GET `/businesses/{business_id}`

Returns the current business state.

---

## POST `/businesses/{business_id}/versions`

Creates a new version when the business idea changes.

```json
{
  "product_service": "Millet snacks for school and office customers",
  "description": "...",
  "reason": "Research showed stronger demand from this segment."
}
```

Never overwrite important historical business definitions when a change needs to remain traceable.

---

# 16. Opportunity Discovery APIs

Used when the entrepreneur does not have a fixed business idea.

## POST `/opportunities/discover`

Request:

```json
{
  "interview_id": "interview-id",
  "location_id": "location-id",
  "capital": 500000,
  "count": 5
}
```

Response:

```json
{
  "opportunities": [
    {
      "id": "opportunity-id",
      "title": "Millet Snack Processing",
      "summary": "...",
      "why_it_may_fit": [
        "Relevant experience",
        "Local market signal"
      ],
      "initial_evidence_ids": [
        "evidence-id-1",
        "evidence-id-2"
      ]
    }
  ]
}
```

The system should not present AI-generated opportunities as established facts without supporting evidence.

---

## POST `/opportunities/{opportunity_id}/select`

Records the entrepreneur's decision.

```json
{
  "selected": true
}
```

This decision becomes part of the product's traceable history.

---

# 17. Research APIs

Research is a long-running process and should use jobs.

## POST `/research/projects`

Creates a research project.

```json
{
  "business_id": "business-id",
  "research_scope": {
    "geography": "local",
    "radius_km": 10
  }
}
```

Response:

```json
{
  "project_id": "project-id",
  "status": "created"
}
```

---

## POST `/research/projects/{project_id}/start`

Starts research.

Response:

```http
202 Accepted
```

```json
{
  "job_id": "job-id",
  "status": "queued"
}
```

---

## GET `/jobs/{job_id}`

Returns processing state.

Possible states:

```text
queued
running
completed
failed
cancelled
```

Example:

```json
{
  "id": "job-id",
  "type": "secondary_research",
  "status": "running",
  "progress": 62,
  "message": "Analyzing local market evidence."
}
```

---

# 18. Research Evidence APIs

## GET `/research/projects/{project_id}/evidence`

Returns evidence collected for a research project.

Evidence should expose provenance.

Example:

```json
{
  "id": "evidence-id",
  "source": {
    "name": "Official Government Source",
    "url": "https://example.gov.in",
    "type": "government"
  },
  "published_at": "2026-01-10",
  "accessed_at": "2026-09-12T10:30:00Z",
  "geography": "Indore",
  "claim": "Example claim",
  "value": 123,
  "unit": "households",
  "quality": {
    "authority": 0.95,
    "recency": 0.90,
    "geographic_relevance": 0.85
  },
  "confidence": 0.89
}
```

---

## GET `/evidence/{evidence_id}`

Returns a single evidence record and its provenance.

---

# 19. Evidence Conflict APIs

## GET `/research/projects/{project_id}/conflicts`

Returns conflicting or materially inconsistent evidence.

Example:

```json
{
  "conflicts": [
    {
      "id": "conflict-id",
      "topic": "market_demand",
      "severity": "high",
      "summary": "Two sources report materially different demand estimates.",
      "evidence_ids": [
        "evidence-a",
        "evidence-b"
      ],
      "status": "open"
    }
  ]
}
```

The UI should make important evidence conflicts visible instead of silently choosing one source.

---

# 20. Primary Research / Survey APIs

## POST `/surveys`

Creates an AI-generated or manually configured survey.

```json
{
  "business_id": "business-id",
  "respondent_type": "customer",
  "purpose": "demand_validation"
}
```

The backend generates structured questions where appropriate.

---

## GET `/surveys/{survey_id}`

Returns survey questions.

```json
{
  "id": "survey-id",
  "title": "Customer Demand Survey",
  "language": "hi",
  "questions": [
    {
      "id": "question-id",
      "type": "single_choice",
      "text": "How often would you buy this product?",
      "options": [
        "Daily",
        "Weekly",
        "Monthly",
        "Rarely"
      ],
      "required": true
    }
  ]
}
```

---

## POST `/surveys/{survey_id}/responses`

Stores a completed response.

```json
{
  "answers": [
    {
      "question_id": "question-id",
      "value": "Weekly"
    }
  ]
}
```

Responses must not be modified in ways that destroy auditability.

---

## POST `/primary-research/interviews`

Allows the entrepreneur to manually enter field interviews.

```json
{
  "business_id": "business-id",
  "respondent_type": "retailer",
  "language": "hi",
  "transcript": "..."
}
```

The backend can extract structured findings while preserving the original input.

---

# 21. Analysis APIs

## POST `/analysis/runs`

Starts an analysis run after sufficient evidence is available.

```json
{
  "research_project_id": "research-project-id",
  "analysis_type": "business_validation"
}
```

Response:

```json
{
  "analysis_run_id": "analysis-id",
  "status": "queued"
}
```

---

## GET `/analysis/runs/{analysis_run_id}`

Returns analysis status/result.

A completed result should be structured.

```json
{
  "status": "completed",
  "summary": {
    "verdict": "promising_with_conditions",
    "confidence": 0.82,
    "key_reasons": [
      "Evidence indicates local demand.",
      "Competition is present but fragmented."
    ]
  },
  "swot": {
    "strengths": [],
    "weaknesses": [],
    "opportunities": [],
    "threats": []
  },
  "evidence_ids": [],
  "conflict_ids": []
}
```

---

# 22. Recommendation APIs

## GET `/recommendations/business/{business_id}`

Returns current recommendations.

A recommendation should contain:

```json
{
  "id": "recommendation-id",
  "title": "Start with a smaller pilot",
  "recommendation": "...",
  "reasoning": "...",
  "evidence_ids": [
    "evidence-id"
  ],
  "confidence": 0.84,
  "priority": "high",
  "actions": [
    {
      "title": "Interview 20 local customers",
      "status": "pending"
    }
  ]
}
```

The API should distinguish:

```text
evidence
interpretation
recommendation
action
```

rather than returning an opaque AI paragraph.

---

# 23. Financial APIs

Financial logic is a critical backend boundary.

## POST `/finance/scenarios`

Creates a scenario.

```json
{
  "business_id": "business-id",
  "initial_investment": 500000,
  "own_capital": 150000,
  "loan_amount": 350000,
  "expected_monthly_revenue": 180000,
  "monthly_operating_cost": 110000,
  "loan_interest_rate": 10.5,
  "loan_tenure_months": 36
}
```

---

## POST `/finance/scenarios/{scenario_id}/calculate`

Runs deterministic financial calculations.

Possible outputs:

```json
{
  "loan_amount": 350000,
  "estimated_monthly_emi": 11300,
  "estimated_monthly_profit": 70000,
  "estimated_cash_surplus_after_emi": 58700,
  "break_even_estimate": {},
  "affordability": {
    "status": "acceptable",
    "reason": "..."
  }
}
```

The exact financial formulas must be defined separately in the financial-engine specification.

---

## POST `/finance/scenarios/{scenario_id}/what-if`

Allows user-adjustable parameters.

Example:

```json
{
  "monthly_revenue": 150000,
  "loan_amount": 300000
}
```

The system recalculates rather than asking Gemini to estimate the result.

---

# 24. Government Scheme APIs

## GET `/schemes`

Returns relevant government schemes.

Filters may include:

```text
state
business_domain
loan_type
entrepreneur_category
investment_range
```

---

## GET `/schemes/{scheme_id}`

Returns scheme details, including:

```text
official source
eligibility
benefits
loan/subsidy structure
applicable geography
last verified date
version
```

Government scheme information must retain source and verification metadata.

---

## POST `/schemes/match`

Matches a user's business/profile to eligible schemes.

```json
{
  "business_id": "business-id"
}
```

Response:

```json
{
  "matches": [
    {
      "scheme_id": "scheme-id",
      "eligibility_status": "likely_eligible",
      "reasons": [],
      "missing_information": []
    }
  ]
}
```

Do not describe uncertain eligibility as guaranteed approval.

---

# 25. AI Chat API

The app may use Flutter AI Toolkit for conversational UI.

The backend should expose a controlled conversational interface when application context, authorization, tools, or persistent business state are involved.

Example:

```text
POST /api/v1/ai/chat
```

Request:

```json
{
  "conversation_id": "conversation-id",
  "message": "Is this business viable?",
  "language": "hi",
  "business_id": "business-id"
}
```

Response:

```json
{
  "message": {
    "text": "...",
    "language": "hi"
  },
  "context_used": {
    "business_id": "business-id",
    "research_project_id": "research-id"
  },
  "evidence_ids": [
    "evidence-id"
  ]
}
```

If streaming is implemented, use a documented streaming protocol such as Server-Sent Events (SSE) or WebSocket. The choice must be consistent across the Flutter client and FastAPI implementation.

---

# 26. Language and Voice APIs

BHASHINI should sit behind a provider adapter.

The frontend should not depend on raw provider-specific request formats.

Conceptual endpoints:

```text
POST /language/translate
POST /language/speech-to-text
POST /language/text-to-speech
GET  /language/supported
```

Example:

```json
{
  "text": "What product should I sell?",
  "source_language": "en",
  "target_language": "hi"
}
```

Provider-specific credentials remain server-side.

---

# 27. Maps and Location Intelligence

Mappls/MapmyIndia should be accessed through a controlled integration layer where application-specific location intelligence is required.

Conceptual endpoints:

```text
GET /maps/search
GET /maps/reverse-geocode
GET /maps/nearby-businesses
```

The API should normalize provider responses before returning them to Flutter.

Example:

```json
{
  "places": [
    {
      "name": "Example Store",
      "category": "retail",
      "latitude": 22.7,
      "longitude": 75.8,
      "distance_km": 2.4
    }
  ]
}
```

---

# 28. Research Provider Boundary

The backend should use provider adapters.

```text
ResearchService
    |
    +--> WebSearchProvider
    +--> GovernmentSourceProvider
    +--> MapProvider
```

This prevents provider-specific code from spreading through the application.

If the search provider changes later, the public API should remain stable.

---

# 29. Idempotency

Operations that may be retried should support idempotency.

Example header:

```text
Idempotency-Key: <unique-key>
```

Important for:

```text
creating research jobs
creating financial calculations
submitting important actions
payment-related operations
```

A retry should not accidentally create duplicate records or execute an operation twice.

---

# 30. Asynchronous Jobs

Long-running operations should not keep a normal HTTP request open.

Examples:

```text
secondary research
large evidence processing
AI analysis
document processing
large survey analysis
```

Pattern:

```text
POST /research/start
        |
        v
202 Accepted
        |
        v
job_id
        |
        v
GET /jobs/{job_id}
        |
        v
completed / failed
```

Future implementation may use a task queue/background worker system if needed. The API contract should remain independent of the specific queue technology.

---

# 31. Validation Rules

Validation must happen on the backend even if Flutter performs client-side validation.

Examples:

- Required fields cannot be empty.
- Numeric financial values cannot violate defined ranges.
- Enum values must be known.
- UUIDs must be valid.
- Users cannot access another user's resources.
- Unsupported languages must produce a controlled response.
- Invalid business states must be rejected.

Client validation improves UX; backend validation provides trust.

---

# 32. AI Output Validation

Never assume Gemini output is automatically correct.

Pipeline:

```text
User request
    |
    v
Gemini
    |
    v
Structured output
    |
    v
Schema validation
    |
    +--> valid -> application logic
    |
    +--> invalid -> retry/fallback/error
```

AI responses that contain application data should use schemas.

Examples:

```text
OpportunitySchema
EvidenceSummarySchema
AnalysisSchema
RecommendationSchema
SurveySchema
```

---

# 33. AI Does Not Own Application Truth

Gemini must not be treated as the source of truth for:

- authentication
- authorization
- user identity
- financial arithmetic
- database state
- government eligibility rules
- evidence provenance
- final application state
- payment state

Gemini may:

- summarize evidence
- explain calculations
- generate interview questions
- generate survey questions
- identify patterns
- propose hypotheses
- translate/explain
- draft recommendations

The backend decides what becomes official application state.

---

# 34. Security Requirements

Never put these in Flutter source code:

```text
Gemini secret API key
BHASHINI secret credentials
database service-role key
private provider credentials
payment secrets
server-only tokens
```

Use environment variables/secrets management on the backend.

Never log:

```text
passwords
access tokens
private API keys
sensitive eligibility information
unnecessary personal information
```

External web content must be treated as untrusted input.

A webpage must never be allowed to override system instructions merely because its text contains instructions.

---

# 35. Rate Limiting

Rate limits should exist for expensive operations.

Especially:

```text
AI calls
research jobs
web search
speech processing
translation
large analysis operations
```

If a limit is reached:

```http
429 Too Many Requests
```

with a machine-readable error code.

---

# 36. API Observability

Each important request should be traceable through:

```text
request_id
user_id
endpoint
timestamp
duration
status
error_code
provider calls where safe
job_id where applicable
```

Do not log sensitive content merely for debugging.

---

# 37. Flutter Integration Rules

Flutter should have a typed API/data layer.

Conceptually:

```text
Flutter UI
    |
Application/State
    |
Repository
    |
API Client
    |
FastAPI
```

Avoid making raw HTTP calls throughout UI widgets.

Bad:

```text
Button -> directly calls HTTP -> parses JSON -> updates UI
```

Better:

```text
Button
 -> application action
 -> repository
 -> API client
 -> typed response
 -> state update
 -> UI
```

This makes the app easier for multiple AI coding agents to modify safely.

---

# 38. API Client Models

Frontend models should represent stable API contracts.

Example:

```text
Business
Evidence
ResearchProject
ResearchJob
Survey
SurveyResponse
AnalysisResult
Recommendation
FinancialScenario
SchemeMatch
```

Avoid exposing raw database tables directly as the frontend's permanent data model.

---

# 39. API Contract Testing

Every endpoint should eventually have:

1. Request validation test
2. Successful response test
3. Authentication test
4. Authorization test
5. Invalid input test
6. External-service failure test where applicable
7. Database failure test where applicable
8. Regression test for previously fixed bugs

The frontend should have mock/stub responses for development where possible.

---

# 40. API Documentation

FastAPI should generate OpenAPI documentation.

The team should maintain:

```text
/docs/api-contracts.md
```

and keep it aligned with implementation.

Generated OpenAPI documentation should be treated as an implementation verification layer, not as a replacement for product-level API decisions.

---

# 41. Recommended Endpoint Map

```text
/api/v1
│
├── profile
├── locations
│
├── interviews
│   └── {id}/messages
│
├── businesses
│   └── {id}/versions
│
├── opportunities
│   ├── discover
│   └── {id}/select
│
├── research
│   ├── projects
│   └── projects/{id}/evidence
│
├── evidence
│   └── {id}
│
├── surveys
│   └── {id}/responses
│
├── primary-research
│   └── interviews
│
├── analysis
│   └── runs
│
├── recommendations
│
├── finance
│   └── scenarios
│
├── schemes
│   └── match
│
├── ai
│   └── chat
│
├── language
│
├── maps
│
└── jobs
    └── {id}
```

This is the initial contract surface, not a requirement to implement every endpoint in the first MVP.

---

# 42. MVP API Scope

The first working MVP should prioritize:

```text
Authentication
Profile/onboarding
Location
Interview
Business/idea
Opportunity discovery
Secondary research
Evidence
Basic primary research
Analysis
Recommendations
Financial scenario
Government scheme matching
AI chat
```

Future modules can include:

```text
business logbook
operational tracking
prediction-to-reality
supplier workflows
retailer workflows
advanced analytics
continuous monitoring
```

---

# 43. Multi-Agent Development Contract

Before an AI coding agent changes an endpoint, it must:

1. Read this API contract.
2. Read `product.md`.
3. Read `architecture.md`.
4. Read `database.md`.
5. Identify affected endpoint(s).
6. Preserve existing request/response compatibility unless intentionally versioning.
7. Add/update validation.
8. Add/update tests.
9. Update documentation.
10. Report any contract change explicitly.

An agent must not invent a new endpoint simply because it is convenient for implementation.

---

# 44. Feature Development Loop

For every feature:

```text
Product requirement
      ↓
API contract
      ↓
Database impact
      ↓
Backend implementation
      ↓
Tests
      ↓
Flutter integration
      ↓
Manual test
      ↓
Real evidence/logs
      ↓
Fix
      ↓
Retest
      ↓
Git commit
```

The API contract should be decided before multiple agents independently implement the same feature.

---

# 45. Anti-Patterns

Avoid:

### 1. Direct provider calls everywhere

```text
Flutter -> Gemini
Flutter -> Maps
Flutter -> random search API
```

This creates security and maintenance problems.

### 2. AI-generated arbitrary JSON

If the UI expects a schema, validate it.

### 3. Business logic in widgets

Financial calculations, eligibility decisions, and research orchestration belong behind stable application/backend boundaries.

### 4. Returning giant opaque AI paragraphs

Prefer structured:

```text
claim
evidence
reasoning
recommendation
action
```

### 5. Silent contract changes

Changing a response field can break another agent's code.

### 6. Synchronous research

Do not hold an HTTP request open while performing large research tasks.

### 7. Trusting client validation

The backend must validate independently.

### 8. Exposing database internals

Do not make the API a thin uncontrolled mirror of every PostgreSQL table.

---

# 46. Definition of Done

An API feature is complete when:

- endpoint contract is documented
- authentication is defined
- authorization is enforced
- request validation exists
- response schema is stable
- error codes are defined
- database interaction is correct
- external providers are isolated behind adapters
- AI outputs are schema-validated where required
- important operations are idempotent
- tests exist
- logs/request IDs exist
- Flutter integration works
- failure states are handled
- documentation matches implementation
- changes are committed to Git

---

# 47. Final Principle

The API is the **contract between independent parts of the product**.

It should make it possible for:

```text
Flutter agent
Backend agent
Database agent
AI agent
Research agent
UX agent
Testing agent
```

to work in parallel without each one guessing how the others work.

The goal is not to create the largest API.

The goal is to create a **small, stable, typed, secure, traceable boundary** that lets the SIH 26091 product evolve without becoming fragile.

> **Define the contract → implement behind it → validate it → test it → integrate it.**
