---
name: supabase
description: Best practices, schema conventions, Row Level Security (RLS) enforcement, and client adapter patterns for Supabase Postgres, Auth, and Storage in Vyapar Mitra.
---

# Supabase Integration Skill

## Architectural Boundaries
1. **Server-Side Primacy**: All sensitive business logic, AI orchestration, and financial calculations run in the FastAPI backend, NOT in direct client-to-database calls.
2. **Row Level Security (RLS)**: Every table in Postgres must have RLS enabled with explicit policies tied to `auth.uid()`.
3. **Role Segregation**:
   - `anon_key`: Used by Flutter client for initial auth, login, and public read-only configuration.
   - `authenticated`: Bound to authenticated user JWTs for profile-specific queries.
   - `service_role_key`: Strictly backend-only. Never expose to client applications or mobile builds.

## Database & Query Best Practices
- **Explicit Columns**: Always select explicit columns rather than `*` to optimize network payload and security.
- **Transactions & Cascades**: Ensure foreign key constraints have appropriate `ON DELETE CASCADE` or `RESTRICT` rules.
- **Error Handling**: Wrap all Supabase client calls in `try / except` blocks and convert PostgREST exceptions to standard domain error structures.
- **Deterministic Migrations**: All schema modifications must exist as versioned SQL migration files in `supabase/migrations/`.
