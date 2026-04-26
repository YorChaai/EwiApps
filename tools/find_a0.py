
import os
import glob

# Cari file SQL terbaru di data/exportdb
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEARCH_PATTERN = os.path.join(BASE_DIR, 'data', 'exportdb', '**', '*.sql')
sql_files = glob.glob(SEARCH_PATTERN, recursive=True)
# Urutkan berdasarkan waktu modifikasi terbaru
sql_files.sort(key=os.path.getmtime, reverse=True)

sql_file = sql_files[0] if sql_files else None

def find_a0_in_sql():
    if not sql_file or not os.path.exists(sql_file):
        print(f"File SQL tidak ditemukan di {os.path.join(BASE_DIR, 'data', 'exportdb')}")
        return

    print(f"--- Mencari baris yang mengandung 'A0' di: {os.path.basename(sql_file)} ---")
    with open(sql_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if "'A0'" in line or "A0" in line:
                print(f"Baris {i+1}: {line.strip()[:200]}...")

            # Berhenti setelah beberapa baris agar tidak kepanjangan
            if i > 50000: break

if __name__ == "__main__":
    find_a0_in_sql()
