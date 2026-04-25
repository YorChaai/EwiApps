import psycopg2
from urllib.parse import urlparse

db_uri = 'postgresql://postgres:yorchai12@localhost:5432/miniproject_db'
url = urlparse(db_uri)

STRIP_SUBCAT_IDS = (50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 68)
PARENT_CAT_IDS = (1, 16, 18, 20, 23, 26, 30, 32, 34, 36, 38, 39, 42, 44, 46, 48, 67)

conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
cur = conn.cursor()

query = """
    SELECT status, COUNT(*), SUM(amount)
    FROM (
        SELECT 
            (CASE 
                WHEN category_id IN %s THEN 'STRIP_SUBCAT'
                WHEN category_id IN %s THEN 'INDUK_LANGSUNG'
                ELSE 'VALID'
            END) as status,
            amount
        FROM expenses 
        WHERE EXTRACT(YEAR FROM date) = 2024
    ) sub
    GROUP BY status
"""
cur.execute(query, (STRIP_SUBCAT_IDS, PARENT_CAT_IDS))
results = cur.fetchall()

print('HASIL REKAPITULASI 2024:')
for r in results:
    print(f'{r[0]}: {r[1]} item, Total: Rp {r[2]:,.0f}')
conn.close()
