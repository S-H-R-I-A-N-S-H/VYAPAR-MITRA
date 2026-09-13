-- 2026-10-01: Create Logbook schema and transactions table
CREATE SCHEMA IF NOT EXISTS logbook;

CREATE TABLE IF NOT EXISTS logbook.transactions (
    id               BIGSERIAL PRIMARY KEY,
    user_id          UUID        NOT NULL REFERENCES auth.users(id),
    item_description TEXT        NOT NULL,
    quantity         NUMERIC     NOT NULL,
    unit             VARCHAR(20) NOT NULL, -- e.g., litre, kg
    amount_rupees    NUMERIC(12,2) NOT NULL,
    category         VARCHAR(50),
    tags             TEXT[],
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    synced           BOOLEAN      NOT NULL DEFAULT FALSE
);
