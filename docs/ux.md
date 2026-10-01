# UX

## SIH 26091 — AI-Powered Business Advisory Assistant

**Purpose:** Define the user experience for a first-time rural/semi-urban entrepreneur. The UX should make a complex business-validation system feel simple, trustworthy, local, multilingual, and actionable without hiding important evidence or uncertainty.

---

# 1. UX North Star

The entrepreneur should feel:

> **"I understand what I should do next, why the app recommends it, and what evidence supports that recommendation."**

The application should reduce the difficulty of business planning without pretending that entrepreneurship can be reduced to one AI score.

---

# 2. Primary User

The primary user is a:

**First-time rural or semi-urban entrepreneur**

The user may:

- have a business idea
- have only a rough idea
- have no fixed idea
- have limited business knowledge
- have limited access to professional business advice
- prefer an Indian language
- prefer voice interaction
- have limited financial resources
- need help understanding government schemes
- know their local market better than any online dataset

The UX must therefore be beginner-first.

---

# 3. UX Principles

## 3.1 Simplicity

Show the minimum information required to make the next decision.

Avoid unnecessary technical language.

---

## 3.2 Progressive Disclosure

Reveal complexity gradually.

```text
Simple answer
    ↓
Why?
    ↓
Evidence
    ↓
Detailed analysis
    ↓
Source details
```

A beginner should not be forced to understand the full research system.

---

## 3.3 Evidence-Based Trust

Important recommendations should have an obvious:

```text
Why this?
```

entry point.

That can reveal:

- evidence
- sources
- dates
- geography
- sample size
- limitations
- confidence

---

## 3.4 Entrepreneur Control

AI recommends.

Entrepreneur decides.

Important decisions should require user confirmation.

Examples:

```text
Choose business opportunity
Confirm business definition
Confirm financial assumptions
Start research
Proceed with recommended next step
```

---

## 3.5 Local Relevance

Location should be visible where it materially affects the result.

Example:

```text
Your area
Indore district
~10 km local market
```

Do not make the user repeatedly enter location.

---

## 3.6 Multilingual by Design

Language should be treated as a core product feature, not a translation layer added at the end.

The user should be able to choose a preferred language during onboarding.

The system should preserve meaning across:

```text
UI
AI conversation
Survey
Research summary
Financial explanation
Voice
```

---

# 4. Core Product Journey

The primary UX journey (full MVP):

```text
Welcome
   ↓
Language
   ↓
Onboarding
   ↓
Interview
   ↓
Business idea / No fixed idea
   ↓
Opportunity discovery
   ↓
Choose opportunity
   ↓
Confirm business
   ↓
Research
   ↓
Primary validation
   ↓
Analysis
   ↓
Financial planning
   ↓
Government schemes
   ↓
Detailed Project Report
   ↓
Recommendation
   ↓
Next action
   ↓
Digital Logbook (voice/text, offline-first)
   ↓
Continuous AI Insights
   ↓
Deviation detection
   ↓
Guided discussion
   ↓
Action suggestions
   ↓
Improve & Grow
```

Post-MVP additions:

```text
Business knowledge layer
+
GST / Tax compliance assistance
```

---

# 5. Onboarding

The onboarding should explain the product before asking for significant information.

Conceptual sequence:

```text
Welcome
↓
What the app does
↓
Language
↓
Business situation
↓
Basic profile
↓
Location
↓
Financial/eligibility information where needed
↓
Ready
```

Avoid turning onboarding into a long registration form.

---

# 6. Welcome Screen

The first screen should communicate the product in one sentence.

Example:

> **"Your AI business companion — from idea to growth."**

Supporting explanation:

> "Understand your local market, validate your idea, explore financial options, and know what to do next."

Primary CTA:

```text
Get Started
```

Secondary options can include:

```text
Already have an idea?
I need help finding an idea.
```

---

# 7. Language Selection

Language should be easy to find.

Example:

```text
Choose your preferred language

English
हिन्दी
[Regional language]
```

If supported, include a short voice sample or recognizable language label.

The selected language should affect subsequent AI interaction.

Whether the entire UI is translated automatically should remain a product decision until implementation is finalized.

---

# 8. Business Situation

Ask early:

```text
Do you already have a business idea?
```

