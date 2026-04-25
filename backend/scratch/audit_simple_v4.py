import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def audit_simple_v4_351():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        # Query items bermasalah (Induk Langsung) dengan Code
        query = """
            SELECT 
                c.code,
                c.name as kategori_induk,
                e.description
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            WHERE c.parent_id IS NULL 
              AND EXTRACT(YEAR FROM e.date) = 2024
            ORDER BY e.amount DESC
        """
        cur.execute(query)
        rows = cur.fetchall()

        # Membuat Laporan Markdown sesuai request user (Format: Code - Name)
        md = "# 📋 DAFTAR RINGKAS STRIP 2024 (DENGAN KODE)\n\n"
        md += "| No | Kategori Induk | Deskripsi |\n"
        md += "| :-- | :--- | :--- |\n"
        
        for i, r in enumerate(rows, 1):
            # r: (code, name, desc)
            kategori_display = f"{r[0]} - {r[1]}"
            md += f"| {i} | {kategori_display} | {r[2]} |\n"

        output_file = "LAPORAN_STRIP_KODE_FINAL.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Laporan dengan kode selesai: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    audit_simple_v4_351()
