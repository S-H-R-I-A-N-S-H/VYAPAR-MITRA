# Vyapar Mitra — Vision & Product Bible

> **This is the canonical reference document for all product, technical, and design decisions in Vyapar Mitra.**
> Every feature, architecture choice, and UX decision must be evaluated against this document.

---

## 1. Problem Analysis

India has a large and economically important base of small and unincorporated businesses. The Annual Survey of Unincorporated Sector Enterprises 2025 estimated **7.92 crore** unincorporated non-agricultural establishments employing approximately **12.81 crore workers**. The sector's Gross Value Added increased by 10.87 percent, while the share of establishments using the internet increased from 26.7 percent to 39.4 percent. These figures show both the scale of India's grassroots business ecosystem and the growing opportunity for digital support.

The challenge faced by a first-time rural or semi-urban entrepreneur is not simply the absence of capital or government schemes. The larger problem is the **absence of accessible, localized, and understandable decision support before and after starting a business**.

An entrepreneur may know that they want to start a dairy unit, retail shop, food business, tailoring unit, repair service or another local enterprise, but may not know:
- Whether that business is suitable for their locality
- How many similar businesses operate nearby
- What competitors charge
- Where suppliers are located
- What customer segments are underserved
- What risks may affect the business
- How much capital is required
- How much financing is appropriate
- Whether expected cash flow can support repayment

### 1.1 Gap in Existing Government Platforms

India already has several useful government platforms, but they solve specific parts of this problem rather than providing one continuous business decision workflow:

| Platform | Purpose | Gap |
|---|---|---|
| **myScheme** | Scheme discovery and eligibility | Not a complete localized business feasibility workflow |
| **JanSamarth** | Credit-linked scheme discovery | No market validation, DPR generation, or post-launch monitoring |
| **CHAMPIONS** | Grievance resolution and advisory | Not a continuous workflow connecting discovery → validation → DPR → monitoring |
| **Udyam Registration** | Digital enterprise registration | Does not validate local suitability or provide continuous assistance |

The NITI Aayog report on convergence of schemes identifies that MSME-related information and services are distributed across MyMSME, NSWS, myScheme, and Udyam Registration — **the entrepreneur still has to connect these pieces themselves.**

### 1.2 The Decision-Making Gap

A first-time entrepreneur may have to separately:
1. Find a business idea
2. Research the local market
3. Identify competitors
4. Find suppliers
5. Collect local customer feedback
6. Understand government information
7. Estimate project cost
8. Calculate financing requirements
9. Understand repayment
10. Identify applicable schemes
11. Prepare a business plan and Detailed Project Report
12. Start the business
13. Maintain records
14. Determine what to do when actual performance differs from expectations

This creates a **major decision-making gap** for users who may have limited access to professional business consulting.

**PS 26091** specifically calls for a hyper-local AI Business Advisory Assistant and Smart Financial Calculator that can guide beneficiaries through business feasibility and financial structuring.

---

## 2. Proposed Solution and Innovation

**Vyapar Mitra** is a multilingual, voice-first business companion designed to help a first-time rural or semi-urban entrepreneur move from understanding their situation to discovering, validating, financing, starting, operating, and growing a business.

### Core Innovation

The core innovation is **not** simply adding AI to an existing business portal. Vyapar Mitra connects four forms of information normally handled separately:

1. The entrepreneur's circumstances and capabilities
2. Online web research
3. Local market evidence
4. Deterministic financial and scheme rules

### The Complete Entrepreneur Journey

```
Understand → Discover → Validate → Finance → Plan → Start → Record → Identify → Discuss → Improve → Learn → Comply → Grow
```

---

## 2.1 Understanding the Entrepreneur

The journey starts with an **AI-assisted interview** (text or voice) in the entrepreneur's preferred language.

**Information collected:**
- Preferred language
- Location
- Available capital
- Occupation and business experience
- Skills, education, or vocational background
- Interests and preferred business type
- Products or services of interest
- Available resources (land, workspace, assets, family support)
- Preferred operating scale
- Whether starting or expanding a business
- Target customers and practical constraints
- Understanding of the proposed business

**For scheme assistance, additionally:**
- Age, gender, income
- Residence, social category or caste
- Disability status, minority status
- Employment status and other scheme-specific attributes

