
import sqlite3
import psycopg2
import pandas as pd
from urllib.parse import urlparse
import os

# --- KONFIGURASI ---
SQLITE_PATH = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\backup_sqlite\database_lama_sqlite_sebelum_postgres.db"
POSTGRES_URI = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
YEAR = 2024

def get_summary_data_sqlite(path):
    print(f"Mengambil data dari SQLite: {path}")
    conn = sqlite3.connect(path)
    # Ambil kategori
    cats = pd.read_sql_query("SELECT id, code, name, parent_id FROM categories", conn)
    # Ambil pengeluaran (di SQLite lama kolomnya 'amount')
    expenses = pd.read_sql_query(f"""
        SELECT category_id, date, amount
        FROM expenses
        WHERE status = 'approved' AND date LIKE '{YEAR}-%'
    """, conn)
    conn.close()
    return cats, expenses

def get_summary_data_postgres(uri):
    print(f"Mengambil data dari PostgreSQL...")
    url = urlparse(uri)
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    # Ambil kategori
    cats = pd.read_sql_query("SELECT id, code, name, parent_id FROM categories", conn)
    # Ambil pengeluaran
    expenses = pd.read_sql_query(f"""
        SELECT category_id, date, amount
        FROM expenses
        WHERE status = 'approved' AND EXTRACT(YEAR FROM date) = {YEAR}
    """, conn)
    conn.close()
    return cats, expenses

def process_to_matrix(cats, expenses):
    # Buat map kategori
    cat_map = {row['id']: f"{row['code']} - {row['name']}" for _, row in cats.iterrows()}

    # Siapkan baris data
    data = []
    for cat_id, cat_label in cat_map.items():
        row_data = {'Kategori': cat_label}
        cat_expenses = expenses[expenses['category_id'] == cat_id].copy()
        cat_expenses['month'] = pd.to_datetime(cat_expenses['date']).dt.month

        total_yearly = 0
        for m in range(1, 13):
            month_total = cat_expenses[cat_expenses['month'] == m]['amount'].sum()
            row_data[f"Bulan {m}"] = month_total
            total_yearly += month_total

        row_data['TOTAL'] = total_yearly
        data.append(row_data)

    df = pd.DataFrame(data)
    # Urutkan berdasarkan kode kategori (A, A1, A2...)
    df = df.sort_values('Kategori')
    return df

try:
    # 1. Olah SQLite
    s_cats, s_exps = get_summary_data_sqlite(SQLITE_PATH)
    df_sqlite = process_to_matrix(s_cats, s_exps)

    # 2. Olah PostgreSQL
    p_cats, p_exps = get_summary_data_postgres(POSTGRES_URI)
    df_postgres = process_to_matrix(p_cats, p_exps)

    # 3. Simpan ke Excel
    output_file = "Perbandingan_Database.xlsx"
    with pd.ExcelWriter(output_file) as writer:
        df_postgres.to_sheet_name = "DATA POSTGRES" # Alias dummy
        df_postgres.to_excel(writer, sheet_name="DATA_POSTGRESQL", index=False)
        df_sqlite.to_excel(writer, sheet_name="DATA_SQLITE_LAMA", index=False)

    print(f"\n✅ BERHASIL! File perbandingan disimpan di: {os.path.abspath(output_file)}")
    print("Silakan buka file tersebut untuk melihat perbedaan angka per sub-kategori.")

except Exception as e:
    print(f"❌ Error: {e}")
