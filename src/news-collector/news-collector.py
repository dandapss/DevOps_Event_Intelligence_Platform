import os
import calendar
from datetime import datetime, timezone
from urllib.request import urlopen, Request
import psycopg2
import feedparser as fp

DB_HOST = os.getenv("DB_HOST", "postgresql")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "event_intelligence")
DB_USER = os.getenv("DB_USER", "db_user")
DB_PASSWORD = os.getenv("DB_PASSWORD")
if not DB_PASSWORD:
  raise RuntimeError("DB_PASSWORD environment variable is required")

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

def get_news_data(symbol: str):
  url = f"https://feeds.finance.yahoo.com/rss/2.0/headline?s={symbol}&region=US&lang=en-US"
  print(url)

  # This url is not letting python to read so changing it to Mozilla
  req = Request(url,headers={"User-Agent": "Mozilla/5.0"})

  with urlopen(req, timeout=10) as response:
    feed = fp.parse(response.read())

  if not feed.entries:
    raise ValueError(f"No news entries found for {symbol}")
  return feed.entries

def save_news(data: dict, conn):
  # conn = get_connection()

  # try:
    with conn.cursor() as cur:
      cur.execute(
        """
        INSERT INTO stock_news
        (symbol,title,summary,published_at,url,collected_at)
        VALUES
        (%s,%s,%s,%s,%s,%s)
        ON CONFLICT (url) DO NOTHING
        """,
        (
          data["symbol"],
          data["title"],
          data["summary"],
          data["published_at"],
          data["url"],
          data["collected_at"]
        )
      )

def main():
  try:
    conn = get_connection()
  except Exception as e:
    print(f"[FAILED] Could not connect to PostgresSQL: {e}")
    return 1
  failed = False

  try:
    for symbol in SYMBOLS:
      try:
        entries = get_news_data(symbol)
        symbol_failed = False

        for entry in entries:
          title = entry.get("title")
          url = entry.get("link")

          if not title or not url:
            print(f"[FAILED] {symbol}: article is missing title or URL")
            failed = True
            symbol_failed = True
            continue

          published_parts = entry.get("published_parsed")
          published_at = (
            datetime.fromtimestamp(
              calendar.timegm(published_parts), tz=timezone.utc,
            )
            if published_parts
            else None
          )

          data = {
            "symbol" : symbol,
            "title" : title,
            "summary" : entry.get("summary") or "",
            "published_at" : published_at,
            "url" : url,
            "collected_at" : datetime.now(timezone.utc)
          }

          save_news(data, conn)
        conn.commit()
        if symbol_failed:
          print(f"[FAILED] {symbol}: one or more articles were skipped")
        else:
          print(f"[SUCCESS] {symbol}")
      except Exception as e:
        conn.rollback()
        failed = True
        print(f"[FAILED] {symbol}: {e}")      

  finally:
    conn.close()

  return 1 if failed else 0

if __name__ == "__main__":
  raise SystemExit(main())