> Only information required for the relevant workflow is requested. The interview is adaptive — it does not repeatedly ask questions already answered.

---

## 2.2 When the Entrepreneur Does Not Have a Business Idea

Vyapar Mitra combines the entrepreneur's profile with location-based research to identify **3 to 5 potential opportunities** (not random AI suggestions).

Each opportunity is presented with:
- Supporting evidence
- Risks and uncertainties
- Information gaps

The entrepreneur selects an opportunity for deeper validation.

---

## 2.3 When the Entrepreneur Already Has a Business Idea

Vyapar Mitra **clarifies and narrows** broad ideas:

- "I want to start a food business" → home-based snack business / takeaway outlet / tiffin service / packaged food / catering
- "I want to open a clothing shop" → refined by product category, target customer, price segment, location, operating model

Goal: Convert a broad idea into a **clearly defined business proposition** that can be researched and validated.

---

## 2.4 Hyper-Local Business Research

After opportunity selection, Vyapar Mitra performs **structured live web research** around the entrepreneur's location:

- Population and demographic characteristics
- Rural/urban classification, official socioeconomic indicators
- Existing businesses or establishments
- Industry information
- Supplier and sourcing information
- Wholesale and retail price references
- Transport, distance, and fuel/transportation inputs
- Government datasets and reports relevant to the business category
- Government scheme and policy information

> **Important:** Online research is NOT treated as direct village-level demand data. It establishes population, demographics, regional activity, and pricing references. Local demand requires primary validation.

---

## 2.5 Government and Official Information Sources

| Source | Purpose |
|---|---|
| Open Government Data Platform India | Government datasets |
| Census / Official demographic data | Population data |
| MoSPI | Enterprise and socioeconomic statistics |
| Ministry of Social Justice and Empowerment | Applicable schemes |
| NSCFDC | Where applicable |
| NABARD | Rural development and enterprise context |
| Reserve Bank of India | Financial and credit context |
| JanSamarth | Credit-linked scheme information |
| myScheme | Scheme discovery and eligibility |
| MoMSME / MyMSME / CHAMPIONS | MSME resources |
| PM Vishwakarma | Eligible artisan activities |

> Official sources are the reference for scheme and policy rules. Source and update information is maintained so outdated rules are not silently presented as current.

---

## 2.6 Mappls and Location Intelligence

Mappls provides the geographic layer:
- Location identification and geocoding
- Nearby place and business discovery
- Distance calculations and route estimation
- Transport-related cost calculations

> Geographic feasibility cannot be determined from a district name alone. A supplier 5 km away vs 60 km away creates very different sourcing and distribution costs. Map-based information becomes an input into competitor analysis, supplier analysis, and financial calculations.

---

## 2.7 Primary Research Through the Entrepreneur's Local Network

Secondary research cannot answer every question about a specific local market. Vyapar Mitra adds a **primary research layer**.

- The entrepreneur provides ground-level information via their existing local network
- Vyapar Mitra generates and structures **AI-generated surveys** based on information gaps identified during secondary research
- Survey targets: consumers, competitors, suppliers, retailers/distributors
- Collection methods: voice conversation, online forms, direct structured entry, or filling known gaps

---

## 2.8 Handling Incomplete Primary Data

The system identifies:
- Missing responses
- Contradictory responses
- Approximate values
- Unusual responses
- Low response counts
- Information requiring further validation

An **information gap list** is created and presented transparently. The entrepreneur can continue with current data or request additional questions / targeted follow-up research.

---

## 2.9 Evidence Conflict Detection and Resolution

Primary evidence (local) and secondary evidence (online) are compared — not simply combined.

| Scenario | System Response |
|---|---|
| Secondary shows demand, local surveys show weak demand | Identify conflict, investigate causes, request targeted follow-up |
| Secondary shows weak demand, local surveys show strong demand | Do not auto-reject; request additional responses to strengthen finding |

**Conflicts are surfaced, not hidden.** If the entrepreneur wants to proceed with unresolved conflicts, the system proceeds while noting the conflict in the final report. These steps are optional.

---

## 2.10 Feasibility and SWOT Analysis

