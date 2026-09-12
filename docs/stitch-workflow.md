# Stitch Workflow — VYAPAR MITRA

## Purpose

This document defines how the VYAPAR MITRA team should use Google Stitch for UI/UX exploration and screen prototyping before implementing the approved design in Flutter.

**Core rule:** Stitch is a design/prototyping tool. It must not become the source of truth for product logic, business rules, evidence standards, financial calculations, API contracts, security, or database structure.

The source of truth remains the project documentation:

- `product.md` — product behaviour, user journeys, scope and business rules
- `architecture.md` — system architecture and technology boundaries
- `database.md` — data model and persistence rules
- `api-contracts.md` — Flutter ↔ backend contracts
- `ai-behaviour.md` — AI behaviour, evidence and recommendation rules
- `ux.md` — UX principles, flows and interaction rules
- `security.md` — security and privacy constraints
- `testing.md` — testing and acceptance criteria
- `development.md` — implementation workflow

---

# 1. What Stitch Should Do

Use Stitch to:

1. Explore visual directions quickly.
2. Generate initial screen layouts.
3. Establish a consistent visual language.
4. Prototype important user journeys.
5. Iterate on individual screens.
6. Produce visual references for Flutter implementation.
7. Validate the overall experience before spending implementation effort.

Do **not** use Stitch to decide:

- What data the application stores.
- Which financial formula is correct.
- Whether a government scheme is actually eligible.
- What an AI recommendation means.
- Which evidence is trustworthy.
- What the API contract should be.
- Authentication or authorization behaviour.
- Database relationships.
- Security policy.

Those decisions belong in the project specifications and implementation.

---

# 2. Source-Derived Stitch Prompting Rules

The Google AI Developers Forum's Stitch Prompt Guide recommends a high-level-to-detailed workflow:

### Start high-level

For a complex application, begin with the overall product concept and visual direction. Then move to individual screens and components.

### Be clear and specific

Describe:

- the purpose of the screen,
- the important UI elements,
- the desired layout,
- the interaction,
- the visual tone,
- and the relevant UX requirements.

### Use UI/UX vocabulary

Instead of vague instructions such as:

> "Make it better."

Use concrete references such as:

> "Use a compact top app bar, a prominent primary action, grouped cards, clear section headings, and a bottom navigation bar."

### Use visual adjectives deliberately

Words describing the intended atmosphere can influence the generated visual language.

For this product, useful directions include:

- trustworthy
- welcoming
- simple
- calm
- local
- modern
- professional
- approachable
- low-cognitive-load
- mobile-first

Avoid making every screen visually dramatic. The product should feel trustworthy rather than flashy.

### Make one major change at a time

A key lesson from the Stitch discussion is that combining many unrelated changes in one prompt can cause an existing layout to be recreated or broken.

Prefer:

1. create the structure;
2. refine the hierarchy;
3. add one component;
4. adjust spacing;
5. adjust typography;
6. refine imagery;
7. polish interaction states.

### Keep prompts focused

Use one screen/component and one or two meaningful adjustments per iteration where possible.

Do not repeatedly send a giant prompt containing the entire application when you only want to change one screen.

### Save good states

When a screen reaches an approved state, capture/export it before continuing.

Treat approved screens as visual checkpoints.

---

# 3. Project-Specific Stitch Strategy

Our workflow should be:

```text
Project Docs
    ↓
UX/User Journey
    ↓
Stitch Visual Direction
    ↓
Core Screen
    ↓
Lock Visual Language
    ↓
Next Screen
    ↓
Focused Refinement
    ↓
Approved Screens
    ↓
Flutter Implementation
    ↓
Real Device Testing
```

The critical distinction is:

```text
Product specification → what the product does
UX specification      → how the experience should work
Stitch                 → how it can look
Flutter                → how it actually behaves
```

---

# 4. Before Opening Stitch

Do not start by asking Stitch to design the entire product in one enormous prompt.

First extract from `product.md` and `ux.md`:

- primary user;
- current user journey;
- purpose of the screen;
- required information;
- primary action;
- secondary actions;
- important states;
- language requirements;
- location context;
- evidence/trust requirements;
- financial safety requirements;
- accessibility requirements.

Then decide what the screen must communicate.

Example:

```text
Screen:
Business Validation Summary

User goal:
Understand whether the selected business idea appears viable.

Primary action:
Continue to recommendation/action plan.

Important content:
Executive summary
Evidence-backed findings
SWOT
Unknowns/conflicts
Financial snapshot
Recommended next steps

Trust requirement:
Recommendations must show why they were made and what evidence supports them.
```

Only after this should you write the Stitch prompt.

---

# 5. Global Visual Foundation

Start Stitch with a high-level prompt establishing the application's identity.

### Master visual prompt

```text
Design a mobile-first multilingual AI business companion for first-time rural and semi-urban entrepreneurs in India.

The product should feel trustworthy, welcoming, simple, calm, modern and professional without feeling corporate or intimidating.

The primary users may have limited digital experience, so use clear hierarchy, readable typography, generous touch targets, simple navigation, progressive disclosure and plain-language labels.

The application helps entrepreneurs discover business opportunities, validate an idea using local market evidence, understand government schemes and loans, plan finances, and receive evidence-based recommendations.

Use a clean mobile-first layout with cards, clear section headings, concise supporting text and strong primary actions.

The visual system should be consistent across all screens. Prioritize accessibility, readability, trust and low cognitive load over decorative complexity.

Design for Flutter mobile implementation rather than a desktop website.
```

Use this to establish the direction. Then move screen-by-screen.

---

# 6. Lock the Design Language

Once a strong screen/theme exists, preserve it.

The Stitch discussion specifically recommends using a design document such as `DESIGN.md` to maintain consistency, including exact:

- colours,
- fonts,
- radius,
- spacing,
- and other theme decisions.

For this project, the eventual design system should also record:

```text
Typography
Colour tokens
Spacing scale
Corner radius
Elevation
Button styles
Input styles
Card styles
Navigation
Iconography
Charts
Status indicators
Evidence/confidence indicators
Warning/error states
Loading states
Empty states
Voice controls
Language selector
```

If Stitch generates a particularly good screen, use it as a **reference screen** for later screens.

When creating a new screen, explicitly tell Stitch to preserve the reference screen's:

- header;
- logo/branding;
- typography;
- spacing;
- card treatment;
- navigation;
- button style;
- visual hierarchy.

---

# 7. Screen-by-Screen Workflow

For every important screen:

## Step 1 — Define the screen

Write a short screen specification.

```text
Screen:
[Name]

Purpose:
[What the user needs to accomplish]

Primary action:
[Main action]

Required content:
[List]

Important states:
[List]

UX constraints:
[List]

Trust/safety requirements:
[List]
```

## Step 2 — Generate the first version

Ask Stitch to create the layout without trying to perfect every detail.

## Step 3 — Inspect

Check:

- Is the hierarchy obvious?
- Can a first-time entrepreneur understand it?
- Is the primary action obvious?
- Is there too much information?
- Are important facts visually distinguishable from recommendations?
- Is the screen actually mobile-friendly?
- Are touch targets comfortable?
- Does it match the established visual language?

## Step 4 — Change one thing

Examples:

```text
Keep the existing layout. Improve only the information hierarchy so the primary action is visually dominant.
```

```text
Keep the existing layout and styling. Reduce visual density in the evidence section by grouping secondary details into expandable cards.
```

```text
Keep everything else unchanged. Improve the spacing between the financial summary cards.
```

## Step 5 — Save the approved state

Record the screenshot/design reference.

## Step 6 — Move to the next screen

Use the approved screen as a reference.

---

# 8. Recommended Screen Order

Do not design screens randomly. Follow the user's journey.

### Phase A — Entry and onboarding

1. Welcome
2. Language selection
3. Entrepreneur profile
4. Location
5. Financial/basic eligibility information

### Phase B — Discovery

