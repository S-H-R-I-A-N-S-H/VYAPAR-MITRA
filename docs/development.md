# Development

## SIH 26091 — AI-Powered Business Advisory Assistant

**Purpose:** Define the practical development workflow, repository conventions, local setup, branching strategy, AI-coding-agent workflow, environment management, code quality, collaboration, and release process for building the SIH 26091 application safely and efficiently.

This document turns the architecture and product documents into a repeatable **build process**.

---

# 1. Development Philosophy

The project should use AI to accelerate implementation without allowing AI-generated code to determine the architecture by accident.

The core loop is:

```text
THINK
  ↓
SPECIFY
  ↓
GENERATE
  ↓
RUN
  ↓
OBSERVE
  ↓
GIVE AI EVIDENCE
  ↓
FIX
  ↓
VERIFY
  ↓
COMMIT
```

The team should optimize for:

```text
Fast learning
+
Small changes
+
Frequent testing
+
Clear ownership
+
Traceable decisions
```

rather than simply generating the maximum amount of code.

---

# 2. Human vs AI Responsibilities

## Humans own

- problem interpretation
- product scope
- architecture
- business rules
- UX decisions
- security policy
- financial rules
- evidence standards
- final acceptance
- demo story

## AI agents own/support

- boilerplate
- implementation
- refactoring
- test generation
- debugging
- documentation drafts
- repetitive code
- component creation
- API integration code
- migration drafts
- code review assistance

AI may suggest architecture changes, but humans must approve changes that materially affect the system.

---

# 3. Repository Structure

Recommended repository:

```text
sih-26091/
│
├── apps/
│   └── mobile/
│       └── Flutter application
│
├── backend/
│   └── FastAPI application
│
├── database/
│   ├── migrations/
│   ├── seeds/
│   └── tests/
│
├── packages/
│   └── shared contracts/models where genuinely useful
│
├── docs/
│   ├── product.md
│   ├── architecture.md
│   ├── database.md
│   ├── api-contracts.md
│   ├── ai-behaviour.md
│   ├── ux.md
│   ├── security.md
│   ├── testing.md
│   ├── development.md
│   └── decisions.md
│
├── scripts/
│
├── .github/
│   └── workflows/
│
├── .env.example
├── README.md
└── .gitignore
```

The exact repository layout may change, but the principles should remain:

```text
Application
Backend
Database
Documentation
Automation
Tests
```

must remain easy to find.

---

# 4. Documentation as AI Context

The `/docs` directory is part of the development system.

Before making a substantial change, an AI coding agent should read the relevant documents.

Minimum context:

```text
product.md
architecture.md
api-contracts.md
security.md
testing.md
```

Add:

```text
database.md
ai-behaviour.md
ux.md
```

when the task touches those areas.

---

# 5. Agent Context Hierarchy

When instructions conflict, use:

```text
Security constraints
        ↓
Product requirements
        ↓
Architecture
        ↓
API contract
        ↓
Database design
        ↓
AI behaviour
        ↓
UX
        ↓
Implementation preference
```

A convenient implementation must never override a security or product requirement.

---

# 6. AI Agent Handoff

Every agent should receive a focused task.

Good:

> Implement the business confirmation screen described in `ux.md`. Use the existing business API contract. Do not modify backend behaviour. Add loading, error, and edit states and reuse existing design-system components.

Bad:

> Build the entire app.

Large vague tasks encourage inconsistent architecture and difficult debugging.

---

# 7. Task Specification

Before assigning an implementation task, define:

```text
Goal
Scope
Inputs
Expected behaviour
Affected files/modules
API contract
Database impact
Acceptance criteria
Tests
Out of scope
```

Example:

```text
Goal:
Allow the entrepreneur to confirm the interpreted business definition.

Scope:
Flutter confirmation screen only.

API:
GET /businesses/{id}
POST /businesses/{id}/versions

Acceptance:
User can confirm or edit the business.
```

---

# 8. Feature Sizing