After research and evidence comparison:

- **Strengths:** Existing skills, available resources, identified customer segment
- **Weaknesses:** Limited capital, supplier dependence, lack of experience
- **Opportunities:** Underserved segment, market gap
- **Threats:** Established competitors, seasonal demand, supply risks, transportation costs

All conclusions are connected to their **supporting evidence, limitations, and information gaps** — not generic AI paragraphs.

---

## 2.11 Financial Structuring

Financial structuring uses **deterministic backend calculations** (not AI).

```
Market findings → Expected sales → Revenue → Operating costs → Financing requirement → Repayment → Cash flow
```

**Key questions answered:**
- Am I eligible under the defined conditions?
- How much financing do I actually need?
- How much can I reasonably repay?
- Over what tenure?

**PS 26091 Financing Structure (example):**
- 10% beneficiary contribution + 90% financing
- If entrepreneur has ₹1,00,000 margin → theoretical project cost = ₹10,00,000, financing = ₹9,00,000 (subject to scheme limits and actual approval)

Vyapar Mitra also compares required financing with **projected business cash flow** so the entrepreneur understands whether borrowing is financially manageable.

---

## 2.12 Government Scheme Assistance — The Scheme Engine

Scheme assistance uses a **structured rule-based eligibility engine** (the Scheme Engine).

### Financing Rules (from PS 26091)

| Scheme | Project Cost | Max Financing | Interest Rate | Repayment Period |
|---|---|---|---|---|
| Micro Finance Scheme | Up to ₹1.40 lakh | 90% (max ₹1.25 lakh) | 6.5% beneficiary | 3 years (3-month moratorium) |
| Term Loan Scheme | ₹1.40 lakh – ₹50 lakh | 90% (max ₹45 lakh) | 8% beneficiary | 7 years (6-month moratorium) |

> The system reports whether available information satisfies defined conditions. **It does not promise loan sanction** — final approval remains with the relevant financial institution or authority. Scheme rules are stored in the database so they can be updated when official conditions change.

---

## 2.13 Repayment Affordability

Eligibility and affordability are **separate questions**.

The system calculates proposed repayment and compares it with projected business cash flow:

```
Expected monthly sales - Operating costs = Cash available for repayment
vs.
Proposed monthly repayment obligation
```

If repayment places significant pressure on projected cash flow, the system surfaces this clearly and allows the entrepreneur to evaluate alternatives (e.g., reduce project scale, reconsider financing amount).

---

## 2.14 Detailed Project Report (DPR) Generation

The DPR consolidates:
- Entrepreneur profile and business concept
- Market research (competitor, supplier)
- Primary and secondary research
- Evidence conflicts
- SWOT analysis
- Project cost, contribution, funding requirement
- Revenue assumptions and operating costs
- Repayment information
- Relevant scheme information
- Risks and mitigation measures

One structured document instead of disconnected AI responses.

---

## 2.15 Digital Logbook and Voice-Enabled Financial Ledger

**Offline-first digital business logbook** with voice-enabled logging.

**Example voice input:**
> "Today I sold 25 packets at 40 rupees each and spent 500 rupees on raw material."

**Structured output:**
- Sales quantity: 25
- Selling price: ₹40
- Sales value: ₹1,000
- Raw material expense: ₹500

**Voice actions:** Record sales, add expenses, record customer feedback, update business observations, create follow-up items.

The logbook becomes structured real business data, later compared with the original business plan.

---

## 2.16 Continuous AI Insights

The system compares logbook records with planned assumptions and historical performance.

**Example — sales deviation:**
- Plan expected 40 units/day; actual consistently at ~25 units/day
- System asks: "Have customer visits decreased? Has a competitor changed pricing? Have your prices changed? Do you notice another reason?"
- Entrepreneur responds with context (e.g., new competitor selling ₹5 cheaper)
- System combines sales trend + entrepreneur explanation to suggest possible actions

**The continuous loop:**
```
Record → Detect → Discuss → Understand → Act → Observe → Improve
```

> Business growth and ongoing assistance are **part of the MVP**, not a post-MVP feature.

---

## 2.17 Multilingual and Voice-First Interaction