6. AI interview
7. Interview progress
8. Business opportunities
9. Opportunity comparison
10. Business idea confirmation

### Phase C — Validation

11. Validation/research dashboard
12. Research progress
13. Market findings
14. Evidence detail
15. Primary survey
16. Survey response/results
17. Conflict/uncertainty state

### Phase D — Decision support

18. Business validation summary
19. SWOT
20. Financial scenario
21. Government scheme/loan matching
22. Recommendation
23. Action plan

### Phase E — Future product

24. Business workspace
25. Operations/logbook
26. Performance dashboard
27. Prediction vs reality
28. Growth recommendations

For the VYAPAR MITRA prioritize the smallest coherent journey rather than trying to prototype every future screen.

---

# 9. Prompt Anatomy

A good screen prompt can follow this structure:

```text
Design a mobile screen for [screen name].

Purpose:
[User goal]

Layout:
[Top / middle / bottom structure]

Content:
[Important information]

Primary action:
[Action]

Secondary actions:
[Actions]

Interaction:
[What happens when the user taps/expands/submits]

Visual direction:
[Style and relationship to existing screens]

UX requirements:
[Accessibility, simplicity, progressive disclosure, etc.]

Reference:
[Existing approved screen/style to preserve]
```

Keep the language natural. Do not begin with complicated XML or JSON unless there is a specific reason to do so.

---

# 10. Prompt Templates for VYAPAR MITRA

## A. Welcome Screen

```text
Design the mobile welcome screen for an AI business companion for first-time rural and semi-urban entrepreneurs in India.

The purpose is to immediately communicate that the app helps the entrepreneur understand whether a business idea is viable and guides them from idea to sustainable growth.

Use a welcoming, trustworthy and simple visual hierarchy.

Include:
- concise value proposition;
- short supporting explanation;
- primary CTA to get started;
- optional secondary action for an existing user;
- subtle local/business imagery.

Avoid dense text and avoid making the screen look like a generic AI chatbot.

Keep the layout mobile-first and suitable for Flutter implementation.
```

## B. Language Selection

```text
Design the language selection screen.

The user should be able to choose the language in which the AI assistant communicates.

Make language selection extremely clear for a first-time smartphone/app user.

Use large, readable language options and a clear selected state.

Include a primary Continue action.

The design should make it obvious that the AI will communicate in the selected language.

Keep the screen simple and avoid unnecessary settings.
```

## C. AI Interview

```text
Design a mobile conversational interview screen for a first-time rural entrepreneur.

The AI is collecting information about the entrepreneur's skills, experience, interests, goals, available resources and business preferences.

Use a friendly conversational layout with:
- AI message area;
- user response area;
- clear input control;
- optional microphone/voice action;
- progress indication;
- simple skip/back controls where appropriate.

The screen must not feel like a long form.

Show enough context for the user to understand why the current question matters.

Prioritize readability and comfortable mobile interaction.
```

## D. Opportunity Cards

```text
Design a mobile screen showing 3–5 business opportunities recommended for the entrepreneur.

Each opportunity card should communicate:
- business type;
- short explanation;
- why it may fit the entrepreneur;
- local relevance;
- major opportunity;
- important risk or unknown;
- confidence/evidence indicator.

Allow the entrepreneur to compare options and choose one.

Do not present the recommendation as an unquestionable answer. The UI should communicate that these are evidence-informed opportunities for the entrepreneur to evaluate.
```

## E. Research Dashboard

```text
Design a mobile business validation dashboard for the selected business idea.

The dashboard should summarize the validation process across:
- customer demand;
- competition;
- pricing;
- suppliers;
- distribution;
- purchasing power;
- local market context;
- risks;
- government schemes.

Show research progress clearly.

Use cards and progressive disclosure so the screen does not become overwhelming.

The user should be able to open an individual finding and inspect its evidence.
```

## F. Evidence Detail

