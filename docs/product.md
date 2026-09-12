# SIH 26091 --- Product Definition

**Document:** `docs/product.md`\
**Purpose:** Single source of truth for what the product is, who it
serves, what it does, what the SIH MVP must prove, and what is
intentionally deferred.

------------------------------------------------------------------------

## 1. Product Identity

### Product name

**VYAPAR MITRA --- Full-Lifecycle Evidence-Based Advisory & Smart Financing for Rural Micro-Entrepreneurs**

### One-sentence definition

> We are building a multilingual AI-powered business companion for rural
> and semi-urban entrepreneurs that combines hyper-local secondary
> research, entrepreneur-led primary market validation, financial and
> loan planning, evidence-based business recommendations, and continuous
> business-performance insights across the journey from discovering a
> business idea to starting, operating and growing it.

### Core promise

> **Our app helps a first-time rural entrepreneur determine whether
> their business idea is viable and how they should start it. It helps
> them make better financial decisions and assists at every single step
> of their business. The goal is to scale and sustain the business.**

### Core philosophy

The product must not behave like a generic chatbot that produces a
business report from broad Internet knowledge.

Instead:

1.  Understand the entrepreneur.
2.  Understand the locality.
3.  Use secondary research to form initial hypotheses.
4.  Identify what is still unknown.
5.  Help the entrepreneur collect local primary evidence.
6.  Compare and reconcile evidence, including conflicts.
7.  Analyze business feasibility.
8.  Analyze financial eligibility **and** affordability.
9.  Explain recommendations with traceable evidence.
10. Let the entrepreneur make the final decision.
11. Eventually compare predictions with actual business performance and
    continuously improve guidance.

------------------------------------------------------------------------

## 2. Target User

### Primary user

**A first-time rural entrepreneur.**

The product is also intended to support rural and semi-urban
micro-entrepreneurs more broadly, but the UX and complexity should be
optimized around someone who:

-   may be starting their first business;
-   may not have formal business/financial knowledge;
-   may know a business idea but not know how to validate it;
-   may have only partial information about the local market;
-   may prefer a local Indian language and/or voice interaction;
-   may need help understanding financing and government schemes;
-   may have limited access to professional business consultants.

### User starting states

#### State A --- Entrepreneur already has an idea

Example:

> "I want to start a dairy business."

The system must not immediately generate a generic report. It first
needs to understand and narrow the business.

For example, "dairy business" could mean:

-   milk production;
-   milk collection;
-   milk retail;
-   paneer/ghee/other dairy-product production;
-   processing;
-   distribution.

The entrepreneur should confirm the system's understanding before full
validation begins.

#### State B --- Entrepreneur has no fixed idea

The system should:

> **Interview → Research → Generate 3--5 business opportunities →
> Entrepreneur chooses one → Full validation begins**

The AI should recommend multiple plausible opportunities rather than
forcing one "correct" business. The entrepreneur remains the final
decision-maker.

------------------------------------------------------------------------

## 3. Product Lifecycle

The product follows a complete business lifecycle:

> **DISCOVER → VALIDATE → DECIDE → START → OPERATE → ANALYZE → GROW**

The simplified presentation may be shown as:

> **Discover → Validate → Start → Operate & Grow**

The stages are connected rather than isolated.

------------------------------------------------------------------------

## 4. Stage 1 --- DISCOVER

### Objective

Understand the entrepreneur and establish enough context to personalize
the rest of the product.

### First-time onboarding

The first experience should educate the entrepreneur about what the
application can do before asking for extensive information.

The onboarding should establish:

-   preferred language;
-   business type/domain, if known;
-   product/service, if known;
-   location;
-   available capital;
-   relevant personal/business eligibility information;
-   caste/community information where required for government-scheme
    matching, with appropriate privacy and consent handling.

### Location model

Location is a core product input, not a decorative feature.

The intended location information is:

-   village/town;
-   district;
-   state;
-   pincode;
-   exact map/GPS location.

Location enables the system to reason about the entrepreneur's
hyper-local market and retrieve relevant:

-   demographics;
-   census information;
-   registered businesses;
-   competitors;
-   suppliers;
-   market conditions;
-   economic indicators;
-   other locality-specific information.

