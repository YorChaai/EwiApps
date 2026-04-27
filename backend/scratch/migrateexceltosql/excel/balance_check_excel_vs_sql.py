
import pandas as pd
import psycopg2
from urllib.parse import urlparse
import os

# Paths
excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def format_rp(val):
    return f"Rp {val:,.0f}"

def check_sync():
    print("[*] Memulai pengecekan keselarasan (Excel vs SQL)...")
    
    # 1. AMBIL DATA EXCEL 1
    # Sheet 1: Transaksi
    df_excel = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024', skiprows=5)
    # Bersihkan baris total di bawah (biasanya ada tulisan REVENUE (IDR) atau TOTAL)
    df_excel = df_excel[df_excel.iloc[:, 3].notna()] # Ambil yang ada nomornya (#)
    
    excel_total_revenue = pd.to_numeric(df_excel.iloc[:, 6], errors='coerce').sum() # INVOICE VALUE
    excel_total_expense = pd.to_numeric(df_excel.iloc[:, 12], errors='coerce').sum() # AMOUNT (Expense)
    
    # 2. AMBIL DATA SQL
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    cur = conn.cursor()
    
    cur.execute("SELECT SUM(invoice_value) FROM revenues WHERE report_year = 2024")
    sql_total_revenue = cur.fetchone()[0] or 0
    
    cur.execute("SELECT SUM(amount) FROM expenses e JOIN settlements s ON e.settlement_id = s.id WHERE s.report_year = 2024")
    sql_total_expense = cur.fetchone()[0] or 0
    
    cur.execute("SELECT opening_cash_balance FROM dividend_settings WHERE year = 2024")
    sql_opening_cash = cur.fetchone()[0] or 0
    
    cur.execute("SELECT SUM(amount) FROM dividends WHERE report_year = 2024")
    sql_total_div = cur.fetchone()[0] or 0
    
    conn.close()

    # REPORTING
    print("\n" + "="*50)
    print("PERBANDINGAN KESELARASAN (EXCEL VS SQL)")
    print("="*50)
    print(f"{'Komponen':<20} | {'Excel 1 (Manual)':<20} | {'SQL (Database)':<20}")
    print("-" * 65)
    print(f"{'Total Revenue':<20} | {format_rp(excel_total_revenue):<20} | {format_rp(sql_total_revenue):<20}")
    print(f"{'Total Expense':<20} | {format_rp(excel_total_expense):<20} | {format_rp(sql_total_expense):<20}")
    print(f"{'Saldo Kas (Neraca)':<20} | {'(Ada di Sheet 2)':<20} | {format_rp(sql_opening_cash):<20}")
    print(f"{'Total Deviden':<20} | {'(Ada di Sheet 3)':<20} | {format_rp(sql_total_div):<20}")
    print("="*50)
    
    if abs(excel_total_expense - sql_total_expense) < 1000:
        print("KESIMPULAN: Data Transaksi (Expense) SUDAH SELARAS.")
    else:
        print("KESIMPULAN: Data Transaksi BELUM SELARAS (Ada Selisih).")
        
    if sql_opening_cash == 0:
        print("PERINGATAN: Data Neraca di SQL masih KOSONG (Rp 0), perlu migrasi dari Sheet 2.")

if __name__ == "__main__":
    check_sync()
