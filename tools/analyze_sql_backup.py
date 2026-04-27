import os
import re

sql_file = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\data\exportdb\2026-04-25_19-21-46\backup_postgres_2026-04-25_19-21-46.sql"

def analyze_backup():
    if not os.path.exists(sql_file):
        print("File tidak ditemukan")
        return

    # Counter
    settle_years = {}
    adv_years = {}

    # Trackers
    current_table = None

    # Regex untuk deteksi baris data di COPY (tab-separated)
    # Format biasanya: ID [tab] SETTLE_ID [tab] CAT_ID [tab] DESC [tab] AMOUNT [tab] DATE ...

    with open(sql_file, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()

            # Deteksi awal tabel
            if line.startswith('COPY public.expenses'):
                current_table = 'expenses'
                continue
            elif line.startswith('COPY public.advance_items'):
                current_table = 'advance_items'
                continue
            elif line == r'\.': # Akhir blok COPY
                current_table = None
                continue

            if current_table == 'expenses' and line:
                parts = line.split('\t')
                if len(parts) >= 6:
                    date_str = parts[5] # Kolom ke-6 adalah date
                    settle_id = parts[1]
                    try:
                        year = date_str.split('-')[0]
                        if year.isdigit():
                            year = int(year)
                            if settle_id not in settle_years.get(year, set()):
                                settle_years.setdefault(year, set()).add(settle_id)
                    except: pass

            if current_table == 'advance_items' and line:
                parts = line.split('\t')
                if len(parts) >= 9:
                    date_str = parts[8] # Kolom ke-9 adalah date
                    adv_id = parts[1]
                    try:
                        year = date_str.split('-')[0]
                        if year.isdigit():
                            year = int(year)
                            if adv_id not in adv_years.get(year, set()):
                                adv_years.setdefault(year, set()).add(adv_id)
                    except: pass

    # Cetak Hasil
    print("\n" + "="*45)
    print("ANALISIS DATA BACKUP (YEAR/AKTUAL)")
    print("="*45)
    print(f"{'YEAR':<10} | {'SETTLE':<15} | {'KASBON':<15}")
    print("-" * 45)

    all_years = sorted(list(set(list(settle_years.keys()) + list(adv_years.keys()))))
    for y in all_years:
        if 2020 <= y <= 2035:
            s_count = len(settle_years.get(y, []))
            a_count = len(adv_years.get(y, []))
            print(f"{y:<10} | {s_count:<15} | {a_count:<15}")
    print("="*45)

if __name__ == "__main__":
    analyze_backup()