A 5--10 km research/market area is the current conceptual scope where
appropriate, but the exact radius may vary by business type.

### Early financial access

After onboarding, the entrepreneur should be able to access the
financial area and understand potentially relevant government financing
schemes.

This early access is useful because financial constraints are part of
business discovery, not merely something considered after a business has
been selected.

### AI interview

A deeper AI interview follows the initial onboarding.

The interview should understand:

-   skills and experience;
-   preferences and goals;
-   available resources;
-   risk appetite;
-   desired income;
-   available capital;
-   business interests;
-   constraints;
-   relevant local knowledge.

The result is a structured entrepreneur profile.

------------------------------------------------------------------------

## 5. Business Discovery When No Idea Exists

If the entrepreneur has no fixed business idea:

### Input

-   entrepreneur profile;
-   skills;
-   experience;
-   interests;
-   available capital;
-   available resources;
-   risk appetite;
-   desired income;
-   location;
-   local market/environment.

### Process

1.  Build the entrepreneur profile.
2.  Research the locality.
3.  Identify relevant market opportunities.
4.  Generate and evaluate candidate businesses.
5.  Present **3--5 business opportunities**.
6.  Explain why each may fit.
7.  Let the entrepreneur choose.
8.  Start full validation for the selected opportunity.

The system should not imply certainty. Opportunities are recommendations
to investigate, not guarantees of success.

------------------------------------------------------------------------

## 6. Business Definition When an Idea Exists

Before full validation, the AI must narrow the business idea enough to
make research meaningful.

The AI should clarify the proposed:

-   business model;
-   product/service;
-   target customer;
-   approximate scale;
-   intended market;
-   relevant operational assumptions.

Then it should present:

> **"Here is how I understand your proposed business..."**

The entrepreneur confirms or corrects it.

Only then should full validation begin.

------------------------------------------------------------------------

## 7. Stage 2 --- VALIDATE

### Objective

Determine whether the proposed business makes sense in the
entrepreneur's actual local context.

Validation uses two evidence streams.

### Secondary research

Priority order:

1.  government sources;
2.  trusted/reliable sources;
3.  other relevant online sources.

The MVP's secondary-research mechanism is primarily:

> **Web search + initial government-website data**

Secondary research forms initial hypotheses. It does not automatically
represent ground reality.

### Primary research

Primary research validates what secondary research cannot establish
reliably.

The MVP collection mechanisms are:

1.  **In-app surveys**
2.  **Manual interview/field-data entry**

Google Forms may be considered later, but are not the primary MVP
mechanism.

------------------------------------------------------------------------

## 8. Research Categories

Important research categories include:

-   actual local demand;
-   customer needs and preferences;
-   customer dissatisfaction;
-   purchasing power;
-   market size/reach;
-   competitors;
-   competitor offerings and pricing;
-   competitor gaps;
-   suppliers;
-   raw-material availability;
-   supplier pricing;
-   distribution channels;
-   retailers/distributors;
-   local economic indicators;
-   registered businesses;
-   seasonal factors;
-   business risks;
-   relevant government schemes;
-   required capital;
-   expected business economics.

The research plan should be business-specific rather than one fixed
questionnaire for every entrepreneur.

------------------------------------------------------------------------

## 9. AI-Generated Primary Surveys

The AI should identify information gaps from secondary research and
generate targeted surveys.

### Customer survey

Potentially understand:

-   needs;
-   current alternatives;
-   preferences;
-   acceptable price;
-   dissatisfaction;
-   purchase intent;
-   frequency/volume.

### Competitor research

Understand:

-   offerings;
-   pricing;
-   customer segments;
-   strengths;
-   weaknesses;
-   service gaps;
-   positioning.

### Supplier research

Understand:

-   materials;
-   cost;
-   availability;
-   minimum quantities;
-   delivery;
-   reliability.

### Retailer/distributor research

Understand:

-   willingness to stock/sell;
-   margins;
-   customer demand;
-   distribution feasibility;
-   expected sales channels.

The AI should generate only the questions required to resolve relevant
uncertainties.

------------------------------------------------------------------------

