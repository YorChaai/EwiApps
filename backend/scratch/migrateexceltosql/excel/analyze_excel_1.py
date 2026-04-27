
import pandas as pd
import os

file_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"
output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\excel"
md_output = os.path.join(output_dir, "analysis_excel_1.md")

def analyze():
    print(f"[*] Menganalisis File 1: {os.path.basename(file_path)}")
    xls = pd.ExcelFile(file_path)
    
    with open(md_output, "w", encoding="utf-8") as f:
        f.write(f"# 📊 Analisis Excel 1 (Original Messy)\n\n")
        f.write(f"**File:** `{os.path.basename(file_path)}`\n\n")
        
        for sheet in xls.sheet_names:
            df = pd.read_excel(file_path, sheet_name=sheet).head(20)
            f.write(f"## Sheet: `{sheet}`\n")
            f.write(f"**Kolom terdeteksi:** {', '.join([str(c) for c in df.columns])}\n\n")
            f.write(df.to_markdown() + "\n\n")
            
    print(f"[+] Laporan analysis_excel_1.md dibuat.")

if __name__ == "__main__":
    analyze()
