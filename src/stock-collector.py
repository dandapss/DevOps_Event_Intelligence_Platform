import os
from datetime import datetime

import psycopg2
import yfinance as yf

DB_HOST = os.getenv("DB_HOST", "postgresql")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "event_intelligence")
DB_USER = os.getenv("DB_USER", "stock")
DB_PASSWORD = os.getenv("DB_PASSWORD", "stock")

SYMBOLS = os.getenv(
  "SYMBOLS",
  "MSFT,NVDA,TSM"
).split(",")

def get_connection():
  return psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD
  )

def get_stock_data(symbol: str):
  ticker = yf.Ticker(symbol)

  info = ticker.info

  current_price = info.get("currentPrice")
  previous_close = info.get("previousClose")

  if current_price is None or previous_close is None:
    raise Exception(
      f"Price information not found for {symbol}"
    )

  change_percent = (
    (current_price - previous_close) / previous_close
  ) * 100

  return {
    "symbol": symbol,
    "current_price": current_price,
    "previous_close": previous_close,
    "change_percent": change_percent,
    "currency": info.get("currency", "UNKNOWN"),
    "market_status": info.get("marketState", "UNKNOWN"),
    "collected_at": datetime.utcnow()
  }

def save_stock(data: dict):
  conn = get_connection()

  try:
    with conn.cursor() as cur:
      cur.execute(
        """
        INSERT INTO stock_prices
        (symbol,current_price,previous_close,change_percent,currency,market_status,collected_at)
        VALUES
        (%s,%s,%s,%s,%s,%s,%s)
        """,
        (
          data["symbol"],
          data["current_price"],
          data["previous_close"],
          data["change_percent"],
          data["currency"],
          data["market_status"],
          data["collected_at"]
        )
      )
    conn.commit()

  finally:
    conn.close()

def main():
  for symbol in SYMBOLS:
    try:
      data = get_stock_data(symbol)
      
      save_stock(data)

      print(
        f"[SUCCESS] {symbol}"
        f"{data['current_price']}"
      )

    except Exception as e:
      print(f"[FAILED] {symbol}: {e}")

if __name__ == "__main__":
  main()
