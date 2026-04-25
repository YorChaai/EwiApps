
import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

try:
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    cur = conn.cursor()
    query = """
        SELECT c.code, c.name, COUNT(e.id)
        FROM expenses e
        JOIN categories c ON e.category_id = c.id
        WHERE c.parent_id IS NULL AND EXTRACT(YEAR FROM e.date) = 2024
        GROUP BY c.code, c.name
    """
    cur.execute(query)
    rows = cur.fetchall()
    print("=== SISA ITEM DI KATEGORI INDUK (2024) ===")
    if not rows:
        print("SEMUA BERSIH! Tidak ada item yang nyangkut di Induk.")
    else:
        for r in rows:
            print(f"Kategori {r[0]} ({r[1]}): {r[2]} item")
    conn.close()
except Exception as e:
    print(f"Error: {e}")
