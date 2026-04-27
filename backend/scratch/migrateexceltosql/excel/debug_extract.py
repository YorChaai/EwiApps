import pandas as pd
import numpy as np

excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"

try:
    df_raw = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024')
    print("Membaca Excel...")

    mode = None
    for idx, row in df_raw.iterrows():
        row_str = " ".join([str(x).upper() for x in row.values])
        if "REVENUE & TAX" in row_str:
            mode = 'REVENUE'
            print(f"[{idx}] Masuk Mode REVENUE")
            continue
        elif "OPERATION COST AND OFFICE" in row_str or "PENGELUARAN" in row_str:
            if mode != 'EXPENSE':
                mode = 'EXPENSE'
                print(f"[{idx}] Masuk Mode EXPENSE")
            continue

        if mode == 'REVENUE' and idx < 20: # Just print first few to debug
            print(f"  [REV DEBUG] row[1]: {row.iloc[1]} (type: {type(row.iloc[1])}), row[5]: {row.iloc[5]}")

except Exception as e:
    print(f"Error: {e}")