Prefer small vertical slices.

Bad:

```text
Build all research functionality.
```

Better:

```text
Build research-project creation.
Test.
Build research-job status.
Test.
Build evidence list.
Test.
Build evidence detail.
Test.
Build conflict display.
Test.
```

Each slice should produce something testable.

---

# 9. Vertical Feature Development

A feature should ideally travel through the full stack:

```text
UX
 ↓
API contract
 ↓
Backend
 ↓
Database
 ↓
Flutter
 ↓
Test
```

Do not create huge disconnected layers that cannot be tested.

---

# 10. Git Workflow

Use Git for version control.

Recommended:

```text
main
```

for stable/demo-ready code.

Feature branches:

```text
feature/onboarding
feature/research-evidence
feature/finance-scenarios
feature/scheme-matching
```

Bug fixes:

```text
fix/finance-validation
fix/survey-submission
```

---

# 11. Commit Strategy

Commit small logical changes.

Good:

```text
feat: add business confirmation screen
feat: add research job endpoint
fix: preserve financial scenario assumptions
test: add RLS ownership tests
```

Avoid:

```text
final changes
everything
fixed stuff
update
```

A commit should answer:

> What changed?

---

# 12. Commit After Verification

Preferred loop:

```text
Change
↓
Run tests
↓
Manual verification
↓
Commit
```

Do not commit known-broken code simply because an AI agent says the implementation is finished.

---

# 13. Pull Requests

For team collaboration, a pull request should include:

```text
What changed
Why
Screenshots for UI changes
Tests run
Known limitations
Database migrations
API contract changes
Security implications
```

Keep pull requests small enough to review.

---

# 14. Avoid Parallel-Agent Conflicts

Multiple AI agents should not independently redesign the same architectural area.

Before parallel work:

```text
Define shared contract
↓
Assign module ownership
↓
Separate files/modules
↓
Implement
↓
Integrate
```

Example:

```text
Agent A → Flutter onboarding
Agent B → FastAPI profile endpoint
Agent C → tests
```

They should share the same contract rather than inventing separate ones.

---

# 15. Shared Contract First

When frontend and backend are developed in parallel:

```text
API contract
        ↓
Frontend model
        +
Backend schema
        ↓
Tests
        ↓
Integration
```

This prevents:

```text
Flutter expects A
Backend returns B
```

---

# 16. Local Development Environment

The developer machine should have the project's core tooling installed.

Recommended:

```text
Git
GitHub access
Flutter SDK
Dart tooling
Android Studio
Android SDK
Android emulator/device
VS Code or preferred IDE
Python
FastAPI dependencies
Supabase CLI
Node.js where required by supporting tools
```

Only install tools actually required by the current project.

Avoid accumulating unrelated global dependencies.

---

# 17. Flutter Development

Flutter is the primary client framework.

Use:

```text
Dart
Flutter
Flutter AI Toolkit
```

Recommended project practices:

- feature-oriented folders
- reusable widgets
- typed models
- centralized API client
- repository pattern where useful
- state management chosen consistently
- design tokens
- localization architecture
- testable business/application logic

Do not put backend logic inside Flutter widgets.

---

# 18. Flutter Folder Concept

A feature-oriented structure may look like:

```text
lib/
├── core/
│   ├── networking/
│   ├── theme/
│   ├── localization/
│   ├── errors/
│   └── widgets/
│
├── features/
│   ├── onboarding/
│   ├── interview/
│   ├── business/
│   ├── opportunities/
│   ├── research/
│   ├── finance/
│   ├── schemes/
│   └── recommendations/
│
└── main.dart
```

The exact state-management architecture should be chosen once and used consistently.

---

# 19. Backend Development

FastAPI is the application backend.

Recommended conceptual structure:

