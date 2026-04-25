import psycopg2
from urllib.parse import urlparse
import os

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# ID yang dianggap "Strip" di laporan (Subkategori '-' ATAU Kategori Induk langsung)
STRIP_SUBCAT_IDS = (50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 68)
PARENT_CAT_IDS = (1, 16, 18, 20, 23, 26, 30, 32, 34, 36, 38, 39, 42, 44, 46, 48, 67)

ALL_TARGET_IDS = STRIP_SUBCAT_IDS + PARENT_CAT_IDS

def run_audit_2024():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai audit item Strip khusus tahun 2024...")

        # Query detail dengan filter tahun 2024
        query = """
            SELECT 
                COALESCE(p.name, '---') as nama_induk,
                c.name as nama_sub,
                c.code as kode_sub,
                e.description,
                e.amount,
                e.date,
                s.title as settlement_title,
                (CASE 
                    WHEN c.id IN %s THEN 'Benar Strip (A0/B0/dll)'
                    WHEN c.id IN %s THEN 'Induk Langsung (Tanpa Sub)'
                    ELSE 'Lainnya'
                END) as status_kategori
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            JOIN settlements s ON e.settlement_id = s.id
            WHERE e.category_id IN %s
            AND EXTRACT(YEAR FROM e.date) = 2024
            ORDER BY nama_induk, kode_sub, e.date
        """
        cur.execute(query, (STRIP_SUBCAT_IDS, PARENT_CAT_IDS, ALL_TARGET_IDS))
        rows = cur.fetchall()

        md_content = "# Audit Item Strip - Tahun 2024\n\n"
        md_content += "Laporan ini hanya menampilkan item yang tercatat pada **tahun 2024**.\n\n"
        
        grand_total = sum(r[4] for r in rows)
        md_content += f"### TOTAL PENGELUARAN 2024: Rp {grand_total:,.0f}\n\n"

        md_content += "| Kategori Induk | Subkategori | Kode | Status | Deskripsi | Amount | Tanggal | Settlement |\n"
        md_content += "| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
        
        for r in rows:
            # r: (nama_induk, nama_sub, kode_sub, desc, amount, date, settlement, status)
            parent = r[0]
            sub = r[1]
            if r[7] == 'Induk Langsung (Tanpa Sub)':
                parent = sub
                sub = "---"
                
            md_content += f"| {parent} | {sub} | {r[2]} | {r[7]} | {r[3]} | Rp {r[4]:,.0f} | {r[5]} | {r[6]} |\n"

        output_file = "AUDIT_STRIP_2024.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] Audit 2024 selesai: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    run_audit_2024()
