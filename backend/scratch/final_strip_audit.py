import psycopg2
from urllib.parse import urlparse
import os

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# List ID Subkategori Strip yang diminta user
STRIP_IDS = (50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 68)

def run_audit():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai audit item berdasarkan List ID Strip...")

        md_content = "# Laporan Audit Item Subkategori Strip (-)\n\n"
        md_content += f"Audit dilakukan terhadap **{len(STRIP_IDS)} ID Subkategori** yang memiliki nama '-'.\n\n"

        # 1. Cari di tabel expenses (Settlement)
        query_expenses = f"""
            SELECT 
                s.title as settlement_title,
                p.name as kategori_induk,
                c.code as kode_sub,
                c.name as nama_sub,
                e.description,
                e.amount,
                e.date
            FROM expenses e
            JOIN settlements s ON e.settlement_id = s.id
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            WHERE e.category_id IN %s
            ORDER BY s.title, e.date
        """
        cur.execute(query_expenses, (STRIP_IDS,))
        expense_rows = cur.fetchall()

        md_content += "## 1. Item di Settlement (Expenses)\n"
        if not expense_rows:
            md_content += "✅ Tidak ditemukan item di tabel expenses yang menggunakan ID strip ini.\n\n"
        else:
            md_content += f"Ditemukan **{len(expense_rows)} item**:\n\n"
            md_content += "| Settlement | Induk | Kode | Deskripsi | Amount | Tanggal |\n"
            md_content += "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
            for r in expense_rows:
                md_content += f"| {r[0]} | {r[1]} | {r[2]} | {r[4]} | Rp {r[5]:,.0f} | {r[6]} |\n"
            md_content += "\n"

        # 2. Cari di tabel advance_items (Kasbon)
        query_advances = f"""
            SELECT 
                a.title as advance_title,
                p.name as kategori_induk,
                c.code as kode_sub,
                c.name as nama_sub,
                ai.description,
                ai.estimated_amount,
                ai.date
            FROM advance_items ai
            JOIN advances a ON ai.advance_id = a.id
            JOIN categories c ON ai.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            WHERE ai.category_id IN %s
            ORDER BY a.title, ai.date
        """
        cur.execute(query_advances, (STRIP_IDS,))
        advance_rows = cur.fetchall()

        md_content += "## 2. Item di Kasbon (Advance Items)\n"
        if not advance_rows:
            md_content += "✅ Tidak ditemukan item di tabel advances yang menggunakan ID strip ini.\n\n"
        else:
            md_content += f"Ditemukan **{len(advance_rows)} item**:\n\n"
            md_content += "| Kasbon | Induk | Kode | Deskripsi | Amount | Tanggal |\n"
            md_content += "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
            for r in advance_rows:
                md_content += f"| {r[0]} | {r[1]} | {r[2]} | {r[4]} | Rp {r[5]:,.0f} | {r[6]} |\n"
            md_content += "\n"

        # Simpan laporan
        output_file = "LAPORAN_AUDIT_STRIP_FINAL.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] Selesai! Laporan berhasil dibuat: {output_file}")
        
        conn.close()
    except Exception as e:
        print(f"[!] Terjadi kesalahan: {e}")

if __name__ == "__main__":
    run_audit()