```text
backend/
├── app/
│   ├── api/
│   ├── core/
│   ├── modules/
│   │   ├── profile/
│   │   ├── interview/
│   │   ├── business/
│   │   ├── research/
│   │   ├── evidence/
│   │   ├── surveys/
│   │   ├── analysis/
│   │   ├── finance/
│   │   ├── schemes/
│   │   └── ai/
│   │
│   ├── providers/
│   ├── services/
│   └── main.py
│
└── tests/
```

Keep provider-specific code inside `providers/`.

---

# 20. Backend Responsibilities

FastAPI should own:

```text
business logic
authorization
validation
AI orchestration
research orchestration
financial orchestration
provider adapters
API contracts
job management
security boundaries
```

Supabase should provide managed infrastructure rather than becoming a substitute for all application logic.

---

# 21. Database Development

Database changes should use migrations.

Never manually change production schema without recording the change in version-controlled migration files.

Conceptual workflow:

```text
Design
↓
Migration
↓
Local/test database
↓
Test
↓
Review
↓
Production
```

---

# 22. Migration Rules

Each migration should be:

```text
small
descriptive
versioned
reviewable
repeatable
```

Example:

```text
20260912_add_research_conflicts.sql
```

Do not repeatedly rewrite old migrations after they have been applied to shared environments.

---

# 23. Seed Data

Maintain safe seed/demo data for:

```text
demo entrepreneur
demo business
demo evidence
demo surveys
demo financial scenario
demo scheme records
```

Seeds should be deterministic.

A fresh development environment should be able to reach a known state.

---

# 24. Environment Variables

Use environment-specific configuration.

Example:

```text
.env
.env.example
```

`.env.example` should contain names but not secrets.

Example:

```text
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
GEMINI_API_KEY=
BHASHINI_API_KEY=
MAP_PROVIDER_KEY=
```

The actual values must never be committed.

---

# 25. Configuration Rules

Never hard-code:

```text
production URLs
API keys
tokens
passwords
provider secrets
environment-specific credentials
```

Configuration should be injected through environment/configuration mechanisms.

---

# 26. Provider Abstraction

External providers should be isolated.

Conceptually:

```text
AIService
   ↓
GeminiProvider

TranslationService
   ↓
BHASHINIProvider

MapService
   ↓
MapplsProvider

ResearchService
   ↓
SearchProvider
```

Application modules should depend on the service interface rather than directly importing provider-specific code everywhere.

---

# 27. Why Provider Abstraction Matters

If a provider changes:

```text
Provider A
↓
Provider B
```

the product should require minimal changes.

This also makes testing easier because a fake provider can replace the real one.

---

# 28. AI Development Workflow

When building an AI feature:

```text
Define desired behaviour
↓
Define structured output
↓
Define evidence/context
↓
Define failure cases
↓
Write prompt
↓
Implement
↓
Test with golden cases
↓
Review outputs
```

Do not start by writing a huge prompt before defining the actual product behaviour.

---

# 29. Prompt Files

Important prompts should live in version-controlled files or clearly versioned configuration.

Examples:

```text
prompts/
├── interview/
├── opportunity/
├── research/
├── analysis/
├── recommendations/
└── surveys/
```

Prompts should be treated like code.

---

# 30. Prompt Changes

A prompt change can change application behaviour.

Therefore:

```text
Prompt change
↓
Run AI evaluation
↓
Review important cases
↓
Update version
↓
Commit
```

Do not silently replace a production prompt.

---

# 31. AI Context Construction

For every AI operation, define:

```text
System rules
+
Task
+
Relevant user context
+
Relevant business context
+
Relevant evidence
+
Relevant constraints
```

Do not dump all available information into the prompt.

---

# 32. Research Development

Research should be developed in stages:

```text
Research question
↓
Provider retrieval
↓
Raw result
↓
Normalization
↓
Evidence extraction
↓
Quality assessment
↓
Conflict detection
↓
Analysis
```

Do not jump directly from:

```text
Search result → final recommendation
```

---

# 33. Research Reproducibility

A research/analysis run should preserve enough metadata to understand:

```text
what was researched
when
using which configuration/model
which evidence was used
which analysis version was used
```

