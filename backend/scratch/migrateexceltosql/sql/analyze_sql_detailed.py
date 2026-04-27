
import psycopg2
from urllib.parse import urlparse
import os

# Database URI from .env
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql"
md_path = os.path.join(output_dir, "db_detailed_info.md")

def analyze_db_detailed():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai analisis mendalam SQL...")

        md_content = "# 🔍 Laporan Kamus Data & Distribusi Tahunan\n\n"
        
        # 1. DISTRIBUSI DATA PER TAHUN (ACTUAL)
        md_content += "## 📅 1. Distribusi Data Per Tahun (Actual Transaction Date)\n"
        md_content += "Data volume berdasarkan kapan transaksi benar-benar terjadi.\n\n"

        queries = {
            'expenses': "SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM expenses GROUP BY 1 ORDER BY 1",
            'advances': "SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM advance_items GROUP BY 1 ORDER BY 1",
            'revenues': "SELECT EXTRACT(YEAR FROM invoice_date), COUNT(*) FROM revenues GROUP BY 1 ORDER BY 1",
            'taxes': "SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM taxes GROUP BY 1 ORDER BY 1",
            'dividends': "SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM dividends GROUP BY 1 ORDER BY 1"
        }

        for table, query in queries.items():
            md_content += f"### Tabel: `{table}`\n"
            md_content += "| Tahun | Jumlah Data |\n"
            md_content += "| :--- | :--- |\n"
            cur.execute(query)
            rows = cur.fetchall()
            for yr, count in rows:
                md_content += f"| {int(yr) if yr else 'NULL'} | {count} |\n"
            md_content += "\n"

        # 2. KAMUS DATA (TIPE DATA EXCEL-FRIENDLY)
        md_content += "## 🛠️ 2. Kamus Data (Tipe Kolom untuk Persiapan Excel)\n\n"

        cur.execute("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name")
        tables = [t[0] for t in cur.fetchall()]

        for table in tables:
            md_content += f"### Struktur Tabel: `{table}`\n"
            cur.execute(f"""
                SELECT column_name, data_type, character_maximum_length, is_nullable
                FROM information_schema.columns 
                WHERE table_name = '{table}'
                ORDER BY ordinal_position
            """)
            md_content += "| Kolom | Tipe Data (Excel) | Wajib? |\n"
            md_content += "| :--- | :--- | :--- |\n"
            for col, dtype, mlen, null in cur.fetchall():
                friendly = dtype
                if 'integer' in dtype: friendly = "Angka Bulat"
                elif 'precision' in dtype: friendly = "Angka Desimal"
                elif 'varying' in dtype: friendly = f"Teks (Max {mlen or ''})"
                elif 'text' in dtype: friendly = "Teks Panjang"
                elif 'date' in dtype: friendly = "Tanggal (YYYY-MM-DD)"
                elif 'timestamp' in dtype: friendly = "Waktu (YYYY-MM-DD HH:MM)"
                elif 'boolean' in dtype: friendly = "Boolean (True/False)"

                md_content += f"| {col} | {friendly} | {'TIDAK' if null == 'YES' else 'YA'} |\n"
            md_content += "\n"

        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] db_detailed_info.md dipulihkan.")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    analyze_db_detailed()