Choices:

```text
Yes, I have an idea
I have a rough idea
No, help me find one
```

This creates the main branching point.

---

# 9. Location UX

Location is highly important to the product.

Ask for location in a simple way:

```text
Where do you want to start your business?

[Use my location]

or

[Select state]
[Select district]
[Enter town/village]
[Pincode]
```

If GPS is used, explain why:

> "We use your location to understand your local market, nearby businesses, and relevant opportunities."

Do not imply that GPS location is always exact.

---

# 10. Sensitive Information

If caste/community or other sensitive eligibility information is needed for scheme matching:

- explain why it is requested
- request consent where appropriate
- avoid making it feel mandatory when it is not necessary
- keep it separate from ordinary profile information
- do not display it unnecessarily throughout the application

Example:

> "This information can help us identify government schemes for which you may qualify."

---

# 11. Financial Information

Ask only information that is useful at that stage.

Examples:

```text
How much can you invest initially?
Do you already have business assets/equipment?
Would you consider a loan?
```

Do not ask for detailed financial information before it becomes relevant.

---

# 12. AI Interview UX

The interview should feel like a conversation with a helpful business advisor.

Not:

```text
Question 1/37
Question 2/37
...
```

Prefer:

```text
AI:
"Tell me a little about what you are good at or what kind of work
you enjoy."

User:
"I have worked with dairy animals."

AI:
"That's useful. Do you already have dairy equipment or animals?"
```

---

# 13. Interview Screen

Recommended layout:

```text
------------------------------------------------
Business Companion                    [Language]
------------------------------------------------

AI message

"Tell me about your experience..."

                         [🎙 Voice]

------------------------------------------------
[ Type your answer...                         ]
                         [ Send ]
------------------------------------------------

Understanding you  ●●●○○
------------------------------------------------
```

The progress indicator should represent meaningful progress, not a fake percentage.

---

# 14. Voice UX

Voice should be highly visible for users who prefer speaking.

Controls:

```text
Tap to speak
Listening...
Processing...
AI speaking...
```

The user must be able to interrupt/cancel.

Important values should be confirmed.

Example:

> "I heard that you have ₹2 lakh available. Is that correct?"

---

# 15. Conversation Context

The interface should make it clear that the AI remembers relevant business information.

Example:

> "You mentioned earlier that you already have a small shop."

This reduces repeated questions.

---

# 16. No-Idea Experience

When the user has no fixed business idea, the experience should feel like discovery rather than a generic list.

Flow:

```text
Interview
↓
"We found a few possibilities that fit your profile and location."
↓
3–5 opportunities
↓
Compare
↓
Choose one
```

---

# 17. Opportunity Cards

Each card should communicate the most important information quickly.

Example:

```text
┌─────────────────────────────────────┐
│ Millet Snack Processing             │
│                                     │
│ Why it may fit you                 │
│ ✓ Relevant experience              │
│ ✓ Local raw material signal        │
│ ✓ Fits your capital range         │
│                                     │
│ Market signal     Moderate/Strong  │
│ Competition       Moderate         │
│ Risk              Medium           │
│                                     │
│ [Explore]                           │
└─────────────────────────────────────┘
```

Do not present these indicators as absolute truth.

---

# 18. Opportunity Comparison

Users should be able to compare 3–5 opportunities.

Useful dimensions:

```text
Fit with your skills
Starting capital
Local demand signal
Competition
Risk
Potential support/schemes
Validation difficulty
```

Keep comparison understandable.

---

# 19. Business Confirmation

Before deep research:

```text
Here's what I understand:

Business:
Millet snack processing

Customer:
Local households + retailers

Location:
Your selected area

Starting scale:
Small/local

[That's correct]
[Edit]
```

This is a critical checkpoint.

---

# 20. Research Experience

Research should not feel like the application has frozen.

Show a progress-oriented experience:

```text
Understanding your business       ✓
Checking local market             ✓
Reviewing competition             ●
Checking customer signals         ○
Checking financial factors        ○
Preparing recommendation          ○
```

The exact percentage should only be shown if the system can calculate meaningful progress.

---

# 21. Research Loading States

Avoid:

```text
Loading...
```

for long periods.

Use meaningful messages:

```text
Finding local market signals...
Checking relevant sources...
Comparing available evidence...
Looking for conflicting signals...
Preparing your validation summary...
```

Do not claim a task is completed before it actually is.

---

# 22. Research Result Screen

Default layout:

```text
Business Validation

[Overall assessment]

Why?
1. ...
2. ...
3. ...

Evidence
[View evidence]

Market
Competition
Customer
Pricing
Suppliers
Finance
Risks

[Continue to financial planning]
```

---

# 23. Overall Assessment

Avoid relying on a giant numerical score.

Prefer a clear status such as:

```text
Promising
Promising with conditions
Needs more validation
High risk
Not recommended currently
```

The status must have a visible explanation.

---

# 24. Evidence Cards

Example:

```text
┌─────────────────────────────────────┐
│ Local demand signal                │
│                                     │
│ 18 of 25 interviewed customers     │
│ expressed purchase interest.        │
│                                     │
│ Primary research · Your area       │
│ Sample: 25                         │
│                                     │
│ [Why this matters] [View details]  │
└─────────────────────────────────────┘
```

Do not hide important limitations.

---

# 25. Evidence Detail

When opened:

```text
Claim
Source
Source type
Date
Geography
Data
Method/sample
Limitations
Confidence
```

This creates traceable recommendations.

---

# 26. Conflict UI

Conflicting evidence should be visually distinguishable.

Example:

```text
Mixed evidence

Government/industry data:
Demand appears strong.

Your local survey:
Interest is currently weaker.

Why this may differ:
The broader market may not represent your immediate customer segment.

[Investigate]
```

The system should never silently discard contradictory evidence.

---

# 27. SWOT UX

Use four simple sections:

```text
Strengths
Weaknesses
Opportunities
Threats
```

Each item should ideally have a short reason/evidence link.

Avoid filling the screen with generic text.

---

# 28. Executive Summary

This should be the most important output screen.

Recommended hierarchy:

```text
------------------------------------------------
YOUR BUSINESS VALIDATION
------------------------------------------------

PROMISING WITH CONDITIONS

Why we say this
• Reason 1
• Reason 2
• Reason 3

What supports this
[Evidence]

What could go wrong
[Top risks]

Financial picture
₹X investment
₹Y estimated monthly revenue
₹Z estimated monthly surplus

What to do next
1. ...
2. ...
3. ...

[Build my action plan]
------------------------------------------------
```

---

# 29. Financial UX

Financial planning should be understandable without requiring financial expertise.

Use editable assumptions.

Example:

```text
Initial investment       ₹5,00,000
Your contribution        ₹1,50,000
Loan                     ₹3,50,000

Expected monthly revenue ₹1,80,000
Operating cost           ₹1,10,000

[Adjust assumptions]
```

---

# 30. What-If Interaction

Make scenarios interactive.

Example:

```text
What if monthly revenue is lower?

₹1.8L  ─────●────
₹1.5L  ───●──────
₹1.2L  ─●────────

Estimated surplus
₹58,700 → ₹28,700 → ₹8,700
```

Exact values must come from deterministic calculations.

---

# 31. Financial Risk Communication

Do not use only colour.

Example:

```text
Repayment comfort: Moderate

Why:
Your projected monthly surplus is positive, but the buffer becomes
small if revenue falls below ₹X.
```

This is more informative than:

```text
GREEN
```

---

# 32. Government Scheme UX

Present schemes as opportunities to investigate, not guaranteed benefits.

Example:

```text
Potentially relevant schemes

Scheme A
✓ Matches business category
✓ Matches location
? Registration information needed

[View eligibility]

Scheme B
...
```

Always show:

```text
Last verified
Official source
Eligibility conditions
```

where appropriate.

---

# 33. Recommendation Screen

A recommendation should answer:

```text
What should I do?
Why?
What evidence supports it?
What could change the recommendation?
What should I do next?
```

Example:

```text
Recommendation

Start with a small paid pilot.

Why?
Local demand signals are encouraging, but the current sample is small.

Risk:
Repeat purchase behaviour is not yet validated.

Next step:
Test 30 customers before committing the full investment.

[Start this validation]
```

---

# 34. Action Plan

Recommendations should become concrete tasks.

