
import psycopg2
from urllib.parse import urlparse
import re

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# Aturan Kata Kunci per Kode
RULES = {
    'A1': ['ticket', 'airplane', 'taxi', 'toll', 'fee', 'rental', 'transport', 'parkir', 'bensin', 'fuel', 'solar', 'mobil', 'moving'],
    'A2': ['hotel', 'penginapan', 'mess', 'stay', 'homestay'],
    'A3': ['tunjangan lapangan', 'field allowance', 'allowance'],
    'A4': ['makan', 'meal', 'lunch', 'dinner', 'snack', 'snak', 'aqua', 'minum'],
    'A10': ['gaji', 'payroll', 'raple', 'bonus', 'thr'],
    'A11': ['sales'],
    'A12': ['wastafel', 'fabricate', 'panel', 'dummy test', 'project operation'],
    'A14': ['maintenance', 'service', 'perbaikan', 'repair', 'cuci'],
    'B1': ['pembuatan alat', 'lab', 'research'],
    'D1': ['data processing', 'log data'],
    'D2': ['license', 'software', 'google', 'subscription', 'internet'],
    'E1': ['white marker', 'spidol', 'stationery', 'kertas', 'atk', 'office'],
    'E2': ['bank', 'admin fee', 'transfer', 'biaya bank'],
    'F1': ['logistic', 'pengiriman', 'kurir', 'jne', 'tiki', 'pos', 'delivery'],
    'F2': ['gloves', 'steker', 'hand tools', 'kunci', 'tools', 'isolasi', 'lakban', 'safety'],
    'F3': ['battery', 'baterai', 'sparepart', 'accu', 'suku cadang', 'filter oil', 'part'],
    'H1': ['medical', 'kesehatan', 'obat', 'dokter', 'rs', 'rumah sakit']
}

def strict_family_fix():
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        # 1. Ambil data kategori
        cur.execute("SELECT id, code, name, parent_id FROM categories")
        rows = cur.fetchall()
        cat_by_id = {r[0]: {'code': r[1], 'name': r[2], 'parent_id': r[3]} for r in rows}
        cat_by_name = {r[2].lower().strip(): r[0] for r in rows if r[3] is None} # Parent Map

        # 2. Ambil semua expenses
        cur.execute("SELECT id, description, category_id FROM expenses")
        expenses = cur.fetchall()

        print(f"Mulai merapikan {len(expenses)} data agar tetap dalam Grup Induk yang benar...")

        updated_count = 0
        for exp_id, desc, current_id in expenses:
            if not desc: continue

            # Ekstrak Parent dari deskripsi, misal [Biaya Operasi]
            match = re.search(r'\[(.*?)\]', desc)
            if not match: continue

            tag_name = match.group(1).lower().strip()

            # Cari ID Induk berdasarkan tag tersebut
            target_parent_id = None
            if tag_name in cat_by_name:
                target_parent_id = cat_by_name[tag_name]

            if target_parent_id is None: continue

            # Sekarang cari subkategori TERBAIK HANYA di bawah target_parent_id ini
            best_sub_id = None
            desc_low = desc.lower()

            # Prioritas 1: Cari yang cocok kata kunci
            for cid, data in cat_by_id.items():
                if data['parent_id'] == target_parent_id:
                    keywords = RULES.get(data['code'], [])
                    if any(kw in desc_low for kw in keywords):
                        best_sub_id = cid
                        break

            # Prioritas 2: Jika tidak ada kata kunci, cari baris strip '-' di bawah parent ini
            if not best_sub_id:
                for cid, data in cat_by_id.items():
                    if data['parent_id'] == target_parent_id and (data['name'].strip() == '-' or data['code'].endswith('0')):
                        best_sub_id = cid
                        break

            # Eksekusi jika berbeda
            if best_sub_id and best_sub_id != current_id:
                cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (best_sub_id, exp_id))
                updated_count += 1

        conn.commit()
        print(f"✅ BERHASIL: {updated_count} data telah dikembalikan ke 'Keluarga' yang benar (sesuai label di deskripsi).")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    strict_family_fix()
