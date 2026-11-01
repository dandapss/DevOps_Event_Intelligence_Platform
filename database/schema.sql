-- Initial business-data schema for the stock-and-news MVP.
-- This file declares structure only; it does not connect to or modify a database.

-- Keep historical observations and the source timestamp for traceability.
CREATE TABLE IF NOT EXISTS market_quotes (
    id BIGSERIAL PRIMARY KEY,
    symbol TEXT NOT NULL,
    source TEXT NOT NULL,
    price NUMERIC(18, 6) NOT NULL CHECK (price >= 0),
    currency CHAR(3) NOT NULL,
    change_percent NUMERIC(10, 4),
    observed_at TIMESTAMPTZ NOT NULL,
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (symbol, source, observed_at)
);

-- Store headlines and links only, not full article bodies or raw API responses.
-- The unique source/URL pair makes collector retries idempotent.
CREATE TABLE IF NOT EXISTS news_items (
    id BIGSERIAL PRIMARY KEY,
    source TEXT NOT NULL,
    source_id TEXT,
    canonical_url TEXT NOT NULL,
    title TEXT NOT NULL,
    published_at TIMESTAMPTZ,
    collected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    matched_symbol TEXT,
    UNIQUE (source, canonical_url)
);

-- Record batch outcomes for audit and dashboard queries.
-- Do not store secrets or full error responses in this table.
CREATE TABLE IF NOT EXISTS collection_runs (
    id BIGSERIAL PRIMARY KEY,
    source TEXT NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    finished_at TIMESTAMPTZ,
    status TEXT NOT NULL CHECK (status IN ('running', 'succeeded', 'failed')),
    records_seen INTEGER NOT NULL DEFAULT 0 CHECK (records_seen >= 0),
    records_stored INTEGER NOT NULL DEFAULT 0 CHECK (records_stored >= 0),
    error_code TEXT
);

CREATE INDEX IF NOT EXISTS idx_market_quotes_symbol_observed
    ON market_quotes (symbol, observed_at DESC);

CREATE INDEX IF NOT EXISTS idx_news_items_published
    ON news_items (published_at DESC);

CREATE INDEX IF NOT EXISTS idx_collection_runs_source_started
    ON collection_runs (source, started_at DESC);
