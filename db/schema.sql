CREATE TABLE IF NOT EXISTS stock_prices (
  id BIGSERIAL PRIMARY KEY,

  symbol VARCHAR(20) NOT NULL,

  current_price NUMERIC(12,2) NOT NULL,

  previous_close NUMERIC(12,2) NOT NULL,

  change_percent NUMERIC(8,2) NOT NULL,

  currency VARCHAR(10) NOT NULL,

  market_status VARCHAR(20) NOT NULL,

  collected_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_prices_symbol ON stock_prices(symbol);

CREATE INDEX IF NOT EXISTS idx_stock_prices_collected_at ON stock_prices(collected_at);


---

CREATE TABLE IF NOT EXISTS stock_news (
  id BIGSERIAL PRIMARY KEY,

  symbol VARCHAR(20) NOT NULL,

  title TEXT NOT NULL,

  summary TEXT NOT NULL,

  published_at TIMESTAMP,

  url TEXT NOT NULL UNIQUE,

  collected_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stock_news_symbol ON stock_news(symbol);

CREATE INDEX IF NOT EXISTS idx_stock_news_collected_at ON stock_news(collected_at);