Example:

```text
YOUR NEXT 7 DAYS

□ Interview 20 potential customers
□ Compare 3 local competitors
□ Test two price points
□ Check scheme eligibility
□ Update financial scenario
```

Each action should ideally explain why it matters.

---

# 35. Goal Gradient

Show meaningful progress toward the entrepreneur's goal.

Example:

```text
Business validation
██████░░░░ 60%

✓ Idea understood
✓ Market researched
✓ 25 customer responses
○ Pricing validation
○ Financial stress test
```

Do not create artificial progress merely to make the interface look engaging.

---

# 36. Smart Defaults

Use sensible defaults where they reduce decision fatigue.

Examples:

```text
Suggested survey questions
Suggested research geography
Suggested financial scenario
Suggested next action
Suggested opportunity
```

But always allow editing where the decision materially affects the outcome.

---

# 37. Contrast Effect

When presenting options, contextualize them.

Instead of:

```text
Loan A: ₹X
Loan B: ₹Y
```

show:

```text
Loan A
Lower repayment burden
Longer tenure

Loan B
Higher monthly repayment
Shorter tenure
```

The user should understand what each option means for their situation.

---

# 38. Loss Aversion

Use carefully and ethically.

Instead of only:

> "You could earn more."

Also explain:

> "Taking the full loan before validating demand could increase repayment pressure if sales are lower than expected."

Never use fear to manipulate the entrepreneur into a decision.

---

# 39. Reciprocity

Provide value before asking for unnecessary commitment.

The application should demonstrate usefulness before pushing:

```text
signup
payment
referral
sharing
```

Do not block the core value proposition behind unnecessary steps.

---

# 40. IKEA Effect

Allow meaningful customization.

Examples:

```text
Edit business assumptions
Choose target customer
Adjust expected investment
Modify survey questions
Select research area
Choose preferred recommendation priorities
```

The entrepreneur should feel that the business plan is theirs.

---

# 41. Accessibility

Design for users who may have:

- smaller screens
- lower digital literacy
- weaker internet
- limited familiarity with business software
- visual/hearing limitations

Requirements:

- readable typography
- strong contrast
- large touch targets
- clear icons + labels
- meaningful error messages
- voice alternatives
- minimal unnecessary animation
- no information conveyed by colour alone

---

# 42. Low-Connectivity UX

Where feasible:

```text
Cache
recent business state
last successful analysis
survey drafts
important profile information
```

If offline:

```text
You are offline.

Your saved work is safe.
We'll sync when you're connected.
```

Do not pretend a research request completed while offline.

---

# 43. Error UX

Errors should be actionable.

Bad:

```text
Error 500
```

Better:

> "We couldn't complete the market research because the research service is temporarily unavailable. Your existing work is safe. Try again."

For recoverable errors:

```text
[Try again]
```

For input errors:

```text
Tell us your approximate investment amount.
```

---

# 44. Empty States

Empty states should teach the user what to do.

Example:

```text
No business ideas yet.

Not sure what to start?
Let's talk about your skills, resources, and local market.

[Find an idea]
```

---

# 45. Navigation

A simple initial navigation model:

```text
Home
Research
Finance
Business
Profile
```

The exact information architecture can change after usability testing.

Avoid exposing every backend module as a navigation item.

---

# 46. Home Dashboard

The home screen should answer:

```text
Where am I?
What is my business?
What should I do next?
What changed?
```

Example:

```text
Good morning

Your business:
Millet Snack Processing

Validation:
███████░░░ 70%

Next best action:
Run customer price validation

Financial scenario:
Moderate repayment risk

[Continue]
```

---

# 47. Business Workspace

A business should have a central workspace.

Conceptual sections:

```text
Overview
Validation
Research
Customers
Competition
Finance
Schemes
Action Plan
Progress
```

The MVP may expose only the sections actually implemented.

---

# 48. Business State

The UI should clearly communicate the current stage.

Example:

```text
DISCOVER
✓

VALIDATE
● Current

DECIDE
○

START
○
```

Later:

```text
OPERATE
ANALYZE
GROW
```

---

# 49. Design System

Use reusable design tokens rather than styling every screen independently.

Define:

