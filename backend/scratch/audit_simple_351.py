import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def audit_simple_351():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        # Query items bermasalah (Induk Langsung)
        query = """
            SELECT 
                c.name as kategori_induk,
                e.description,
                e.amount,
                e.date
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            WHERE c.parent_id IS NULL 
              AND EXTRACT(YEAR FROM e.date) = 2024
            ORDER BY e.amount DESC
        """
        cur.execute(query)
        rows = cur.fetchall()

        # Membuat Laporan Markdown Sederhana
        md = "# 📋 DAFTAR RINGKAS 351 ITEM STRIP - 2024\n\n"
        md += "| No | Kategori Induk | Deskripsi | Amount |\n"
        md += "| :-- | :--- | :--- | :--- |\n"
        
        for i, r in enumerate(rows, 1):
            # r: (kategori, desc, amount, date)
            md += f"| {i} | {r[0]} | {r[1]} | Rp {r[2]:,.0f} |\n"

        with open("LAPORAN_STRIP_RINGKAS.md", "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Laporan ringkas selesai: LAPORAN_STRIP_RINGKAS.md")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    audit_simple_351()
