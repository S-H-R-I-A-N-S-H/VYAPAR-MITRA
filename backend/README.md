# VYAPAR MITRA — Backend API

FastAPI-based modular monolith serving as the backend boundary for VYAPAR MITRA.

## Core Responsibilities
- **Authentication & Authorization**: Supabase JWT session verification and ownership checks.
- **Deterministic Financial Engine**: Authoritative EMI, project-cost, cash-flow, and affordability calculations.
- **Scheme Matching Engine**: Structured deterministic eligibility rules for government schemes (PMEGP, Mudra, etc.).
- **Research & Evidence Pipeline**: Secondary market research orchestration, primary survey aggregation, and conflict detection.
- **AI Orchestration**: Gemini integration enforcing strict Pydantic JSON schemas.
- **External Adapters**: Pluggable adapters for BHASHINI and Mappls with sandbox/mock fallbacks.

## Local Setup

1. Create a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

4. Run tests:
   ```bash
   pytest
   ```