```text
Typography
Spacing
Corner radius
Elevation
Buttons
Inputs
Cards
Chips
Progress indicators
Dialogs
Bottom sheets
Navigation
Charts
Evidence components
AI message components
```

This prevents AI-generated screens from developing inconsistent styles.

---

# 50. Visual Language

The visual design should feel:

```text
Trustworthy
Warm
Modern
Simple
Local
Professional
Optimistic
```

Avoid:

- excessive corporate-dashboard styling
- overly futuristic AI visuals
- excessive gradients
- unnecessary glassmorphism
- visual clutter
- animations that distract from decisions

---

# 51. Animation Principles

Animation should communicate:

```text
progress
state change
feedback
relationship
```

Good examples:

- subtle onboarding transitions
- progress animation
- card entrance
- AI typing indicator
- successful task completion
- chart transitions

Avoid animation merely because it is possible.

Animations should remain performant on lower-end devices.

---

# 52. External UI Components

The development team may use established component/animation libraries and asset websites rather than building every animation from scratch.

However:

- check licenses
- prefer reusable components
- avoid importing huge libraries for one effect
- verify mobile performance
- maintain visual consistency

The source of a component should be documented when licensing requires it.

---

# 53. Illustrations

Illustrations can make complex concepts easier.

Useful places:

```text
Onboarding
No-idea discovery
Research loading
Empty states
Financial explanation
Success states
```

Illustrations should support comprehension rather than decorate every screen.

---

# 54. Charts

Charts should answer a question.

Examples:

```text
Revenue vs cost
Loan repayment
What-if scenarios
Predicted vs actual
Market/competition comparison
```

Do not display a chart if a simple number or sentence communicates the same thing better.

---

# 55. Data Density

The product may contain complex research.

Use hierarchy:

```text
Headline
↓
Key number
↓
Short explanation
↓
Evidence
↓
Details
```

Never force users to read a research report to understand the main recommendation.

---

# 56. Trust UI

Trust should be visible throughout the product.

Useful labels:

```text
Based on your survey
Official source
Last verified
Estimated
Calculated
User-provided
Mixed evidence
Needs more validation
```

These labels teach users how much confidence to place in a result.

---

# 57. AI Conversation + Structured UI

Do not make the entire product a chatbot.

Use the best interaction for each task:

```text
Chat:
interview, clarification, explanation

Cards:
opportunities, recommendations

Forms:
assumptions, profile, business definition

Charts:
financial scenarios

Tables:
detailed comparisons

Progress:
research/actions

Evidence cards:
source-backed claims
```

The AI conversation should complement the application rather than replace its interface.

---

# 58. Onboarding-to-Value Principle

The user should reach meaningful value quickly.

A good sequence:

```text
Understand product
↓
Answer a few useful questions
↓
Receive a meaningful insight
↓
Continue deeper
```

Avoid:

```text
Register
↓
Verify
↓
Fill 20 fields
↓
Accept 5 screens
↓
Finally see value
```

unless a specific requirement genuinely makes those steps necessary.

---

# 59. Decision Fatigue

The app should avoid presenting too many choices simultaneously.

Use:

```text
3–5 opportunities
Top 3 reasons
Top 3 risks
Next 1–3 actions
```

Detailed information can remain available behind expansion.

---

# 60. Recommendation Priority

If multiple recommendations exist, rank them by:

```text
Impact
+
Urgency
+
Evidence strength
+
Ease of validation
```

The user should know what matters most now.

---

# 61. User Corrections

The entrepreneur must be able to correct AI assumptions.

Example:

```text
AI:
"You have ₹5 lakh available."

User:
"No, I only have ₹2 lakh."

UI:
[Update financial assumption]
```

The corrected value should become structured application data.

---

# 62. Preventing AI UX Hallucinations

The UI must not display:

```text
fake progress
fake evidence
fake survey responses
fake source logos
fake approval status
fake financial calculations
```

Loading animations should represent actual system state.

---

# 63. Trustworthy Loading

A loading state should correspond to a real backend state.

Example:

```text
queued
running
processing evidence
analyzing
completed
failed
```

This makes long-running AI operations understandable.

---

# 64. Privacy UX

Explain sensitive data collection in simple language.

Example:

> "We use your location to understand your local market."

