import pandas as pd

excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"

try:
    df_raw = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024')

    print("Melihat struktur blok Expense#1:")
    # Print rows 95 to 115
    for idx in range(95, 115):
        print(f"Baris {idx}: {df_raw.iloc[idx].values[:10]}")

except Exception as e:
    print(f"Error: {e}")
