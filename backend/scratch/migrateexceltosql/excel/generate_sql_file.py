import sys
import os
import pandas as pd
from datetime import datetime
import json

# Add backend path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))

excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"
sql_output_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\OUTPUT_MIGRASI_2024.sql"

def clean_amount(val):
    if pd.isna(val): return 0.0
    if isinstance(val, (int, float)): return float(val)
    val_str = str(val).upper().replace('RP', '').replace(' ', '')
    val_str = val_str.replace('.', '').replace(',', '.')
    try:
        return float(val_str)
    except:
        return 0.0

def escape_sql_string(val):
    if val is None or pd.isna(val): return "NULL"
    s = str(val).replace("'", "''")
    return f"'{s}'"

def map_category(subgroup_name, desc):
    text = str(subgroup_name).lower() + " " + str(desc).lower()
    if 'airplane' in text or 'transport' in text or 'taxi' in text or 'travel' in text or 'flight' in text or 'tiket' in text or 'ticket' in text:
        return 2 # Transportation
    if 'hotel' in text or 'mess' in text or 'penginapan' in text or 'kost' in text:
        return 3 # Accommodation
    if 'laundry' in text or 'loundry' in text:
        return 7 # Laundry
    if 'makan' in text or 'meal' in text or 'konsumsi' in text or 'minum' in text:
        return 5 # Meal
    if 'allowance' in text or 'uang saku' in text or 'perdiem' in text:
        return 4 # Allowance
    if 'logistik' in text or 'logistic' in text or 'ongkir' in text or 'kirim' in text:
        return 27 # Logistic
    if 'sparepart' in text or 'suku cadang' in text:
        return 29 # Sparepart
    if 'tool' in text or 'alat' in text:
        return 28 # Hand Tools
    if 'training' in text or 'bosiet' in text or 'pelatihan' in text:
        return 10 # Training
    if 'mcu' in text or 'medical' in text or 'rs' in text or 'kesehatan' in text:
        return 33 # Medical
    if 'bank' in text or 'admin' in text:
        return 25 # Biaya Bank
    if 'gaji' in text or 'salary' in text or 'fee' in text:
        return 11 # Gaji
    if 'sewa' in text or 'rental' in text:
        return 19 # Rental Tool
    return 71 # Biaya Operasi Lain-lain

print("Mengekstraksi data dari Excel...")
df_raw = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024')

revenues = []
expenses = []

mode = None
current_expense_group = None
current_expense_subgroup = None

for idx, row in df_raw.iterrows():
    row_str = " ".join([str(x).upper() for x in row.values])
    if "REVENUE & TAX" in row_str:
        mode = 'REVENUE'
        continue
    elif "OPERATION COST AND OFFICE" in row_str or "PENGELUARAN" in row_str:
        mode = 'EXPENSE'
        continue

    if mode == 'REVENUE':
        date_val = row.iloc[1]
        if isinstance(date_val, (pd.Timestamp, datetime)) or (isinstance(date_val, str) and '-' in date_val and len(date_val) > 5):
            desc = str(row.iloc[3]) if pd.notna(row.iloc[3]) else ''
            inv_val = clean_amount(row.iloc[5])
            curr = str(row.iloc[6]).strip() if pd.notna(row.iloc[6]) else 'IDR'
            exc = clean_amount(row.iloc[7]) if pd.notna(row.iloc[7]) else 1.0
            inv_num = str(row.iloc[8]) if pd.notna(row.iloc[8]) else ''
            client = str(row.iloc[9]) if pd.notna(row.iloc[9]) else ''
            recv_date = row.iloc[10]
            amt_recv = clean_amount(row.iloc[11])
            ppn = clean_amount(row.iloc[12])
            pph23 = clean_amount(row.iloc[13])
            trf_fee = clean_amount(row.iloc[14])
            remark = str(row.iloc[15]) if pd.notna(row.iloc[15]) else ''

            if inv_val > 0 or amt_recv > 0:
                if not isinstance(recv_date, (pd.Timestamp, datetime)): recv_date = None
                revenues.append({
                    'invoice_date': date_val, 'description': desc, 'invoice_value': inv_val,
                    'currency': curr, 'currency_exchange': exc, 'invoice_number': inv_num,
                    'client': client, 'receive_date': recv_date, 'amount_received': amt_recv,
                    'ppn': ppn, 'pph_23': pph23, 'transfer_fee': trf_fee, 'remark': remark
                })

    elif mode == 'EXPENSE':
        col1 = str(row.iloc[1]).strip()
        col3 = str(row.iloc[3]).strip()

        if col1.startswith('Expense#'):
            current_expense_group = col3
            current_expense_subgroup = None
            continue

        date_val = row.iloc[1]
        amt_val = row.iloc[5]

        if pd.isna(date_val) and pd.isna(amt_val) and col3 != 'nan' and col3 != '':
            current_expense_subgroup = col3
            continue

        if isinstance(date_val, (pd.Timestamp, datetime)) or (isinstance(date_val, str) and '-' in date_val and len(date_val) > 5):
            desc = col3
            source = str(row.iloc[4]) if pd.notna(row.iloc[4]) else ''
            amt = clean_amount(row.iloc[5])
            curr = str(row.iloc[6]).strip() if pd.notna(row.iloc[6]) else 'IDR'
            exc = clean_amount(row.iloc[7])
            if exc == 0.0: exc = 1.0

            if amt > 0:
                expenses.append({
                    'date': date_val, 'description': desc, 'source': source,
                    'amount': amt, 'currency': curr, 'currency_exchange': exc,
                    'expense_group': current_expense_group, 'expense_subgroup': current_expense_subgroup
                })