For sensitive eligibility data:

> "This information is used to identify potentially relevant government schemes."

Do not request sensitive information merely because it might someday be useful.

---

# 65. Notifications

Notifications should be useful and actionable.

Examples:

```text
Your research is ready.
A recommendation changed because of new evidence.
Your financial scenario needs attention.
A planned validation task is due.
```

Avoid excessive notifications.

---

# 66. Future Prediction-to-Reality UX

Eventually the app should show:

```text
What we expected
        vs
What actually happened
```

Example:

```text
Expected monthly revenue     ₹1.8L
Actual monthly revenue       ₹1.3L

Difference                   -28%

What changed?
Repeat purchases were lower than expected.

What should we test next?
Customer retention.
```

This creates a continuous learning loop.

---

# 67. Demo UX

For the SIH demonstration, the experience should be optimized around a clear story:

```text
First-time entrepreneur
        ↓
Shares background
        ↓
Gets 3–5 relevant opportunities
        ↓
Chooses one
        ↓
System researches local market
        ↓
Entrepreneur adds primary research
        ↓
AI detects/handles evidence
        ↓
Validation summary
        ↓
Financial scenario
        ↓
Relevant government schemes
        ↓
Clear next action
```

The demo should show the product's unique intelligence rather than only polished screens.

---

# 68. UX for Judges

A judge should quickly understand:

```text
Who is this for?
What problem does it solve?
Why is AI useful?
Where does the evidence come from?
Why is the recommendation trustworthy?
How is it localized?
How does finance work?
What happens after the recommendation?
```

The UI should make these answers visible through the product itself.

---

# 69. MVP UX Scope

The MVP should prioritize:

```text
Onboarding
Language
Location
Interview
Idea/no-idea branching
3–5 opportunities
Business confirmation
Secondary research
Primary survey/manual entry
Evidence
Conflict indication
Validation summary
SWOT
Financial scenario
Government scheme matching
Recommendations
Action plan
```

Do not overload the MVP with every future business-management feature.

---

# 70. Future UX Scope

Post-MVP:

```text
Business logbook
Daily/weekly operations
Inventory
Supplier management
Customer tracking
Sales tracking
Prediction-to-reality
Advanced analytics
Continuous recommendations
More language/voice support
Offline-first improvements
```

---

# 71. UX Testing

Before finalizing the product, test with representative users if possible.

Observe:

- Can they understand the onboarding?
- Can they find the language option?
- Do they understand why location is needed?
- Can they explain what the AI recommended?
- Can they find the evidence?
- Do they understand uncertainty?
- Can they modify a financial assumption?
- Do they know what to do next?
- Can they complete a short survey?
- Do they understand scheme eligibility is not guaranteed?

Do not rely only on the development team's assumptions.

---

# 72. AI-Agent UX Rules

When an AI coding agent creates or modifies a screen, it must:

1. Read this document.
2. Follow the design system.
3. Reuse existing components.
4. Avoid creating duplicate components.
5. Preserve navigation conventions.
6. Handle loading, empty, error, and success states.
7. Support the selected language architecture.
8. Consider accessibility.
9. Consider low-connectivity behaviour.
10. Never invent backend data.
11. Use API contracts from `api-contracts.md`.
12. Test the screen on realistic content lengths.
13. Check small-screen layouts.
14. Avoid unnecessary animation.
15. Report any UX assumption that is not defined.

---

# 73. Definition of Done

A UX feature is complete when:

- user goal is clear
- happy path works
- loading state works
- empty state works
- error state works
- success state works
- navigation is consistent
- text works with realistic translations
- long content does not break the layout
- touch targets are usable
- accessibility is considered
- evidence/uncertainty is visible where relevant
- AI output is not presented as unsupported fact
- API state is represented accurately
- animations do not block interaction
- design-system components are reused
- manual testing is complete

---

# 74. Final UX Principle

The application should make sophisticated technology feel simple.

The user should not need to understand:

```text
FastAPI
Supabase
Gemini
BHASHINI
APIs
database schemas
AI agents
research pipelines
```

They should understand:

```text
My business
My market
My money
My evidence
My risks
My next step
```

The strongest UX is therefore:

> **Simple on the surface, rigorous underneath.**