Voice is integrated **across the product**, not limited to a chatbot:
- Initial interview
- Business opportunity discussion
- Primary survey collection
- Daily logbook entries
- Business issue discussions
- Follow-up questions and business insights

**Bhashini** provides supported Indian language speech and language capabilities. The entrepreneur can communicate in a familiar language without extensive English typing.

---

## 2.18 Offline-First Operation

The digital logbook follows an **offline-first approach**:
- When offline: entries stored locally
- When connectivity returns: pending records synchronised with backend

Daily business recording continues even where network availability is inconsistent.

---

## 2.19 Core Innovation Summary

| Layer | Role |
|---|---|
| Secondary research | Establishes what can be learned from available sources |
| Primary research | Provides local ground-level evidence |
| Evidence comparison | Identifies agreement, uncertainty, and conflict |
| Deterministic financial logic | Calculates financing and repayment implications |
| Scheme rules | Identifies defined eligibility conditions |
| DPR | Consolidates planning |
| Digital logbook | Records what actually happens after launch |
| Continuous AI assistance | Compares actuals to plan, discusses deviations, suggests actions |

**Vyapar Mitra is a continuous business decision support system, not a one-time AI recommendation tool.**

---

## 3. Technical Implementation

### Guiding Architecture Principle

> **AI explains and interprets. Deterministic software calculates and applies defined rules. External services provide specialised capabilities. Structured storage maintains the entrepreneur's business history.**

### 3.1 Technology Stack

| Component | Technology |
|---|---|
| Mobile Application | Flutter |
| Backend API | FastAPI (Python) |
| Authentication & DB Services | Supabase |
| Database | PostgreSQL (via Supabase) |
| AI / LLM | Google Gemini API |
| Speech & Language | Bhashini API |
| Location & Mapping | Mappls API |
| Conversational AI (Flutter) | Flutter AI Toolkit |
| Background Tasks | Celery |
| Task Queue | Redis |
| PDF Generation | ReportLab |
| Containerisation | Docker |
| CI/CD | GitHub Actions |

---

### 3.2 System Architecture — Seven Layers

1. **Flutter Application** — Onboarding, AI interview, opportunity discovery, research results, financial calculator, scheme assistance, DPR access, digital logbook, continuous insights
2. **FastAPI Backend** — Receives authenticated requests, coordinates services
3. **Supabase / PostgreSQL** — Stores all structured business data
4. **Research Engine** — Retrieves and structures information from defined sources
5. **Deterministic Financial & Scheme Engine** — Performs calculations, applies structured eligibility rules
6. **AI Layer (Gemini)** — Natural language understanding, interview flow, survey generation, summarisation, contextual discussions
7. **External Services** — Bhashini, Mappls, government information sources

---

### 3.3 End-to-End Data Flow

```
Entrepreneur profile + location + capital + preferences
    ↓
AI interview (text or voice)
    ↓
Structured entrepreneur profile
    ↓
Opportunity generation (if no idea) OR idea clarification
    ↓
Research engine: secondary research (Mappls + government sources)
    ↓
Information gap identification → primary survey generation
    ↓
Entrepreneur collects responses (voice / form / direct entry)
    ↓
Response validation + primary/secondary evidence comparison
    ↓
Conflict detection + feasibility assessment + SWOT
    ↓
Deterministic financial engine: project cost, financing, repayment, cash flow
    ↓
Scheme engine: eligibility check
    ↓
DPR generation
    ↓
[Business starts]
    ↓
Digital logbook entries (voice or text, offline-first)
    ↓
Deviation detection → AI-driven follow-up discussion → action suggestions
```

---

### 3.4 Research Engine

- Input: location, business category, research objectives, entrepreneur constraints
- Output: source information, extracted facts, evidence gaps, opportunities, risks, validation questions
- AI layer explains findings to entrepreneur
- **Separation prevents unsupported AI statements from being treated as verified research**

---

### 3.5 Evidence Structure

Each finding can be represented with:

```
- Claim
- Source
- Source date
- Geographic relevance
- Evidence type (primary / secondary)
- Supporting information
- Contradictory information
- Confidence level
- Information gap
- Recommended validation action
```

---

### 3.6 Financial Engine

