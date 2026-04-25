
import psycopg2
from urllib.parse import urlparse
import re

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# Kamus Kata Kunci Super Lengkap
DICTIONARY = {
    'TRANSPORT': ['ticket', 'tiket', 'airplane', 'pesawat', 'flight', 'train', 'kereta', 'taxi', 'taksi', 'gocar', 'gojek', 'grab', 'mrt', 'krl', 'toll', 'tol', 'parkir', 'parking', 'bensin', 'fuel', 'gasoline', 'solar', 'pertamax', 'rental', 'sewa mobil', 'lalamove', 'kalog', 'jne', 'pos', 'tiki', 'courier', 'kurir', 'pengiriman', 'delivery', 'bagage', 'baggage', 'pax', 'moving', 'slickline', 'transport'],
    'ACCOMMODATION': ['hotel', 'penginapan', 'mess', 'stay', 'homestay', 'lodge', 'accommodation', 'akomodasi'],
    'ALLOWANCE': ['tunjangan', 'tunajngan', 'field allowance', 'allowance', 'thr', 'bonus', 'lapangan'],
    'MEAL': ['makan', 'meal', 'lunch', 'dinner', 'snack', 'snak', 'aqua', 'minum', 'coffee', 'coffe', 'kopi', 'drink', 'soft drink', 'buah', 'nasi', 'gorengan', 'sirop', 'es ', 'tea', 'teh'],
    'LAUNDRY': ['laundry', 'loundry'],
    'TRAINING': ['training', 'pelatihan', 'bosiet', 'survival', 'bss'],
    'GAJI': ['gaji', 'payroll', 'raple'],
    'PROJECT': ['project', 'proyek', 'wika', 'istana', 'taman', 'lampu', 'panel', 'fabricate', 'esor', 'wastafel', 'dummy test'],
    'MAINTENANCE': ['maintenance', 'service', 'perbaikan', 'repair', 'cuci', 'wash'],
    'OFFICE': ['listrik', 'pln', 'electrical', 'bill', 'internet', 'pulsa', 'data', 'materai', 'snappy', 'printing', 'atk', 'stationery', 'kertas', 'office', 'marker', 'spidol', 'white marker'],
    'TOOLS': ['tool', 'gloves', 'steker', 'hand tools', 'kunci', 'tang', 'obeng', 'isolasi', 'lakban', 'safety', 'helm', 'sepatu', 'shoes', 'masker'],
    'SPAREPART': ['battery', 'baterai', 'accu', 'sparepart', 'part', 'suku cadang', 'filter', 'oil', 'grease', 'wd 40', 'wd40', 'connection', 'nipple', 'neple', 'hose', 'pin punch'],
    'ELECTRONIC': ['hp', 'handphone', 'telepon', 'phone', 'tablet', 'asus', 'laptop', 'starlink', 'router', 'modem', 'powerbank', 'power station', 'multimeter', 'fluke', 'sanwa', 'adapter', 'cable', 'kabel', 'otg', 'jack', 'socket']
}

def ultra_mega_fix():
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        # 1. Ambil data kategori lengkap
        cur.execute("SELECT id, code, name, parent_id FROM categories")
        cat_rows = cur.fetchall()
        cat_by_id = {r[0]: {'code': r[1], 'name': r[2], 'parent_id': r[3]} for r in cat_rows}

        # Map Code ke ID untuk mempermudah pencarian target
        code_to_id = {d['code']: cid for cid, d in cat_by_id.items()}

        # 2. Identifikasi kategori yang harus diperbaiki (Induk/Strip)
        bad_ids = [cid for cid, d in cat_by_id.items() if d['parent_id'] is None or d['name'].strip() == '-' or d['code'].endswith('0')]

        # 3. Ambil SEMUA expenses di kategori bermasalah
        cur.execute("SELECT id, description, category_id FROM expenses WHERE category_id IN %s", (tuple(bad_ids),))
        expenses = cur.fetchall()

        print(f"Memulai perbaikan total untuk {len(expenses)} item...")

        updated_count = 0
        for exp_id, desc, current_id in expenses:
            if not desc: continue

            # Cari Keluarga Induk (A, B, C, D, E, F, dsb)
            curr_cat = cat_by_id[current_id]
            parent_id = current_id if curr_cat['parent_id'] is None else curr_cat['parent_id']
            parent_code = cat_by_id[parent_id]['code'] # Misal 'A'

            desc_low = desc.lower()
            target_code = None

            # LOGIKA PENCARIAN SUBKATEGORI (FAMILY-SAFE)
            # Grup A - Biaya Operasi
            if parent_code == 'A':
                if any(k in desc_low for k in DICTIONARY['TRANSPORT']): target_code = 'A1'
                elif any(k in desc_low for k in DICTIONARY['ACCOMMODATION']): target_code = 'A2'
                elif any(k in desc_low for k in DICTIONARY['ALLOWANCE']): target_code = 'A3'
                elif any(k in desc_low for k in DICTIONARY['MEAL']): target_code = 'A4'
                elif any(k in desc_low for k in DICTIONARY['LAUNDRY']): target_code = 'A6'
                elif any(k in desc_low for k in DICTIONARY['TRAINING']): target_code = 'A9'
                elif any(k in desc_low for k in DICTIONARY['GAJI']): target_code = 'A10'
                elif any(k in desc_low for k in DICTIONARY['PROJECT']): target_code = 'A12'
                elif any(k in desc_low for k in DICTIONARY['MAINTENANCE']): target_code = 'A14'
                else: target_code = 'A16' # Fallback Operasi Lain-lain

            # Grup B - R&D
            elif parent_code == 'B':
                target_code = 'B1' # Hampir semua R&D adalah pembuatan alat

            # Grup E - Administrasi
            elif parent_code == 'E':
                if any(k in desc_low for k in ['bank', 'transfer', 'fee']): target_code = 'E2'
                elif any(k in desc_low for k in DICTIONARY['OFFICE']): target_code = 'E3'
                else: target_code = 'E1'

            # Grup F - Pembelian Barang
            elif parent_code == 'F':
                if any(k in desc_low for k in DICTIONARY['TRANSPORT']): target_code = 'F1' # JNE/Kalog
                elif any(k in desc_low for k in DICTIONARY['ELECTRONIC']): target_code = 'F4'
                elif any(k in desc_low for k in DICTIONARY['TOOLS']): target_code = 'F2'
                else: target_code = 'F3' # Default Sparepart

            # Keluarga lain (G, H, I, J, dst)
            else:
                # Cari subkategori pertama yang bukan kode '0' di keluarga tersebut
                for cid, d in cat_by_id.items():
                    if d['parent_id'] == parent_id and not d['code'].endswith('0'):
                        target_code = d['code']
                        break

            # EKSEKUSI UPDATE
            if target_code and target_code in code_to_id:
                tid = code_to_id[target_code]
                if tid != current_id:
                    cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (tid, exp_id))
                    updated_count += 1

        conn.commit()
        print(f"✅ SUKSES TOTAL: {updated_count} item telah dipindahkan.")
        print(f"Database sekarang 100% bersih dari kategori Induk/Strip.")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    ultra_mega_fix()
