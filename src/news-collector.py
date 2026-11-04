#https://feeds.finance.yahoo.com/rss/2.0/headline?s=MSFT&region=US&lang=en-US


import os
from datetime import datetime

import psycopg2
import feedparser as fp

DB_HOST = os.getenv("DB_HOST", "postgresql")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "event_intelligence")
DB_USER = os.getenv("DB_USER", "news")
DB_PASSWORD = os.getenv("DB_PASSWORD", "news")

SYMBOLS = os.getenv(
  "SYMBOLS",
  "MSFT,NVDA,TSM"
).split(",")

def get_news_data(symbol: str):
  url = f"https://feeds.finance.yahoo.com/rss/2.0/headline?s={symbol}&region=US&lang=en-US"
  print(url)
  feed = fp.parse(url)
  entries = feed.entries
  
  titles = entries[0].get("title")
  url = entries[0].get("link")
  if titles is None or url is None:
    raise Exception(
      f"News not found for {symbol}"
    )
  else:
    print(f"It passed@@@@@@@@@@@@@@@@")

# Need to ask GPT Codex. Way 1
# Need to use "list" in save_news
  articles = []
  for entry in entries:
    articles.append(
      {
        "symbol" : symbol,
        "title" : entry.get("title"),
        "summary" : entry.get("summary"),
        "published" : entry.get("published"),
        "url" : entry.get("link"),
        "collected_at" : datetime.utcnow()
      }
    )
  return articles

# Need to ask GPT Codex, Way 2
# Need to use "dict" in save_news 
  for entry in entries:
    new = {
      "symbol" : symbol,
      "title" : entry.get("title"),
      "summary" : entry.get("summary"),
      "published" : entry.get("published"),
      "url" : entry.get("link"),
      "collected_at" : datetime.utcnow()
    }

def get_connection():
  return psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD
  ) 


def save_news(data: dict):
  conn = get_connection()

  try:
    with conn.cursor() as cur:
      cur.execute(
        """
        INSERT INTO stock_news
        (symbol,title,summary,published_at,url,collected_at)
        VALUES
        (%s,%s,%s,%s,%s,%s)
        """,
        (
          data["symbol"],
          data["title"],
          data["summary"],
          data["published"],
          data["url"],
          data["collected_at"]
        )
      )
    conn.commit()

  finally:
    conn.close()


def main():
  for symbol in SYMBOLS:
    try:
      data = get_news_data(symbol)
      save_news(data)

      print(f"[SUCCESS] {symbol}")

    except Exception as e:
      print(f"[FAILED] {symbol} : {e}")

if __name__ == "__main__":
  main()

data = get_news_data("MSFT")
print("==== This is Data ====")
print(data)
print("==== This is save_news ====")
tt = save_news(data)
print(tt)