## 10. Entrepreneur as Ground-Truth Collector

### AI

The AI acts as:

-   research planner;
-   researcher;
-   analyst;
-   evidence organizer;
-   recommendation engine;
-   financial reasoning assistant;
-   conversational advisor.

### Entrepreneur

The entrepreneur:

-   provides local context;
-   provides personal/business information;
-   collects local evidence;
-   conducts interviews where appropriate;
-   enters field information;
-   reviews recommendations;
-   makes the final decision.

The entrepreneur is an active participant in the research loop.

------------------------------------------------------------------------

## 11. Evidence Model

Important evidence should be traceable through:

-   source;
-   source type;
-   location;
-   date;
-   finding/metric;
-   limitations;
-   confidence/evidence quality.

The product should make it possible to answer:

> **"Why did the system recommend this?"**

The answer should lead back to the underlying evidence.

------------------------------------------------------------------------

## 12. Evidence Conflict Detection

The product must explicitly detect conflicts between evidence sources.

Example:

**Secondary data:** online/government data suggests high demand.

**Primary local survey:** local respondents indicate low purchase
interest.

The system should not blindly average the figures.

Instead it should explain:

-   what each source says;
-   how recent it is;
-   where it applies;
-   possible reasons for the difference;
-   how the conflict affects confidence;
-   what additional evidence could resolve it.

### Principle

> **Do not hide uncertainty. Make uncertainty actionable.**

------------------------------------------------------------------------

## 13. Survey Quality

Primary data is not automatically correct.

The system should consider:

-   sample size;
-   respondent relevance;
-   geographic coverage;
-   response quality;
-   possible bias;
-   duplicated/low-quality responses;
-   date/recency.

Weak primary data should lower confidence rather than being treated as
ground truth.

------------------------------------------------------------------------

## 14. Business Analysis

The analysis pipeline is:

> **Evidence → Demand → Competition → Market Reach → Pricing →
> Distribution → Risks → SWOT → Business Feasibility**

### Demand analysis

Assess whether the available evidence supports sufficient local demand.

### Competition analysis

Map relevant competitors and analyze:

-   offerings;
-   pricing;
-   customer segments;
-   strengths;
-   weaknesses;
-   gaps.

### Purchasing-power analysis

Estimate whether the target market can realistically afford the
product/service.

### Pricing analysis

Use observed/local evidence to reason about viable pricing rather than
relying only on generic market averages.

### Distribution analysis

Evaluate:

-   where products/services can be sold;
-   supplier availability;
-   retailer/distributor opportunities;
-   logistics constraints.

### Risk analysis

Identify business-specific risks such as:

-   competition;
-   seasonality;
-   supplier dependency;
-   limited capital;
-   weak demand;
-   pricing pressure;
-   regulatory constraints.

------------------------------------------------------------------------

## 15. SWOT Analysis

SWOT means:

-   **Strengths**
-   **Weaknesses**
-   **Opportunities**
-   **Threats**

The SWOT must be derived from evidence.

Example:

**Strengths** - entrepreneur's existing skill; - local raw-material
access.

**Weaknesses** - limited initial capital; - dependence on one supplier.

**Opportunities** - identified customer dissatisfaction; - underserved
local segment.

**Threats** - established competitor; - seasonal demand.

Each important SWOT point should be traceable to underlying evidence.

------------------------------------------------------------------------

## 16. Final Business Recommendation

The product should not reduce the decision to:

> **Business Score: 78/100**

A score may be a summary indicator later, but it cannot replace
reasoning.

The recommendation should contain:

### Recommendation

What the evidence currently suggests.

### Why?

The most important supporting findings.

### Risks

Important risks that could change the outcome.

### Conflicting evidence

Evidence that disagrees or reduces confidence.

### Confidence

A meaningful confidence level based on evidence quality.

### What is still unknown?

Important unresolved information gaps.

### Recommended next action

Concrete actions the entrepreneur should take.

The core format is:

> **Evidence → Interpretation → Recommendation → Action**

------------------------------------------------------------------------

## 17. Financial Intelligence

Financial planning is integrated with business validation.

The system should reason through:

> **Capital → Project Cost → Funding Requirement → Scheme Eligibility →
> Loan Structure → Repayment → Expected Business Economics →
> Affordability → Financial Recommendation**

### Government scheme discovery

The entrepreneur should receive potentially relevant government
financing schemes based on available profile/business information.

Relevant factors may include:

-   entrepreneur profile;
-   business type;
-   location;
-   caste/community information where applicable;
-   project cost;
-   available margin/capital;
-   scheme-specific requirements.

Current government rules must be verified against authoritative sources
at implementation time.

### Eligibility vs affordability

> **Being eligible for a loan does not mean the entrepreneur should
> borrow the maximum amount.**

The system should consider whether expected business cash flow can
support financing.

### Interactive financial model

The entrepreneur should be able to change important assumptions, such
as:

-   available capital;
-   project cost;
-   financing amount;
-   repayment assumptions;
-   expected revenue;
-   operating expenses;
-   other business-economic parameters.

The output should update accordingly.

The exact financial formulas and government scheme rules must be
deterministic rather than invented by an LLM.

------------------------------------------------------------------------

## 18. Executive Summary Output

The final result should feel like a decision dashboard, not a long
report.

Typical structure:

1.  Business under consideration
2.  Overall recommendation
3.  Key findings
4.  Demand
5.  Competition
6.  Pricing
7.  Suppliers/distribution
8.  SWOT
9.  Risks
10. Evidence/conflicts
11. Confidence
12. Financial model
13. Loan/scheme options
14. Affordability
15. What is still unknown
16. Recommended next steps

Users should be able to drill into evidence when they want more detail.

------------------------------------------------------------------------

## 19. Stage 3 --- START

After a business passes the decision stage, the product can help with:

-   investment/resource planning;
-   government financing routing;
-   loan planning;
-   operational setup;
-   marketing;
-   customer education;
-   initial business action plan.

The SIH MVP should focus on planning and financial decision support
rather than attempting to fully automate business setup.

------------------------------------------------------------------------

## 20. Stage 4 --- OPERATE

The long-term product includes a **Digital Business Logbook**.

It should eventually allow entrepreneurs to record:

-   sales;
-   expenses;
-   purchases;
-   other business records.

Voice logging is particularly useful for reducing the friction of
digital bookkeeping.

------------------------------------------------------------------------

## 21. Stage 5 --- ANALYZE

Once actual business data exists, the system can generate:

-   revenue trends;
-   expense trends;
-   profitability analysis;
-   performance vs original plan;
-   detected problems;
-   detected opportunities;
-   recommendations to improve, expand or pivot.

------------------------------------------------------------------------

## 22. Prediction → Reality Loop

A key long-term differentiator is comparing original feasibility
assumptions with actual business performance.

Example:

### Original prediction

-   Expected monthly revenue: ₹60,000
-   Expected expenses: ₹40,000

### Actual performance

-   Revenue: ₹45,000
-   Expenses: ₹42,000

The system can identify:

> **Actual performance is below the original projection.**

It can then investigate possible causes using:

-   current market information;
-   customer information;
-   competition;
-   transaction history;
-   financial position.

It can recommend actions and later measure whether those actions
improved performance.

This closes the loop between:

> **Business planning ↔ real-world performance**

------------------------------------------------------------------------

## 23. Growth & Scalability

The long-term product can help answer:

-   Should I expand?
-   Where should I expand?
-   When should I expand?
-   Can I afford expansion?
-   What should I change first?
-   Is competition becoming too strong?
-   Should I continue, modify or exit?

Growth recommendations can combine:

-   historical business data;
-   current market research;
-   customer information;
-   competition;
-   financial position;
-   available financing.

Possible resulting decisions:

> **Expand / Improve / Maintain / Pivot**

------------------------------------------------------------------------

## 24. Customer Education & Acquisition

The product can eventually help entrepreneurs create:

-   local-language explanations;
-   product demonstrations;
-   workshop plans;
-   pamphlets/posters;
-   WhatsApp communication;
-   FAQs;
-   sales explanations;
-   responses to customer objections.

A workshop is one mechanism, not the definition of the feature.

------------------------------------------------------------------------

