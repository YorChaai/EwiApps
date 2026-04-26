
import os
import psycopg2
from urllib.parse import urlparse

# URL dari config Anda
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

try:
    conn = psycopg2.connect(
        dbname=url.path[1:],
        user=url.username,
        password=url.password,
        host=url.hostname,
        port=url.port
    )
    cursor = conn.cursor()

    print("--- 1. Cek Kategori A0 ---")
    cursor.execute("SELECT id, code, name FROM categories WHERE code = 'A0'")
    print(cursor.fetchone())

    print("\n--- 2. Contoh Pengeluaran di Kategori A0 (Januari 2024) ---")
    query = """
        SELECT e.id, e.date, e.description, e.idr_amount, e.combined_subcategory_label
        FROM expenses e
        JOIN categories c ON e.category_id = c.id
        WHERE c.code = 'A0' AND e.date >= '2024-01-01' AND e.date <= '2024-01-31'
        LIMIT 10
    """
    cursor.execute(query)
    for row in cursor.fetchall():
        print(row)

    conn.close()
except Exception as e:
    print(f"Error: {e}")
