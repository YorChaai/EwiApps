import re

old_sql = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\backup_postgres_2026-04-28_00-04-50.sql"
new_sql = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\OUTPUT_MIGRASI_2024.sql"

def parse_old_sql():
    total_rev = 0
    total_exp = 0
    exp_count = 0
    rev_count = 0

    with open(old_sql, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    mode = None
    settlements_2024 = set()

    for line in lines:
        if line.startswith("COPY public.settlements "):
            mode = 'settlements'
            continue
        elif line.startswith("COPY public.expenses "):
            mode = 'expenses'
            continue
        elif line.startswith("COPY public.revenues "):
            mode = 'revenues'
            continue
        elif line.startswith(r"\."):
            mode = None
            continue

        if mode == 'settlements':
            parts = line.split('\t')
            if len(parts) > 6 and parts[6].strip() == '2024':
                settlements_2024.add(parts[0].strip())

        elif mode == 'expenses':
            parts = line.split('\t')
            if len(parts) > 10:
                settlement_id = parts[1].strip()
                if settlement_id in settlements_2024:
                    amount = float(parts[4])
                    currency = parts[9].strip()
                    exch = 1.0
                    try:
                        exch = float(parts[10])
                    except:
                        pass

                    if currency != 'IDR' and exch > 0:
                        amount *= exch
                    total_exp += amount
                    exp_count += 1

        elif mode == 'revenues':
            parts = line.split('\t')
            if len(parts) > 16 and parts[16].strip() == '2024':
                amount = float(parts[3])
                currency = parts[4].strip()
                exch = 1.0
                try:
                    exch = float(parts[5])
                except:
                    pass
                if currency != 'IDR' and exch > 0:
                    amount *= exch
                total_rev += amount
                rev_count += 1

    return total_rev, rev_count, total_exp, exp_count

def parse_new_sql():
    total_rev = 0
    total_exp = 0
    exp_count = 0
    rev_count = 0

    with open(new_sql, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    for line in lines:
        if line.startswith("INSERT INTO revenues "):
            # INSERT INTO revenues (...) VALUES ('2024-01-11', 'ALFA Service', 354210000.0, 'IDR', 1.0, ...
            match = re.search(r"VALUES \([^,]+,\s*'[^']*',\s*([0-9.]+),\s*'([^']+)',\s*([0-9.]+),", line)
            if match:
                amount = float(match.group(1))
                currency = match.group(2)
                exch = float(match.group(3))
                if currency != 'IDR' and exch > 0:
                    amount *= exch
                total_rev += amount
                rev_count += 1

        elif line.startswith("INSERT INTO expenses "):
            # INSERT INTO expenses (...) VALUES ((SELECT ...), 19, '...', 29640916.0, ...
            # look for amount which is after the desc string
            # It's fragile to split by comma because desc can have commas.
            # We know it looks like: , 29640916.0, '2024-01-11', 'BCA', 'IDR', 1.0, 'approved', CURRENT_TIMESTAMP);
            match = re.search(r",\s*([0-9.]+),\s*'[^']*',\s*'[^']*',\s*'([^']+)',\s*([0-9.]+),\s*'approved'", line)
            if match:
                amount = float(match.group(1))
                currency = match.group(2)
                exch = float(match.group(3))
                if currency != 'IDR' and exch > 0:
                    amount *= exch
                total_exp += amount
                exp_count += 1

    return total_rev, rev_count, total_exp, exp_count

print("=== PERBANDINGAN DATA LAPORAN 2024 ===")

old_rev, old_r_c, old_exp, old_e_c = parse_old_sql()
print("\n[DATABASE LAMA (backup_postgres...sql)]")
print(f"Total Transaksi Revenue : {old_r_c}")
print(f"Total Nominal Revenue   : Rp {old_rev:,.2f}")
print(f"Total Transaksi Expense : {old_e_c}")
print(f"Total Nominal Expense   : Rp {old_exp:,.2f}")

new_rev, new_r_c, new_exp, new_e_c = parse_new_sql()
print("\n[DATABASE BARU DARI EXCEL (OUTPUT_MIGRASI_2024.sql)]")
print(f"Total Transaksi Revenue : {new_r_c}")
print(f"Total Nominal Revenue   : Rp {new_rev:,.2f}")
print(f"Total Transaksi Expense : {new_e_c}")
print(f"Total Nominal Expense   : Rp {new_exp:,.2f}")

diff_exp = abs(old_exp - new_exp)
print(f"\nSelisih Pengeluaran     : Rp {diff_exp:,.2f}")