```text
Design an evidence detail screen.

The user is viewing a finding used by the AI to support a business recommendation.

Clearly distinguish:
- claim/finding;
- supporting evidence;
- source;
- location/geography;
- date;
- limitations;
- confidence/quality;
- whether the evidence is primary or secondary research.

Make provenance visible without making the screen technically intimidating.

The user should understand not only what the system thinks, but why it thinks it.
```

## G. Financial Scenario

```text
Design a mobile financial planning screen for a small rural business.

Show a clear summary of:
- required investment;
- available capital;
- funding gap;
- possible loan/scheme;
- estimated monthly revenue;
- estimated costs;
- repayment amount;
- repayment duration;
- estimated profit.

Include editable assumptions and a clear What-If interaction so the entrepreneur can change important parameters.

Use strong visual separation between calculated values and AI explanations.

The financial calculation itself is deterministic; this screen only presents the results and explanations.
```

## H. Recommendation

```text
Design the final business recommendation screen.

The screen should answer:
1. What should the entrepreneur do?
2. Why is this recommended?
3. What evidence supports it?
4. What risks or unknowns remain?
5. What should the entrepreneur do next?

Use an executive-summary structure with progressive disclosure.

The recommendation must feel actionable rather than like a generic AI-generated report.

Include a clear primary action to continue to the action plan.
```

---

# 11. Refinement Prompt Examples

When the layout is good, do not regenerate everything.

### Hierarchy

```text
Keep the existing layout and visual language unchanged. Improve only the information hierarchy so the primary action and most important finding are immediately visible.
```

### Density

```text
Keep the current structure. Reduce information density by collapsing secondary details into expandable sections. Do not remove the core findings.
```

### Trust

```text
Keep the existing layout. Make the evidence supporting each recommendation easier to discover without adding visual clutter.
```

### Accessibility

```text
Keep the existing design. Improve readability, touch target size and text contrast for users with limited digital experience. Do not change the overall visual identity.
```

### Mobile ergonomics

```text
Keep the existing visual language. Optimize only for one-handed mobile use: comfortable touch targets, reachable primary actions, sensible vertical spacing and no desktop-style dense layouts.
```

### Visual polish

```text
Keep the layout and component positions unchanged. Refine only typography, spacing and visual consistency.
```

---

# 12. Reference-Screen Strategy

Once one screen is excellent, do not make every new screen from scratch.

Use the approved screen as the visual reference and say explicitly what must remain consistent.

Example:

```text
Create the Business Validation Summary screen using the approved Research Dashboard as the visual reference.

Preserve:
- exact visual language;
- typography;
- spacing system;
- card treatment;
- header structure;
- navigation;
- button style;
- overall mobile ergonomics.

Only change the content structure required for the Business Validation Summary.
```

This reduces visual drift between screens.

---

# 13. Global Changes vs Local Changes

Use a local screen prompt for a local change.

Use a global design mechanism/reference when the change should affect the whole application.

### Local

```text
Change only the financial scenario screen's chart.
```

### Global

```text
Apply the approved typography and spacing system consistently across all screens.
```

The Stitch discussion also describes using multi-select for global changes when appropriate.

---

# 14. Mobile-First Warning

Community discussion around Stitch includes reports that generated interfaces can sometimes lean toward web/CSS-style patterns rather than strong native-mobile ergonomics.

For this project, explicitly state:

```text
Mobile-first.
Designed for a smartphone.
Flutter implementation.
No desktop dashboard assumptions.
Comfortable touch targets.
Vertical scrolling.
Reachable primary actions.
Avoid dense desktop tables unless absolutely necessary.
```

Treat this as a practical caution from community experience, not as a guaranteed limitation of Stitch.

---

# 15. What NOT To Do

Avoid prompts like:

```text
Make the entire app amazing.
```

```text
Redesign everything and add charts, filters, animations, a new sidebar, dark mode, onboarding and payments.
```

```text
Create all 30 screens with every feature.
```

Avoid changing layout, typography, components and information architecture simultaneously unless a full redesign is actually intended.

Avoid using Stitch output as proof that the underlying product logic is correct.

