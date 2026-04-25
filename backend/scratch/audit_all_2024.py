import psycopg2
from urllib.parse import urlparse
import os

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# List ID Subkategori Strip & Kategori Induk untuk penandaan status
STRIP_SUBCAT_IDS = (50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 68)
PARENT_CAT_IDS = (1, 16, 18, 20, 23, 26, 30, 32, 34, 36, 38, 39, 42, 44, 46, 48, 67)

def run_full_audit_2024():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai audit seluruh pengeluaran tahun 2024...")

        # Query SEMUA item expenses di tahun 2024
        query = """
            SELECT 
                COALESCE(p.name, c.name) as nama_induk,
                (CASE WHEN p.name IS NULL THEN '---' ELSE c.name END) as nama_sub,
                c.code as kode_sub,
                (CASE 
                    WHEN c.id IN %s THEN '⚠️ Subkategori Strip'
                    WHEN c.id IN %s THEN '⚠️ Induk Langsung (Tanpa Sub)'
                    ELSE '✅ Subkategori Valid'
                END) as status_kategori,
                e.description,
                e.amount,
                e.date,
                s.title as settlement_title
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            JOIN settlements s ON e.settlement_id = s.id
            WHERE EXTRACT(YEAR FROM e.date) = 2024
            ORDER BY nama_induk, nama_sub, e.date
        """
        cur.execute(query, (STRIP_SUBCAT_IDS, PARENT_CAT_IDS))
        rows = cur.fetchall()

        md_content = "# Audit Seluruh Pengeluaran - Tahun 2024\n\n"
        md_content += "Laporan ini menampilkan **semua item** yang tercatat pada tahun 2024 untuk memantau konsistensi kategori.\n\n"
        
        grand_total = sum(r[5] for r in rows)
        md_content += f"### TOTAL SELURUH PENGELUARAN 2024: Rp {grand_total:,.0f}\n\n"

        md_content += "| Kategori Induk | Subkategori | Kode | Status | Deskripsi | Amount | Tanggal | Settlement |\n"
        md_content += "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
        
        for r in rows:
            # r: (induk, sub, kode, status, desc, amount, date, settlement)
            md_content += f"| {r[0]} | {r[1]} | {r[2]} | {r[3]} | {r[4]} | Rp {r[5]:,.0f} | {r[6]} | {r[7]} |\n"

        output_file = "LAPORAN_FULL_2024.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] Laporan full 2024 selesai: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    run_full_audit_2024()
