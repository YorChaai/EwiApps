
import os

sql_file = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\data\exportdb\2026-04-25_00-42-55\backup_postgres_2026-04-25_00-42-55.sql"

def find_a0_in_sql():
    if not os.path.exists(sql_file):
        print("File tidak ada.")
        return

    print("--- Mencari baris yang mengandung 'A0' ---")
    with open(sql_file, 'r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if "'A0'" in line or "A0" in line:
                print(f"Baris {i+1}: {line.strip()[:200]}...")

            # Berhenti setelah beberapa baris agar tidak kepanjangan
            if i > 50000: break

if __name__ == "__main__":
    find_a0_in_sql()