## 25. Business Knowledge & Continuous Learning

The long-term product can provide:

-   business podcasts;
-   articles;
-   news;
-   case studies;
-   business tips;
-   educational content.

Content should be available in the entrepreneur's preferred language
where possible.

------------------------------------------------------------------------

## 26. Multilingual & Voice Experience

### AI language

The AI should reply in the entrepreneur's preferred language.

Initial practical targets:

-   Hindi;
-   English;
-   one additional regional Indian language for the demonstration.

### UI localization

Ideally the entire UI should support the entrepreneur's preferred
language.

The exact UX behavior remains open. One possible approach is to ask
during onboarding whether the entrepreneur wants the complete app
localized.

### Voice

Voice should be a first-class accessibility mechanism, especially for:

-   AI interaction;
-   local-language conversation;
-   future business-logbook entry.

------------------------------------------------------------------------

## 27. Core Differentiators / USPs

### 1. Hyper-local market understanding

Researches the entrepreneur's locality rather than giving generic
national-level advice.

### 2. AI + primary local validation

The AI does not assume online data is sufficient. It helps the
entrepreneur collect evidence from the local population.

### 3. Evidence conflict detection

Contradictory primary and secondary evidence is surfaced instead of
blindly merged.

### 4. Traceable recommendations

Recommendations expose supporting evidence, source, date, confidence and
limitations.

### 5. Safer financial planning

The product goes beyond "Are you eligible?" toward "Can this business
realistically afford the financing?"

### 6. Entrepreneur-in-the-loop research

The entrepreneur contributes local ground truth rather than passively
accepting an AI report.

### 7. Prediction-to-reality loop

The long-term product can compare expected business performance with
actual performance.

### 8. Multilingual and voice-friendly

Business guidance can be delivered in a preferred Indian language
through text and voice.

### 9. Full business lifecycle

> **Discover → Validate → Decide → Start → Operate → Analyze → Grow**

------------------------------------------------------------------------

## 28. SIH MVP Scope

The SIH MVP should prove the strongest part of the product rather than
attempt the entire future vision.

### Must prove

**Entrepreneur discovery** - lightweight onboarding; - AI interview; -
entrepreneur profile; - business discovery for users without a fixed
idea.

**Business definition** - idea clarification; - narrowing; -
entrepreneur confirmation.

**Research** - hyper-local secondary research; - government-first source
priority; - targeted research; - customer/competitor/supplier/retailer
research; - primary-data collection; - evidence organization.

**Primary research** - AI-generated in-app surveys; - manual
field/interview entry; - response analysis.

**Evidence intelligence** - primary vs secondary comparison; - conflict
detection; - evidence quality; - traceability.

**Business feasibility** - demand; - competition; - purchasing power; -
pricing; - distribution; - risks; - SWOT; - evidence-based
recommendation.

**Financial intelligence** - project-cost estimation; - government
scheme routing; - loan calculation; - repayment analysis; -
affordability analysis.

**Final output** - executive summary; - evidence; - reasons; - risks; -
confidence; - unknowns; - recommended next steps; - interactive
financial assumptions.

------------------------------------------------------------------------

## 29. Post-MVP Scope

These should influence future architecture but should not consume MVP
development time unless required for the demonstration:

-   digital voice logbook;
-   continuous AI business insights;
-   prediction-vs-reality analysis;
-   growth/expansion analysis;
-   private financing guidance;
-   guided ITR/tax assistance;
-   customer education/acquisition tools;
-   business knowledge hub;
-   broader multilingual knowledge capabilities.

------------------------------------------------------------------------

## 30. Explicit Scope Boundaries

The MVP must **not** become:

-   a generic ChatGPT wrapper;
-   a giant static feasibility-report generator;
-   a fully automated business consultant that hides uncertainty;
-   a replacement for banks/government authorities;
-   a system that fabricates unavailable data;
-   a system that treats every online statistic as local ground truth;
-   a system that recommends maximum borrowing simply because the user
    is eligible;
-   an attempt to fully build every post-MVP feature.

------------------------------------------------------------------------

## 31. Product Principles

### Locality over generic advice