This is important when results change later.

---

# 34. Financial Development

Implement financial calculations as deterministic services.

Conceptual:

```text
FinancialScenario
        ↓
Validation
        ↓
FinancialEngine
        ↓
FinancialResult
        ↓
AI explanation
```

The financial engine should have extensive unit tests.

---

# 35. Financial Code Rules

Financial code should:

- use clear variable names
- document formulas
- avoid hidden assumptions
- use appropriate numeric precision
- validate input ranges
- expose assumptions
- return structured results
- have edge-case tests

Do not hide formulas inside AI prompts.

---

# 36. UX Development

Every screen should have:

```text
Loading
Success
Empty
Error
Retry
```

where applicable.

Before implementing a screen, consult:

```text
ux.md
```

and reuse the design system.

---

# 37. Animation Development

Animations should be:

```text
purposeful
reusable
performant
interruptible where appropriate
```

Avoid generating one-off complex animations when a reusable component already exists.

Check performance on lower-end Android devices.

---

# 38. Dependency Management

Before adding a package, ask:

```text
Do we actually need it?
Is there already an existing dependency?
Is it maintained?
Does its license fit?
Does it increase app size?
Does it create security risk?
```

Do not add a library for a feature that can be implemented simply using existing tools.

---

# 39. AI-Generated Dependency Discipline

AI coding agents often add dependencies to solve small problems.

Agents must explain:

```text
Why this dependency is needed
What problem it solves
Whether an existing package can do it
License
Potential maintenance impact
```

The team can then approve/reject it.

---

# 40. Code Style

Use automated formatting and linting.

The repository should define consistent:

```text
formatting
naming
imports
line length where applicable
documentation style
error handling
```

Do not spend human time manually formatting code that tooling can format consistently.

---

# 41. Type Safety

Prefer typed interfaces.

Avoid excessive:

```text
dynamic
Any
untyped dictionaries
raw JSON throughout the application
```

Convert external responses into validated models near the boundary.

---

# 42. Error Handling

Use explicit error types/codes.

Example:

```text
AUTH_REQUIRED
NOT_AUTHORIZED
VALIDATION_ERROR
RESOURCE_NOT_FOUND
PROVIDER_UNAVAILABLE
RESEARCH_FAILED
AI_OUTPUT_INVALID
FINANCIAL_INPUT_INVALID
```

Flutter can then map predictable errors to user-friendly messages.

---

# 43. Logging During Development

Development logs should help identify:

```text
API failures
state transitions
provider failures
job IDs
request IDs
database errors
```

Never print:

```text
API keys
access tokens
passwords
sensitive user data
```

---

# 44. Debugging Workflow

When something fails:

```text
1. Reproduce
2. Capture exact error
3. Capture logs
4. Capture request/response
5. Identify affected layer
6. Form a hypothesis
7. Ask AI to diagnose using evidence
8. Implement minimal fix
9. Add regression test
10. Retest
```

This is preferable to repeatedly asking an AI agent to "try another fix."

---

# 45. Minimal Fix Principle

When debugging:

```text
Fix the root cause
```

rather than:

```text
Add random workarounds
```

Example:

If the frontend displays stale financial results because state is not invalidated, do not add arbitrary delays.

Fix the state lifecycle.

---

# 46. Code Review

Review AI-generated code for:

```text
correctness
security
architecture
performance
maintainability
tests
unnecessary complexity
unexpected dependencies
```

Especially inspect:

```text
auth
database queries
RLS
financial logic
AI tool permissions
file uploads
external API calls
```

---

# 47. Automated Checks

Before merging:

```text
format
lint
static analysis
unit tests
API tests
integration tests where applicable
Flutter tests
build
```

Critical branches should not merge with failing required checks.

---

# 48. CI/CD

CI/CD means automatically checking and delivering code through a controlled pipeline.

Conceptual:

```text
Push
 ↓
CI
 ↓
Tests
 ↓
Build
 ↓
Review
 ↓
Deploy
 ↓
Smoke test
```

