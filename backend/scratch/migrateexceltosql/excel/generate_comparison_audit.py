
import pandas as pd
import psycopg2
from urllib.parse import urlparse
import os

# Paths
excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\excel"
md_path = os.path.join(output_dir, "COMPARISON_EXCEL_VS_SQL_DETAIL.md")

def format_rp(val):
    return f"Rp {val:,.0f}"

def run_audit():
    print("[*] Memulai Audit Perbandingan Detail...")
    
    # --- 1. DATA DARI EXCEL 1 ---
    # Sheet 1: Transaksi
    df_s1 = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024', skiprows=5)
    df_s1 = df_s1[df_s1.iloc[:, 3].notna()] # Ambil yang ada nomornya
    ex_exp_total = pd.to_numeric(df_s1.iloc[:, 12], errors='coerce').sum()
    
    # Sheet 2: Neraca (Coordinate B12 dkk - ini estimasi koordinat, nanti disesuaikan)
    # Kita baca mentah dulu untuk Sheet 2
    df_s2 = pd.read_excel(excel_path, sheet_name='Laba rugi -2024', header=None)
    # Misal Saldo Kas ada di baris yang mengandung 'KAS DAN SETARA KAS'
    ex_opening_cash = 0
    for i, row in df_s2.iterrows():
        if 'KAS DAN SETARA KAS' in str(row[2]):
            ex_opening_cash = row[4] if pd.notna(row[4]) else 0
            break

    # Sheet 3: Deviden
    df_s3 = pd.read_excel(excel_path, sheet_name='Business Summary', header=None)
    ex_div_total = 0
    # Estimasi pencarian total deviden di sheet summary
    for i, row in df_s3.iterrows():
        if 'Dividen' in str(row[1]) or 'Dividend' in str(row[1]):
            ex_div_total = row[2] if pd.notna(row[2]) else 0

    # --- 2. DATA DARI SQL ---
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    cur = conn.cursor()
    
    cur.execute("SELECT SUM(amount) FROM expenses e JOIN settlements s ON e.settlement_id = s.id WHERE s.report_year = 2024")
    sql_exp_total = cur.fetchone()[0] or 0
    
    cur.execute("SELECT opening_cash_balance FROM dividend_settings WHERE year = 2024")
    sql_opening_cash = cur.fetchone()[0] or 0
    
    cur.execute("SELECT SUM(amount) FROM dividends WHERE report_year = 2024")
    sql_div_total = cur.fetchone()[0] or 0
    
    conn.close()

    # --- 3. GENERATE MD REPORT ---
    md = "# 📋 Laporan Audit Perbandingan: Excel 1 vs Database SQL\n\n"
    md += "Laporan ini menunjukkan perbedaan data antara file manual perusahaan dan database aplikasi.\n\n"
    
    md += "## 💰 A. Ringkasan Transaksi (Pengeluaran)\n"
    md += "| Sumber | Total Pengeluaran (2024) | Keterangan |\n"
    md += "| :--- | :--- | :--- |\n"
    md += f"| Excel 1 (Sheet 1) | {format_rp(ex_exp_total)} | Data dari tabel Revenue-Cost |\n"
    md += f"| SQL (Postgres) | {format_rp(sql_exp_total)} | Data hasil import saat ini |\n"
    md += f"| **Selisih** | **{format_rp(abs(ex_exp_total - sql_exp_total))}** | {'⚠️ Ada Perbedaan' if abs(ex_exp_total - sql_exp_total) > 0 else '✅ Sinkron'} |\n\n"

    md += "## ⚖️ B. Komponen Neraca (Balance Sheet)\n"
    md += "| Komponen | Nilai di Excel 1 (Sheet 2) | Nilai di SQL | Status |\n"
    md += "| :--- | :--- | :--- | :--- |\n"
    md += f"| Saldo Kas Awal | {format_rp(ex_opening_cash)} | {format_rp(sql_opening_cash)} | {'❌ Perlu Update' if sql_opening_cash == 0 else '✅ Ada Isi'} |\n\n"

    md += "## 🏛️ C. Pembagian Deviden\n"
    md += "| Sumber | Total Deviden | Keterangan |\n"
    md += "| :--- | :--- | :--- |\n"
    md += f"| Excel 1 (Sheet 3) | {format_rp(ex_div_total)} | Berdasarkan ringkasan bisnis |\n"
    md += f"| SQL (Postgres) | {format_rp(sql_div_total)} | Data di database |\n"
    md += f"| **Status** | | {'❌ Data di SQL masih Kosong' if sql_div_total == 0 else '✅ Terisi'} |\n\n"

    md += "## 🔍 Kesimpulan & Temuan\n"
    if abs(ex_exp_total - sql_exp_total) > 1000000:
        md += "- **Temuan 1**: Ada selisih nominal pengeluaran yang cukup besar. Perlu pengecekan apakah ada item di Excel 1 yang belum ter-import atau ada duplikasi di SQL.\n"
    if sql_opening_cash == 0:
        md += "- **Temuan 2**: Data Neraca di SQL masih nol. Ini akan menyebabkan saldo di dashboard aplikasi tidak akurat.\n"
    
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md)
        
    print(f"[+] Laporan perbandingan dibuat: {md_path}")

if __name__ == "__main__":
    run_audit()