Avoid copying a generated design directly into production without checking it against:

- `product.md`
- `ux.md`
- `architecture.md`
- `api-contracts.md`
- `security.md`

---

# 16. Stitch → Flutter Handoff

Once a screen is approved:

1. Save the screenshot/design reference.
2. Record the important visual tokens.
3. Identify reusable components.
4. Compare the screen against `ux.md`.
5. Map UI data to `api-contracts.md`.
6. Confirm required database data exists in `database.md`.
7. Implement in Flutter.
8. Run on an actual phone/emulator.
9. Compare implementation against the approved visual.
10. Fix implementation-specific issues.
11. Test interaction states.
12. Commit the working version.

The Flutter implementation is the real product. Stitch is the visual specification/prototype.

---

# 17. AI Coding-Agent Handoff

When giving an AI coding agent an approved Stitch design, provide:

```text
1. Product context
2. Relevant user journey
3. Approved Stitch screenshot/reference
4. Relevant UX requirements
5. Relevant API contract
6. Relevant database entities
7. Existing design tokens/components
8. Acceptance criteria
9. Test requirements
```

Tell the agent explicitly:

```text
Implement the approved design without inventing new product behaviour.

If the visual design conflicts with the product specification, stop and identify the conflict instead of silently changing the business logic.
```

---

# 18. Definition of Done for a Stitch Screen

A screen is ready for Flutter implementation when:

- [ ] Its purpose is clear.
- [ ] The primary action is obvious.
- [ ] It follows the user journey.
- [ ] Required product information is present.
- [ ] It does not invent unsupported product logic.
- [ ] It follows the established design language.
- [ ] It is mobile-first.
- [ ] Text is readable.
- [ ] Touch targets are practical.
- [ ] Loading/error/empty states have been considered where relevant.
- [ ] Evidence/trust information is visible where required.
- [ ] Financial values are clearly distinguished from AI explanations.
- [ ] Sensitive information is handled appropriately.
- [ ] The design has been saved as an approved reference.
- [ ] Flutter implementation requirements can be mapped from the screen.

---

# 19. Recommended Team Workflow

Use this division of responsibility:

### Product/UX decisions — Humans

The team decides:

- what the entrepreneur needs;
- what the app should do;
- what information matters;
- what is safe;
- what counts as evidence;
- what recommendations are allowed;
- what the VYAPAR MITRAncludes.

### Visual exploration — Stitch

Stitch helps with:

- layout exploration;
- visual hierarchy;
- component arrangements;
- visual style;
- rapid screen iteration.

### Implementation — Flutter + AI coding assistance

The team/AI coding agent handles:

- reusable Flutter components;
- navigation;
- state management;
- API integration;
- authentication;
- database integration;
- AI integration;
- maps;
- voice/language services;
- validation;
- testing.

### Backend — FastAPI + Supabase

The backend enforces:

- business logic;
- authorization;
- evidence handling;
- deterministic calculations;
- AI orchestration;
- external API boundaries;
- persistence.

---

# 20. The Complete Loop

For every feature:

```text
UNDERSTAND
    ↓
Read the relevant project docs
    ↓
DEFINE
    ↓
Write the screen/feature specification
    ↓
DESIGN
    ↓
Generate in Stitch
    ↓
INSPECT
    ↓
Check against UX + product requirements
    ↓
REFINE
    ↓
Make one focused change
    ↓
APPROVE
    ↓
Save visual checkpoint
    ↓
IMPLEMENT
    ↓
Build in Flutter
    ↓
RUN
    ↓
Test on emulator/device
    ↓
OBSERVE
    ↓
Capture screenshots/errors/logs
    ↓
FIX
    ↓
Give concrete evidence to the coding AI
    ↓
RETEST
    ↓
COMMIT
```

The central development principle remains:

> **Think → Specify → Generate → Run → Observe → Give AI evidence → Fix → Verify → Commit → Repeat.**

For Stitch specifically:

> **Design one thing well → preserve the visual language → make focused changes → save approved states → hand off to Flutter.**
