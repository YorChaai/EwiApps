import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def debug_data():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("--- EXPENSES SAMPLE ---")
        cur.execute("SELECT id, description, category_id, amount FROM expenses LIMIT 20")
        for r in cur.fetchall():
            print(r)

        print("\n--- CATEGORIES SAMPLE ---")
        cur.execute("SELECT id, name, code, parent_id FROM categories WHERE name LIKE '%-%' LIMIT 20")
        for r in cur.fetchall():
            print(r)

        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_data()