Backend software logic calculates:
- Project cost and entrepreneur contribution
- Financing requirement
- Interest, repayment period, installment amount
- Projected revenue and operating expenses
- Cash available and repayment burden
- Scenario comparisons

**The AI model does not determine numerical results.** Same input always produces the same output. Calculations can be tested independently.

---

### 3.7 Scheme Rule Engine

Each scheme rule record contains:
```
- Scheme name
- Eligible project range
- Maximum financing
- Margin requirement
- Interest rate
- Repayment period
- Beneficiary conditions
- Required attributes
- Required documents
- Official source
- Effective date
- Last update date
```

---

### 3.8 AI Layer (Gemini)

**Used for:**
- Understanding natural language business descriptions
- Extracting information from entrepreneur responses
- Generating follow-up interview questions
- Creating surveys based on information gaps
- Summarising research and explaining financial results in simple language
- Discussing business performance changes
- Generating questions to understand possible causes

**NOT used for:**
- Critical financial calculations
- Defined scheme rules

**Architecture: "AI explains, deterministic code decides."**

---

### 3.9 Bhashini Integration

```
Entrepreneur speech → Bhashini → Text → Backend → Structured response → Bhashini → Audio/Text → Entrepreneur
```

---

### 3.10 Mappls Integration

Capabilities used:
- Location identification and geocoding
- Distance calculation
- Nearby place/business discovery
- Route estimation
- Supplier and competitor location analysis

---

### 3.11 Database Entities (PostgreSQL via Supabase)

| Entity | Description |
|---|---|
| Users | Authentication and identity |
| Entrepreneur profiles | Skills, capital, background, attributes |
| Businesses | Business definitions and status |
| Locations | Geographic data |
| Research projects | Research sessions |
| Sources | Evidence sources with metadata |
| Research findings | Structured evidence records |
| Survey templates | AI-generated survey structures |
| Survey responses | Collected primary data |
| Financial models | Deterministic calculation inputs/outputs |
| Scheme rules | Structured eligibility rules with source/date |
| DPRs | Generated project reports |
| Ledger entries | Daily logbook records |
| Business insights | AI-detected deviations and observations |
| Business issues | Identified problems |
| Suggested actions | Recommended next steps |
| Action outcomes | Tracked results |

---

### 3.12 Offline Data Synchronisation

```
Local record → Sync queue → FastAPI → Validation → PostgreSQL
```

The sync layer handles: failed uploads, duplicate submissions, and pending records.

---

### 3.13 Security and Privacy

- **Minimum data collection** — only information required for the selected workflow
- Authentication via Supabase (JWT)
- Role-based database permissions
- Voice processing requires explicit user consent
- Research information and entrepreneur-supplied information stored as separate evidence types
- Financial calculations retain input information and rule source for auditability
- **System does not present scheme eligibility as a guarantee of government or lender approval**

---

### 3.14 Mobile Interface Design Principles

The interface focuses on **decisions, not technical functions**:

- "What should I do next?"
- "What did the system find?"
- "What does it mean for my business?"
- "What information is missing?"
- "What decision do I need to make?"

**Design requirements:** Large readable elements, minimal typing, voice interaction, local language support, simple financial explanations, source labels, clear action prompts. Technical complexity stays inside the system.

---

### 3.15 Scalability Path

| Stage | Scope |
|---|---|
| Initial | Selected locations and business categories |
| Next | More districts, business categories, survey templates |
| State-level | State-specific scheme rules, additional languages |
| National | Broader regional data, more schemes, larger research infrastructure |

Modular separation of application, research engine, financial engine, scheme engine, AI layer, and data sources allows independent expansion.

---

## 4. Feasibility and Impact

### 4.1 36-Hour Hackathon Development Plan

| Hours | Milestone |
|---|---|
| 0–4 | Flutter structure, FastAPI backend, Supabase config, DB schema, financial rules |
| 4–8 | Entrepreneur onboarding, location, capital, business category, initial AI interview |
| 8–12 | Text and voice interaction, Bhashini integration, profile extraction |
| 12–16 | Opportunity discovery, idea clarification, Mappls integration, initial research workflow |
| 16–20 | Primary survey generation, response collection, evidence comparison, conflict detection |
| 20–24 | Deterministic financial engine, project cost, financing, repayment, scheme routing |
| 24–28 | DPR generation, digital logbook, voice-enabled entries |
| 28–32 | Continuous AI insights, deviation detection, follow-up questions, action tracking |
| 32–36 | End-to-end integration, offline testing, financial calculation testing, demo prep |