A recommendation should answer whether the opportunity makes sense **for
this entrepreneur in this locality**.

### Evidence over confidence

A confident AI response is not evidence.

### Primary research as validation

Secondary research creates hypotheses; primary research tests them
against local reality.

### Uncertainty is a feature

Missing or conflicting evidence should reduce confidence and trigger
additional validation.

### Entrepreneur remains in control

The system recommends. The entrepreneur decides.

### Eligibility ≠ affordability

The largest available loan is not necessarily the safest loan.

### Active participation

The entrepreneur is part of the research process.

### Lifecycle continuity

Planning, finance, operations and growth should eventually share the
same business context.

### Simple interaction, complex intelligence

Technical complexity should remain behind the interface.

### Build around the differentiator

The MVP should prove hyper-local, evidence-based decision support rather
than maximize feature count.

------------------------------------------------------------------------

## 32. Product Success Criteria

The MVP is successful if a first-time rural entrepreneur can go from:

> **"I have an idea / I don't know what business to start"**

to:

> **"I understand my local opportunity, I know what evidence supports or
> challenges it, I understand the financial implications, and I know
> what I should do next."**

A strong SIH demonstration should visibly prove:

> **Entrepreneur context → Local research → Primary evidence →
> Conflict-aware analysis → Feasibility → Financial affordability →
> Explainable recommendation → Next action**

------------------------------------------------------------------------

## 33. Product Decision Rules for AI Coding Agents

Any AI coding agent working on this repository must follow these rules:

1.  Do not invent product requirements.
2.  Do not add major features because they "seem useful" without
    documenting the decision.
3.  Do not replace evidence-backed product behavior with generic chatbot
    behavior.
4.  Do not make LLM output the source of truth for deterministic
    financial calculations.
5.  Do not hide missing or conflicting evidence.
6.  Do not remove traceability from important recommendations.
7.  Do not assume the entrepreneur wants the maximum loan.
8.  Do not treat post-MVP functionality as MVP unless explicitly
    approved.
9.  When a requirement is ambiguous, consult the relevant project
    documentation before implementing.
10. When a product decision changes, update `docs/decisions.md`.

------------------------------------------------------------------------

## 34. Open Product Decisions

These remain intentionally unresolved:

1.  Exact mandatory vs optional onboarding fields.
2.  Exact caste/community fields, consent and privacy UX.
3.  Exact business-definition confirmation UX.
4.  How users branch/restart after receiving 3--5 business
    opportunities.
5.  Exact geographic radius logic by business type.
6.  Which government data sources are programmatically accessible for
    the MVP.
7.  Exact evidence-ranking/confidence methodology.
8.  How survey respondents are recruited and authenticated.
9.  Whether/which respondent incentives are used.
10. Exact deterministic financial formulas.
11. Exact government-scheme rule representation and update process.
12. Exact backend/database/authentication/hosting choices.
13. Exact SIH demonstration language set.
14. Exact fallback behavior when a preferred language is unsupported.
15. Exact evidence retention/provenance policy.
16. Minimum automated tests and evaluation cases for the SIH demo.

------------------------------------------------------------------------

## 35. Boundaries of This Document

This document intentionally does **not** define:

-   Flutter folder structure;
-   database tables;
-   API request/response schemas;
-   exact AI prompts;
-   backend implementation;
-   security architecture;
-   testing implementation;
-   deployment configuration.

Those belong in:

-   `docs/architecture.md`
-   `docs/database.md`
-   `docs/api-contracts.md`
-   `docs/ai-behaviour.md`
-   `docs/ux.md`
-   `docs/security.md`
-   `docs/testing.md`
-   `docs/decisions.md`

The separation is intentional:

> **Product behavior comes first; implementation follows the product
> definition.**

------------------------------------------------------------------------

## Final Product Statement

> **We are building a multilingual AI-powered business companion for
> rural and semi-urban entrepreneurs that uses hyper-local research and
> entrepreneur-collected primary evidence to validate business
> opportunities, combines that evidence with financial and loan
> affordability analysis, explains its recommendations transparently,
> and eventually learns from the entrepreneur's real business
> performance to help them improve, sustain and grow.**
