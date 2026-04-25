import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def audit_khusus_351_item():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Menganalisis 351 item 'Strip' tahun 2024...")

        # Query untuk mengambil HANYA item yang bermasalah (Induk Langsung)
        query = """
            SELECT 
                c.name as kategori_induk,
                c.code as kode,
                e.description,
                e.amount,
                e.date,
                s.title as settlement
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            JOIN settlements s ON e.settlement_id = s.id
            WHERE c.parent_id IS NULL             -- Mencari Induk Langsung
              AND EXTRACT(YEAR FROM e.date) = 2024 -- Tahun 2024
            ORDER BY e.amount DESC                 -- Urutkan dari yang Termahal
        """
        cur.execute(query)
        rows = cur.fetchall()

        # Membuat Laporan Markdown
        md = "# 📋 DAFTAR DETAIL 351 ITEM STRIP (INDUK LANGSUNG) - 2024\n\n"
        md += "Laporan ini berisi **seluruh 351 item** yang terbaca sebagai 'Strip' di Excel Anda.\n\n"
        
        total_dana = sum(r[3] for r in rows)
        md += f"### 💰 TOTAL DANA BERMASALAH: Rp {total_dana:,.0f}\n\n"

        md += "| No | Kategori Induk | Deskripsi | Amount | Tanggal | Settlement |\n"
        md += "| :-- | :--- | :--- | :--- | :--- | :--- |\n"
        
        for i, r in enumerate(rows, 1):
            # r: (kategori, kode, desc, amount, date, settlement)
            md += f"| {i} | {r[0]} | {r[2]} | Rp {r[3]:,.0f} | {r[4]} | {r[5]} |\n"

        with open("DAFTAR_PERBAIKAN_STRIP_2024.md", "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Selesai! {len(rows)} item ditemukan.")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    audit_khusus_351_item()
