
import psycopg2
from urllib.parse import urlparse
import re

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# Aturan Kata Kunci per Kode Subkategori
RULES = {
    'A1': ['ticket', 'airplane', 'taxi', 'toll', 'fee', 'rental', 'transport', 'parkir', 'bensin', 'fuel', 'solar', 'mobil', 'moving', 'slickline', 'pesawat', 'train', 'gocar', 'gojek'],
    'A2': ['hotel', 'penginapan', 'mess', 'stay', 'homestay', 'lodge'],
    'A3': ['tunjangan lapangan', 'field allowance', 'allowance', 'thr', 'bonus'],
    'A4': ['makan', 'meal', 'lunch', 'dinner', 'snack', 'snak', 'aqua', 'minum', 'coffee', 'drink', 'soft drink'],
    'A6': ['laundry'],
    'A9': ['training', 'bosiet', 'survival'],
    'A10': ['gaji', 'payroll', 'raple'],
    'A11': ['sales'],
    'A12': ['wastafel', 'fabricate', 'panel', 'dummy test', 'project', 'istana', 'wika', 'lampu taman'],
    'A14': ['maintenance', 'service', 'perbaikan', 'repair', 'cuci'],
    'A16': ['electrical', 'listrik', 'pln'],

    'B1': ['alat', 'eas', 'emr', 'telemetry', 'retort', 'research', 'pembuatan'],

    'D1': ['data processing', 'log data'],
    'D2': ['license', 'software', 'google', 'subscription', 'internet'],

    'E1': ['it service', 'internet data'],
    'E2': ['bank', 'admin fee', 'transfer', 'biaya bank'],
    'E3': ['white marker', 'spidol', 'stationery', 'kertas', 'atk', 'office', 'materai', 'snappy', 'printing'],

    'F1': ['logistic', 'pengiriman', 'kurir', 'jne', 'tiki', 'pos', 'delivery', 'baggage', 'wrapping'],
    'F2': ['gloves', 'steker', 'hand tools', 'kunci', 'tools', 'isolasi', 'lakban', 'safety'],
    'F3': ['battery', 'baterai', 'sparepart', 'accu', 'suku cadang', 'filter oil', 'part'],
    'F4': ['powerbank', 'handphone', 'hp', 'tablet', 'asus', 'starlink', 'multimeter', 'fluke', 'power station'],

    'G1': ['sewa ruangan', 'kantor', 'bbc', 'virtual office'],
    'H1': ['medical', 'kesehatan', 'obat', 'dokter', 'rs', 'rumah sakit', 'mcu', 'fisioterapi', 'konsul'],
    'I1': ['modal kerja', 'pendanaan']
}

def run_strict_family_fix():
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        # 1. Pastikan Kategori Baru ada di DB (A16, E3, F4, I2)
        # Jika psql restore tadi menghapusnya, kita buat lagi
        new_cats = [
            (1, 'A16', 'Biaya Operasi Lain-lain'),
            (23, 'E3', 'ATK & Dokumentasi'),
            (26, 'F4', 'Elektronik & Gadget'),
            (34, 'I2', 'Lisensi & Legalitas')
        ]
        for pid, code, name in new_cats:
            cur.execute("SELECT id FROM categories WHERE code = %s", (code,))
            if not cur.fetchone():
                cur.execute("INSERT INTO categories (parent_id, code, name) VALUES (%s, %s, %s)", (pid, code, name))
        conn.commit()

        # 2. Ambil data kategori lengkap
        cur.execute("SELECT id, code, name, parent_id FROM categories")
        rows = cur.fetchall()
        cat_by_id = {r[0]: {'code': r[1], 'name': r[2], 'parent_id': r[3]} for r in rows}

        # Identifikasi kategori yang harus diperbaiki (Parent langsung atau mengandung '-')
        bad_ids = [cid for cid, d in cat_by_id.items() if d['parent_id'] is None or d['name'].strip() == '-' or d['code'].endswith('0')]

        # 3. Ambil expenses
        cur.execute("SELECT id, description, category_id FROM expenses WHERE category_id IN %s", (tuple(bad_ids),))
        expenses = cur.fetchall()

        print(f"Menganalisis {len(expenses)} item di kategori Induk/Strip...")

        updated_count = 0
        for exp_id, desc, current_id in expenses:
            if not desc: continue

            # Tentukan Keluarga Induknya
            current_cat = cat_by_id[current_id]
            parent_id = current_id if current_cat['parent_id'] is None else current_cat['parent_id']

            desc_low = desc.lower()
            best_target_id = None

            # Cari calon subkategori HANYA yang punya parent_id sama
            for cid, data in cat_by_id.items():
                if data['parent_id'] == parent_id and not data['code'].endswith('0'):
                    keywords = RULES.get(data['code'], [])
                    if any(kw in desc_low for kw in keywords):
                        best_target_id = cid
                        break

            # Eksekusi jika ditemukan yang lebih pas dalam keluarga yang sama
            if best_target_id and best_target_id != current_id:
                cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (best_target_id, exp_id))
                updated_count += 1

        conn.commit()
        print(f"✅ BERHASIL: {updated_count} data dipindahkan ke rincian yang tepat.")
        print(f"PENTING: Tidak ada data yang keluar dari keluarga Induk aslinya.")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_strict_family_fix()
