
import psycopg2
from urllib.parse import urlparse

db_uri = 'postgresql://postgres:yorchai12@localhost:5432/miniproject_db'
url = urlparse(db_uri)
try:
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    cur = conn.cursor()
    cur.execute("SELECT code, name FROM categories ORDER BY code")
    rows = cur.fetchall()
    for row in rows:
        print(f"{row[0]}: {row[1]}")
    conn.close()
except Exception as e:
    print(f"Error: {e}")