The exact hosting/deployment provider can be decided separately.

---

# 49. Branch Protection

The stable branch should ideally require:

```text
passing checks
review/approval where appropriate
no unresolved critical failures
```

For a small hackathon team, keep the process lightweight but do not eliminate basic safeguards.

---

# 50. Local-to-Remote Workflow

Recommended:

```text
Local development
↓
Test
↓
Git commit
↓
Push
↓
CI
↓
Review
↓
Merge
↓
Deploy
```

Do not use production as the first place to test a new feature.

---

# 51. Production Configuration

Production must use:

```text
production secrets
production API URLs
production database
production provider configuration
```

Never copy a developer `.env` into production blindly.

---

# 52. Feature Flags

If a feature is experimental, use a feature flag where practical.

Example:

```text
VOICE_ENABLED
NEW_RESEARCH_UI
PREDICTION_LOOP_ENABLED
```

This allows safer rollout.

Do not create feature flags for every tiny UI change.

---

# 53. Demo Stability

The SIH demo build should be treated as a release candidate.

Before the demo:

```text
Freeze major architectural changes
↓
Run complete regression suite
↓
Test on actual demo device
↓
Verify external services
↓
Verify demo data
↓
Prepare fallback
```

Avoid introducing major new dependencies immediately before presentation.

---

# 54. Backup Plan

The team should maintain:

```text
working build
demo account
seeded demo data
important screenshots
short demo video
architecture backup
source code backup
```

If an external provider fails during the presentation, the product story should still be demonstrable.

---

# 55. Release Checklist

Before a release:

```text
□ Product scope verified
□ API contracts stable
□ Database migrations tested
□ RLS verified
□ Secrets checked
□ AI golden tests passed
□ Financial tests passed
□ End-to-end flow passed
□ Multilingual flow tested
□ Error states tested
□ Build tested
□ Demo data prepared
□ External providers verified
□ Smoke test plan ready
```

---

# 56. Documentation Updates

A development change may require updates to:

```text
product.md
architecture.md
database.md
api-contracts.md
ai-behaviour.md
ux.md
security.md
testing.md
development.md
decisions.md
```

Agents should explicitly identify which documents are affected.

---

# 57. Architecture Decision Records

Important architectural choices should be recorded in:

```text
docs/decisions.md
```

Example:

```text
Decision:
Use FastAPI between Flutter and external AI services.

Reason:
Centralize authorization, orchestration, provider secrets, and business logic.

Alternatives:
Direct Flutter → provider calls.

Rejected because:
Security and maintainability concerns.
```

This prevents the same debate from happening repeatedly.

---

# 58. Decision Rules

Do not make architectural decisions based only on:

```text
"AI says this is better."
```

Evaluate:

```text
requirements
complexity
security
performance
team capability
time
maintainability
```

Then record the decision.

---

# 59. Vibe-Coding Failure Prevention

The team must actively avoid:

### 1. Giant one-shot generation

### 2. Building without a specification

### 3. Trusting compilation as proof of correctness

### 4. Adding features before testing previous ones

### 5. Allowing every agent to modify everything

### 6. Ignoring errors instead of capturing evidence

### 7. Mixing secrets into source code

### 8. Allowing AI to invent business rules

### 9. Overusing dependencies

### 10. Building UI without backend contracts

### 11. Building backend without UX acceptance criteria

### 12. Treating a successful demo path as proof that the system is production-ready

---

# 60. The Agent Development Prompt Pattern

A strong coding-agent request should contain:

```text
CONTEXT
Read relevant docs.

TASK
Implement exactly this feature.

CONSTRAINTS
Do not change unrelated modules.
Follow architecture/security/API contracts.

ACCEPTANCE CRITERIA
1. ...
2. ...
3. ...

TESTING
Add/run tests for:
...

OUTPUT
Report:
- files changed
- tests run
- results
- known limitations
```

This gives the agent boundaries.

