
import psycopg2
from urllib.parse import urlparse
import re

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def run_final_migration():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        # 1. Ambil Map Kategori (Code -> ID)
        cur.execute("SELECT code, id, name FROM categories")
        cat_map = {row[0]: row[1] for row in cur.fetchall()}

        # 2. Baca file hasil finalmapping.md
        md_path = r"backend/hasil finalmapping.md"
        with open(md_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        print("🚀 Memulai Migrasi Data berdasarkan Final Mapping...")

        success_count = 0
        fail_count = 0
        not_found_count = 0
        total_items = 0

        # Regex untuk membaca baris tabel: | No | Induk | Deskripsi | Target |
        # Contoh: | 1 | B - R&D | Deskripsi... | B1 - Alat |
        table_row_pattern = r"\|\s*(\d+)\s*\|\s*[^|]+\|\s*([^|]+)\|\s*([A-Z]\d+)[^|]*\|"

        for line in lines:
            match = re.search(table_row_pattern, line)
            if match:
                total_items += 1
                item_no = match.group(1)
                description = match.group(2).strip()
                target_code = match.group(3).strip()

                if target_code in cat_map:
                    target_id = cat_map[target_code]

                    # Cari expense yang cocok dengan deskripsi
                    # Kita gunakan LIKE karena deskripsi di MD mungkin sedikit terpotong/dibersihkan
                    query_find = "SELECT id FROM expenses WHERE description ILIKE %s"
                    cur.execute(query_find, (f"%{description}%",))
                    expense_rows = cur.fetchall()

                    if expense_rows:
                        # Update semua expense yang cocok
                        for exp in expense_rows:
                            exp_id = exp[0]
                            cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (target_id, exp_id))
                        success_count += 1
                    else:
                        # print(f"[!] Item No {item_no} tidak ditemukan di DB: {description[:50]}")
                        not_found_count += 1
                else:
                    print(f"[X] Kode Kategori {target_code} tidak ditemukan di Database!")
                    fail_count += 1

        conn.commit()

        print("\n=== HASIL MIGRASI ===")
        print(f"Total Item di Laporan: {total_items}")
        print(f"Berhasil Dimigrasi  : {success_count} kelompok item")
        print(f"Gagal (Kode Salah)  : {fail_count}")
        print(f"Tidak Ditemukan     : {not_found_count} (Mungkin sudah pernah dipindah)")
        print("=====================\n")

        conn.close()

        # Update status di file MD
        update_md_status(md_path, cat_map)

    except Exception as e:
        print(f"Error: {e}")

def update_md_status(file_path, cat_map):
    """Menambahkan kolom status 'Selesai' pada file MD"""
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    header_found = False

    for line in lines:
        if "| No | Kategori Induk |" in line:
            if "status" not in line:
                line = line.strip() + " status |\n"
            header_found = True
        elif "| :-- |" in line and header_found:
            if ":--- |" not in line: # check if separator for status already exists
                 line = line.strip() + " :--- |\n"
        elif header_found and line.startswith('|'):
            # Baris data
            if "Selesai" not in line:
                line = line.strip() + " Selesai |\n"

        new_lines.append(line)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print(f"📝 File {file_path} telah diperbarui dengan status 'Selesai'.")

if __name__ == "__main__":
    run_final_migration()