---

### 4.2 Key Implementation Challenges

| Challenge | Mitigation |
|---|---|
| Incomplete hyper-local data | Secondary research for digital info + targeted primary surveys for local info |
| Inconsistent primary data | Retain responses, identify disagreement, request additional validation |
| Online vs. local evidence conflict | Identify conflict direction, determine what additional evidence is needed |
| AI hallucination | Source-grounded research, structured evidence, separation of AI and deterministic logic |
| Changing scheme rules | Scheme rules stored as structured data with source and update information |
| Poor connectivity | Offline-first logbook with sync on reconnection |
| Language and literacy barriers | Voice-enabled multilingual interaction |
| User adoption | Guided interviews, simple language, progressive disclosure, action-oriented outputs |

---

### 4.3 Impact Metrics

- Number of entrepreneurs completing onboarding
- % of users receiving evidence-backed business opportunities
- Number of primary survey responses collected
- % of findings with identifiable sources
- Number of evidence conflicts identified
- % of critical financial calculations generated through deterministic logic
- Time to produce feasibility assessment and DPR
- Number of voice-enabled logbook entries
- Number of meaningful business deviations detected
- Number of entrepreneur follow-up discussions initiated
- Number of suggested actions tracked
- % of offline records successfully synchronised
- Completion rate of business planning workflow

---

### 4.4 Financial Value

**Most important financial value:** Improved decision-making **before** capital is committed.

(World Bank India Micro Firms Survey: own funds were the main source for 73.8% of surveyed micro firms — illustrating why better planning matters when entrepreneurs commit their own limited capital.)

**Financial decision process:**
```
Available capital → Project cost → Financing requirement → Expected revenue → Operating cost → Available cash → Repayment → Financial manageability
```

---

### 4.5 Relationship With Existing Government Platforms

Vyapar Mitra is **not a replacement** for existing government platforms. It acts as a **decision support layer**:

```
Vyapar Mitra → Business feasibility → Financial structure → Scheme conditions → DPR → Relevant government/financial portal (JanSamarth, myScheme, Udyam, etc.)
```

---

## 5. Post-MVP Roadmap

### Phase 1 — MVP (Covered)

- Entrepreneur understanding
- Business opportunity discovery
- Existing idea clarification
- Hyper-local research (secondary)
- Primary research with surveys
- Evidence conflict detection
- Feasibility assessment and SWOT
- Financial structuring
- Scheme assistance
- DPR generation
- Multilingual voice interaction
- Voice-enabled digital logbook
- Continuous AI insights
- Entrepreneur-guided problem analysis
- Action suggestions and improvement tracking

### Phase 2 — Post-MVP

1. **Business-Specific Knowledge Layer** — Organised YouTube/podcast transcripts, articles, research papers, government guidance; summarised in preferred language with next actionable steps
2. **Specialised Tax and Compliance Assistance** — GST assistance, ITR guidance, presumptive taxation support, annual business summaries from accumulated records

---

## 6. Long-Term Vision

**Complete entrepreneur lifecycle:**

```
Understand → Discover → Validate → Finance → Plan → Start → Record → Identify → Discuss → Improve → Learn → Comply → Scale → Grow
```

| Layer | Role |
|---|---|
| **AI** | Language understanding, research assistance, explanations, continuous interaction |
| **Deterministic software** | Financial calculations, rule-based decisions |
| **Government sources** | Official scheme and policy information |
| **Primary research** | Local ground-level evidence |
| **Entrepreneur** | Final context and final business decisions |

> **Vyapar Mitra goes beyond being a loan calculator, scheme finder, or generic AI chatbot. It connects local market evidence, financial reasoning, government scheme information, and continuous business records into one system that helps a first-time entrepreneur make informed decisions before starting a business and continue improving it after the business begins operating.**

---

*Last updated: September 2026*
*Document version: 1.0*
*Status: Canonical — all product decisions must reference this document*
