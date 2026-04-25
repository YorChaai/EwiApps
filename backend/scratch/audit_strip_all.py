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

def run_comprehensive_audit():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai audit menyeluruh untuk item 'Tanpa Subkategori' (Strip)...")

        # Query untuk mencari di Expenses
        query = """
            SELECT 
                s.title as settlement_title,
                COALESCE(p.name, c.name) as kategori_induk,
                c.code as kode_terpakai,
                c.name as nama_terpakai,
                e.description,
                e.amount,
                e.date,
                (CASE WHEN c.id IN %s THEN 'Subkategori Strip' ELSE 'Induk Langsung' END) as tipe_mapping
            FROM expenses e
            JOIN settlements s ON e.settlement_id = s.id
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            WHERE e.category_id IN %s
            ORDER BY kategori_induk, e.date
        """
        cur.execute(query, (STRIP_SUBCAT_IDS, ALL_TARGET_IDS))
        rows = cur.fetchall()

        md_content = "# Audit Menyeluruh Item Tanpa Subkategori (Strip)\n\n"
        md_content += "Laporan ini mencakup semua item yang di Excel muncul di baris **'-'**, baik karena memilih subkategori strip atau langsung memilih kategori induk.\n\n"

        grand_total = sum(r[5] for r in rows)
        md_content += f"## GRAND TOTAL: Rp {grand_total:,.0f}\n\n"

        md_content += "| Induk | Kode | Tipe | Deskripsi | Amount | Settlement |\n"
        md_content += "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
        
        for r in rows:
            # r: (settlement, parent, code, name, desc, amount, date, type)
            md_content += f"| {r[1]} | {r[2]} | {r[7]} | {r[4]} | Rp {r[5]:,.0f} | {r[0]} |\n"

        # Simpan laporan
        output_file = "LAPORAN_STRIP_MENYELURUH.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] Berhasil! Laporan menyeluruh dibuat: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    run_comprehensive_audit()
