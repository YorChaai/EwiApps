
import pandas as pd
import os

f1 = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"
f2 = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024_hasil bersih.xlsx"
f3 = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\Revenue-Cost_2024_20260427_2255.xlsx"

output_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\excel\STRATEGI_CONVERT_1_KE_3.md"

def clean_and_compare():
    # Load sheet Revenue-Cost_2024
    # Kita skip 5 baris pertama karena itu biasanya judul/header kotor
    df1 = pd.read_excel(f1, sheet_name='Revenue-Cost_2024', skiprows=5).dropna(how='all').head(10)
    df2 = pd.read_excel(f2, sheet_name='Revenue-Cost_2024', skiprows=5).dropna(how='all').head(10)
    df3 = pd.read_excel(f3, sheet_name='Revenue-Cost_2024', skiprows=5).dropna(how='all').head(10)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("# 🎯 Strategi Konversi: Dari Data Perusahaan (1) ke Data Indah (3)\n\n")
        
        f.write("## 🧐 Perbandingan Tampilan Data\n")
        f.write("Berikut adalah perbandingan 5 baris pertama dari masing-masing file setelah dibersihkan dari baris kosong:\n\n")

        f.write("### 🟥 FILE 1: ASLI PERUSAHAAN (Kotor)\n")
        f.write("> **Masalah:** Banyak kolom 'Unnamed', format tanggal tidak konsisten.\n\n")
        f.write(df1.iloc[:, :10].to_markdown() + "\n\n")

        f.write("### 🟨 FILE 2: HASIL BERSIH LAMA (SQLite)\n")
        f.write("> **Masalah:** Sudah lumayan, tapi subkategori masih belum sempurna.\n\n")
        f.write(df2.iloc[:, :10].to_markdown() + "\n\n")

        f.write("### 🟩 FILE 3: HASIL APLIKASI (Ideal/Tujuan)\n")
        f.write("> **Kelebihan:** Sangat rapi, kolom jelas, data flat, siap masuk SQL.\n\n")
        f.write(df3.iloc[:, :10].to_markdown() + "\n\n")

        f.write("## 🛠️ Cara Mengubah 1 Langsung ke 3\n")
        f.write("Kita akan membuat script `migrate_1_to_sql.py` yang melakukan:\n")
        f.write("1. **Header Remapping**: Menentukan bahwa kolom 'Unnamed: 2' di File 1 sebenarnya adalah 'Tanggal'.\n")
        f.write("2. **Data Type Correction**: Memaksa kolom uang menjadi angka (integer), bukan teks.\n")
        f.write("3. **Category Auto-Matching**: Mencari kata kunci di deskripsi untuk menentukan ID Kategori di Postgres.\n")
        f.write("4. **Postgres Sync**: Data dikirim ke tabel `revenues`, `expenses`, dan `taxes` di Postgres.\n")

    print(f"[+] Laporan STRATEGI_CONVERT_1_KE_3.md dibuat.")

if __name__ == "__main__":
    clean_and_compare()
