
import psycopg2
from urllib.parse import urlparse
import os

# Database URI from .env
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql"
md_path = os.path.join(output_dir, "financial_report_2024.md")

def format_rp(val):
    return f"Rp {val:,.0f}"

def generate_report():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Membangun laporan Laba Rugi & Neraca 2024 (Logika Induk)...")

        md = "# 📝 Laporan Keuangan Komprehensif 2024\n\n"
        md += "Laporan ini mensimulasikan format Excel 'Laba Rugi' dan 'Neraca' berdasarkan data SQL saat ini.\n\n"

        # --- PART 1: LABA RUGI ---
        md += "## 📊 A. Laporan Laba Rugi (Profit & Loss)\n\n"
        
        # 1. PENDAPATAN
        cur.execute("SELECT revenue_type, SUM(invoice_value) FROM revenues WHERE report_year = 2024 GROUP BY 1")
        rev_data = dict(cur.fetchall())
        p_langsung = rev_data.get('pendapatan_langsung', 0)
        p_lain = rev_data.get('pendapatan_lain_lain', 0)
        total_p = p_langsung + p_lain

        md += "### I. PENDAPATAN\n"
        md += f"| Komponen | Nilai |\n"
        md += f"| :--- | :---: |\n"
        md += f"| Pendapatan Langsung | {format_rp(p_langsung)} |\n"
        md += f"| Pendapatan Lain-lain (Bunga Bank) | {format_rp(p_lain)} |\n"
        md += f"| **TOTAL PENDAPATAN** | **{format_rp(total_p)}** |\n\n"

        # LOGIKA: Ambil group dari kategori itu sendiri, atau dari Induknya jika kategori tersebut adalah sub.
        base_query = """
            SELECT 
                COALESCE(p.main_group, c.main_group) as group_utama,
                COALESCE(p.name, c.name) as nama_induk,
                SUM(e.amount)
            FROM expenses e
            JOIN settlements s ON e.settlement_id = s.id
            JOIN categories c ON e.category_id = c.id
            LEFT JOIN categories p ON c.parent_id = p.id
            WHERE s.report_year = 2024
            GROUP BY 1, 2
        """
        cur.execute(base_query)
        rows = cur.fetchall()
        
        beban_langsung = [r for r in rows if r[0] == 'BEBAN LANGSUNG']
        biaya_adm = [r for r in rows if r[0] == 'BIAYA ADMINISTRASI DAN UMUM']
        total_bl = sum(r[2] for r in beban_langsung)
        total_adm = sum(r[2] for r in biaya_adm)

        # 2. BEBAN LANGSUNG
        md += "### II. BEBAN LANGSUNG\n"
        md += f"| Sub-Komponen | Nilai |\n"
        md += f"| :--- | :---: |\n"
        for _, name, val in beban_langsung:
            md += f"| {name.upper()} | {format_rp(val)} |\n"
        md += f"| **TOTAL BIAYA LANGSUNG** | **{format_rp(total_bl)}** |\n\n"

        # 3. BIAYA ADMINISTRASI DAN UMUM
        md += "### III. BIAYA ADMINISTRASI DAN UMUM\n"
        md += f"| Sub-Komponen | Nilai |\n"
        md += f"| :--- | :---: |\n"
        for _, name, val in biaya_adm:
            md += f"| {name.upper()} | {format_rp(val)} |\n"
        md += f"| **TOTAL BIAYA ADM & UMUM** | **{format_rp(total_adm)}** |\n\n"

        # --- PART 2: NERACA ---
        md += "---\n\n## ⚖️ B. Laporan Neraca (Balance Sheet) - 31 Des 2024\n\n"
        cur.execute("SELECT * FROM dividend_settings WHERE year = 2024")
        columns = [desc[0] for desc in cur.description]
        row = cur.fetchone()
        
        if row:
            data = dict(zip(columns, row))
            md += "### I. AKTIVA (ASSETS)\n"
            md += "| Komponen Aktiva | Nilai |\n"
            md += "| :--- | :---: |\n"
            md += f"| Kas dan Setara Kas | {format_rp(data.get('opening_cash_balance', 0))} |\n"
            md += f"| Piutang Usaha | {format_rp(data.get('accounts_receivable', 0))} |\n"
            md += f"| Pajak Dibayar di Muka (PPh 23) | {format_rp(data.get('prepaid_tax_pph23', 0))} |\n"
            md += f"| Inventaris Kantor | {format_rp(data.get('office_inventory', 0))} |\n"
            total_aktiva = data.get('opening_cash_balance', 0) + data.get('accounts_receivable', 0) + data.get('office_inventory', 0)
            md += f"| **TOTAL AKTIVA** | **{format_rp(total_aktiva)}** |\n\n"

            md += "### II. PASIVA (LIABILITIES & EQUITY)\n"
            md += "| Komponen Pasiva | Nilai |\n"
            md += "| :--- | :---: |\n"
            md += f"| Hutang Usaha | {format_rp(data.get('accounts_payable', 0))} |\n"
            md += f"| Hutang Gaji | {format_rp(data.get('salary_payable', 0))} |\n"
            md += f"| Modal Saham | {format_rp(data.get('share_capital', 0))} |\n"
            md += f"| Laba Ditahan | {format_rp(data.get('retained_earnings_balance', 0))} |\n"
            total_pasiva = data.get('accounts_payable', 0) + data.get('salary_payable', 0) + data.get('share_capital', 0) + data.get('retained_earnings_balance', 0)
            md += f"| **TOTAL HUTANG & MODAL** | **{format_rp(total_pasiva)}** |\n\n"

        # --- PART 3: DEVIDEN ---
        cur.execute("SELECT SUM(amount) FROM dividends WHERE report_year = 2024")
        total_div = cur.fetchone()[0] or 0
        md += "### 🏛️ III. DEVIDEN\n"
        md += f"Total Deviden yang dibagikan pada tahun 2024: **{format_rp(total_div)}**\n\n"

        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Laporan Keuangan 2024 berhasil diperbarui.")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_report()
