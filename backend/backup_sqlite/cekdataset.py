import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database Anda
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def cek_isi_db():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("=== ANALISIS DATA JANUARI 2024 ===\n")

        # Query untuk melihat 20 data pertama di Januari 2024
        # Kita join ke categories untuk melihat nama kategorinya di DB
        query = """
            SELECT 
                e.id, 
                e.date, 
                e.description, 
                e.amount, 
                e.category_id, 
                c.code as cat_code, 
                c.name as cat_name
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            WHERE e.date >= '2024-01-01' AND e.date <= '2024-01-31'
            AND e.status = 'approved'
            ORDER BY e.date ASC
            LIMIT 20
        """
        cur.execute(query)
        rows = cur.fetchall()

        print(f"{'ID':<5} | {'Tanggal':<12} | {'Kategori di DB':<20} | {'Amount':<12} | {'Deskripsi'}")
        print("-" * 100)
        
        for r in rows:
            # r[5] adalah cat_code (A, A10, dll), r[6] adalah cat_name
            display_cat = f"{r[5]} - {r[6]}"
            print(f"{r[0]:<5} | {str(r[1]):<12} | {display_cat:<20} | {r[3]:<12,.0f} | {r[2]}")

        # Statistik per kategori
        print("\n=== RINGKASAN PER KATEGORI (JANUARI 2024) ===")
        cur.execute("""
            SELECT c.code, c.name, SUM(e.amount) 
            FROM expenses e 
            JOIN categories c ON e.category_id = c.id 
            WHERE e.date >= '2024-01-01' AND e.date <= '2024-01-31' 
            AND e.status = 'approved'
            GROUP BY c.code, c.name
            ORDER BY c.code
        """)
        for stats in cur.fetchall():
            print(f"Kategori {stats[0]} ({stats[1]}): Rp {stats[2]:,.0f}")

        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    cek_isi_db()