print(f"Ekstraksi selesai. Total Revenue: {len(revenues)}, Total Expense: {len(expenses)}")

with open(sql_output_path, 'w', encoding='utf-8') as f:
    f.write("-- =====================================================================\n")
    f.write("-- SQL SCRIPT: MIGRASI EXCEL KE DATABASE APLIKASI\n")
    f.write("-- SUMBER DATA: 20250427_EWI Financial-Repport_2024.xlsx\n")
    f.write("-- =====================================================================\n\n")

    f.write("BEGIN;\n\n")

    f.write("-- 1. Buat Settlement penampung untuk pengeluaran\n")
    f.write("INSERT INTO settlements (title, status, report_year, user_id, created_at, updated_at)\n")
    f.write("VALUES ('EXCEL MIGRATION 2024 OFFLINE', 'approved', 2024, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)\n")
    f.write("RETURNING id;\n\n")

    # We use a CTE or variable approach in SQL, but for raw SQL file, we can assume settlement ID or use a subquery
    f.write("-- (Catatan: Anda mungkin perlu menyesuaikan settlement_id di bawah ini jika dieksekusi manual)\n")
    f.write("-- Disini kita menggunakan subquery untuk mencari ID settlement yang baru dibuat\n\n")

    f.write("-- 2. Insert Revenues\n")
    for r in revenues:
        inv_date = r['invoice_date'].strftime('%Y-%m-%d') if hasattr(r['invoice_date'], 'strftime') else str(r['invoice_date'])[:10]
        recv_date = r['receive_date'].strftime('%Y-%m-%d') if r['receive_date'] and hasattr(r['receive_date'], 'strftime') else None
        recv_date_sql = f"'{recv_date}'" if recv_date else "NULL"

        f.write(f"INSERT INTO revenues (invoice_date, description, invoice_value, currency, currency_exchange, invoice_number, client, receive_date, amount_received, ppn, pph_23, transfer_fee, remark, revenue_type, report_year, created_at) VALUES ")
        f.write(f"('{inv_date}', {escape_sql_string(r['description'][:250])}, {r['invoice_value']}, {escape_sql_string(r['currency'])}, {r['currency_exchange']}, {escape_sql_string(r['invoice_number'][:50])}, {escape_sql_string(r['client'][:100])}, {recv_date_sql}, {r['amount_received']}, {r['ppn']}, {r['pph_23']}, {r['transfer_fee']}, {escape_sql_string(r['remark'][:250])}, 'pendapatan_langsung', 2024, CURRENT_TIMESTAMP);\n")

    f.write("\n-- 3. Insert Expenses\n")
    for e in expenses:
        cat_id = map_category(e['expense_subgroup'], e['description'])
        exp_date = e['date'].strftime('%Y-%m-%d') if hasattr(e['date'], 'strftime') else str(e['date'])[:10]
        desc = f"{e['expense_group']} - {e['description']}"[:250]

        f.write(f"INSERT INTO expenses (settlement_id, category_id, description, amount, date, source, currency, currency_exchange, status, created_at) VALUES ")
        f.write(f"((SELECT id FROM settlements WHERE title = 'EXCEL MIGRATION 2024 OFFLINE' LIMIT 1), {cat_id}, {escape_sql_string(desc)}, {e['amount']}, '{exp_date}', {escape_sql_string(e['source'][:50])}, {escape_sql_string(e['currency'])}, {e['currency_exchange']}, 'approved', CURRENT_TIMESTAMP);\n")

    f.write("\nCOMMIT;\n")

print(f"\n[+] Berhasil membuat file SQL mandiri di:\n{sql_output_path}")