---

# 61. Evidence-Driven Coding

When giving an AI agent a bug:

```text
Context
+
Exact reproduction
+
Error
+
Logs
+
Screenshot
+
Expected behaviour
+
Actual behaviour
```

The more concrete the evidence, the less the agent needs to guess.

---

# 62. Reversible Development

Prefer changes that can be:

```text
tested
reviewed
reverted
```

Avoid giant changes that modify:

```text
frontend
backend
database
AI prompts
security
```

all at once unless the feature genuinely requires it.

---

# 63. Performance Discipline

Do not optimize prematurely.

First ensure:

```text
correctness
security
maintainability
```

Then measure.

Optimize based on actual evidence:

```text
slow query
slow API
large build
high memory
animation jank
AI latency
```

not assumptions.

---

# 64. Offline and Failure Development

Test failure states during development, not only success.

Simulate:

```text
backend unavailable
Gemini unavailable
search unavailable
database error
slow network
no GPS
translation failure
invalid AI output
```

The app should fail predictably.

---

# 65. Development Milestones

Recommended build sequence:

## Phase 1 — Foundation

```text
Repository
Flutter app
FastAPI app
Supabase project
Environment configuration
CI basics
Design system foundation
```

## Phase 2 — Identity

```text
Authentication
Profile
Onboarding
Language
Location
```

## Phase 3 — Discovery

```text
Interview
Business idea
No-idea flow
3–5 opportunities
Business confirmation
```

## Phase 4 — Validation

```text
Research jobs
Evidence
Primary survey
Conflict detection
Analysis
SWOT
```

## Phase 5 — Decision Support

```text
Recommendations
Financial engine
What-if scenarios
Government schemes
Action plan
```

## Phase 6 — Hardening

```text
Security
Testing
Performance
Multilingual
Voice
Error handling
Demo polish
```

## Phase 7 — Demo Release

```text
Freeze
Regression test
Deploy
Smoke test
Rehearse
Backup
```

---

# 66. Build Order Principle

Build the **smallest complete path** first.

Example:

```text
Onboarding
↓
Interview
↓
One business
↓
One research flow
↓
One evidence view
↓
One analysis
↓
One financial scenario
↓
One recommendation
```

Then expand.

This is safer than building ten incomplete features simultaneously.

---

# 67. Feature Completion Principle

A feature is not complete because:

```text
screen exists
```

It is complete when:

```text
UX
+
API
+
Database
+
Logic
+
Error handling
+
Tests
+
Security
```

are sufficiently implemented for its intended scope.

---

# 68. AI Agent Completion Report

Every significant coding-agent task should end with:

```text
Summary:
...

Files changed:
...

Tests run:
...

Tests passed:
...

Manual checks:
...

Known issues:
...

Docs updated:
...

Next recommended step:
...
```

This creates continuity between agents.

---

# 69. Final Development Workflow

The team's preferred workflow is:

```text
1. Understand the requirement
        ↓
2. Read relevant project docs
        ↓
3. Define acceptance criteria
        ↓
4. Define API/database impact
        ↓
5. Break into small feature
        ↓
6. Implement with AI assistance
        ↓
7. Run the feature
        ↓
8. Observe actual behaviour
        ↓
9. Capture evidence
        ↓
10. Give evidence to AI
        ↓
11. Fix root cause
        ↓
12. Add/update tests
        ↓
13. Retest
        ↓
14. Review
        ↓
15. Commit
        ↓
16. Move to next feature
```

---

# 70. Final Principle

AI coding should make the team faster, not make the system less understandable.

The project should always preserve:

```text
Human product ownership
+
Explicit architecture
+
Stable contracts
+
Secure boundaries
+
Evidence-driven debugging
+
Automated tests
+
Small commits
+
Documented decisions
```

The goal is not:

> **"Vibe code until the demo looks good."**

The goal is:

> **"Use AI to rapidly build a real system whose behaviour we can understand, test, debug, and trust."**
