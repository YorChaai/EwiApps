
import psycopg2
from urllib.parse import urlparse
import os

# Database URI from .env
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\excel"
md_path = os.path.join(output_dir, "DB_DETAILED_AUDIT_2024.md")

def format_rp(val):
    return f"Rp {val:,.0f}"

def audit_db():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Menjalankan Audit Detail Database 2024...")

        md = "# 🕵️ Audit Detail Database PostgreSQL (Tahun 2024)\n\n"
        md += "Laporan ini merinci isi database saat ini untuk dibandingkan dengan data Excel.\n\n"

        # --- 1. SETTLEMENT & EXPENSES ---
        md += "## 💸 1. Rincian Item Settlement (Pengeluaran)\n"
        md += "Daftar transaksi pengeluaran yang terdaftar di sistem.\n\n"
        
        cur.execute("""
            SELECT 
                s.report_year,
                c.name as kategori,
                COALESCE(p.main_group, c.main_group) as group_utama,
                e.description,
                e.amount,
                e.date
            FROM expenses e
            JOIN settlements s ON e.settlement_id = s.id
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            WHERE s.report_year = 2024
            ORDER BY e.date ASC
        """)
        rows = cur.fetchall()
        
        md += "| Tanggal | Deskripsi | Kategori | Grup Utama | Nominal |\n"
        md += "| :--- | :--- | :--- | :--- | :---: |\n"
        total_exp = 0
        for yr, cat, group, desc, amt, dt in rows:
            md += f"| {dt} | {desc} | {cat} | {group or '-'} | {format_rp(amt)} |\n"
            total_exp += amt
        md += f"| **TOTAL** | | | | **{format_rp(total_exp)}** |\n\n"

        # --- 2. NERACA (BALANCE SHEET) ---
        md += "## ⚖️ 2. Isi Neraca (Dividend Settings)\n"
        cur.execute("SELECT * FROM dividend_settings WHERE year = 2024")
        cols = [desc[0] for desc in cur.description]
        row = cur.fetchone()
        if row:
            d = dict(zip(cols, row))
            md += "| Komponen Neraca | Nilai di Database |\n"
            md += "| :--- | :---: |\n"
            md += f"| Saldo Kas Awal | {format_rp(d.get('opening_cash_balance',0))} |\n"
            md += f"| Piutang Usaha | {format_rp(d.get('accounts_receivable',0))} |\n"
            md += f"| Modal Saham | {format_rp(d.get('share_capital',0))} |\n"
            md += f"| Laba Ditahan | {format_rp(d.get('retained_earnings_balance',0))} |\n"
        else:
            md += "⚠️ Data Neraca 2024 tidak ditemukan.\n"
        md += "\n"

        # --- 3. DEVIDEN ---
        md += "## 🏛️ 3. Daftar Pembagian Deviden\n"
        cur.execute("SELECT name, amount, date FROM dividends WHERE report_year = 2024")
        divs = cur.fetchall()
        if divs:
            md += "| Nama Penerima | Tanggal | Jumlah |\n"
            md += "| :--- | :--- | :---: |\n"
            total_div = 0
            for name, amt, dt in divs:
                md += f"| {name} | {dt} | {format_rp(amt)} |\n"
                total_div += amt
            md += f"| **TOTAL DEVIDEN** | | **{format_rp(total_div)}** |\n"
        else:
            md += "⚠️ Tidak ada data Deviden untuk 2024.\n"
        md += "\n"

        # --- 4. PEMETAAN KATEGORI ---
        md += "## 📂 4. Master Kategori yang Digunakan\n"
        cur.execute("SELECT name, main_group FROM categories WHERE parent_id IS NULL ORDER BY main_group")
        md += "| Nama Kategori Induk | Grup Utama |\n"
        md += "| :--- | :--- |\n"
        for name, group in cur.fetchall():
            md += f"| {name} | {group or 'BELUM DIATUR'} |\n"

        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Laporan audit detail dibuat: {md_path}")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    audit_db()
