
import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def inspect_remaining_113():
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        query = """
            SELECT
                c.code,
                c.name as kategori_induk,
                e.description,
                e.amount
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            WHERE c.parent_id IS NULL
              AND EXTRACT(YEAR FROM e.date) = 2024
            ORDER BY c.code, e.amount DESC
        """
        cur.execute(query)
        rows = cur.fetchall()

        print(f"=== RINCIAN 113 ITEM PENTING DI KATEGORI INDUK ===\n")

        current_cat = ""
        for r in rows:
            if r[0] != current_cat:
                current_cat = r[0]
                print(f"\n--- KATEGORI {r[0]} ({r[1]}) ---")
            print(f"- Rp {r[3]:<12,.0f} | {r[2]}")

        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    inspect_remaining_113()
