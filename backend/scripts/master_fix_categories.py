
import psycopg2
from urllib.parse import urlparse
import re

# KONFIGURASI DATABASE
DB_URI = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"

# KAMUS KATA KUNCI (Untuk Mapping Otomatis)
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

def run_master_fix():
    url = urlparse(DB_URI)
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        print("🚀 Memulai MASTER FIX KATEGORI...")

        # 1. Pastikan Kategori Baru ada di DB
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
        cat_rows = cur.fetchall()
        cat_by_id = {r[0]: {'code': r[1], 'name': r[2], 'parent_id': r[3]} for r in cat_rows}
        code_to_id = {d['code']: cid for cid, d in cat_by_id.items()}

        # 3. Ambil SEMUA expenses yang butuh diperbaiki (Kategori Induk, kode '0', atau name '-')
        cur.execute("""
            SELECT id, description, category_id
            FROM expenses
            WHERE category_id IN (
                SELECT id FROM categories
                WHERE parent_id IS NULL OR code LIKE '%0' OR name = '-' OR name = '- -'
            )
        """)
        expenses = cur.fetchall()
        print(f"[*] Terdeteksi {len(expenses)} item yang perlu diredistribusi.")

        updated_count = 0
        for exp_id, desc, current_id in expenses:
            if not desc: continue

            desc_low = desc.lower()
            current_cat = cat_by_id[current_id]
            # Tentukan keluarga induk
            parent_id = current_id if current_cat['parent_id'] is None else current_cat['parent_id']
            parent_code = cat_by_id[parent_id]['code']

            target_code = None

            # STRATEGI 1: Cari Label dalam kurung [Label]
            match = re.search(r'\[(.*?)\]', desc)
            if match:
                label = match.group(1).lower().strip()
                # Cari subcat di bawah parent_id yang sama yang namanya mirip label
                for cid, data in cat_by_id.items():
                    if data['parent_id'] == parent_id:
                        if label in data['name'].lower() or data['name'].lower() in label:
                            target_code = data['code']
                            break

            # STRATEGI 2: Jika tidak ada Label, pakai Kamus Kata Kunci (Family Safe)
            if not target_code:
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
                    else: target_code = 'A16'
                elif parent_code == 'E':
                    if any(k in desc_low for k in ['bank', 'transfer']): target_code = 'E2'
                    elif any(k in desc_low for k in DICTIONARY['OFFICE']): target_code = 'E3'
                    else: target_code = 'E1'
                elif parent_code == 'F':
                    if any(k in desc_low for k in DICTIONARY['TRANSPORT']): target_code = 'F1'
                    elif any(k in desc_low for k in DICTIONARY['ELECTRONIC']): target_code = 'F4'
                    elif any(k in desc_low for k in DICTIONARY['TOOLS']): target_code = 'F2'
                    else: target_code = 'F3'
                elif parent_code == 'B': target_code = 'B1'
                elif parent_code == 'C': target_code = 'C1'
                elif parent_code == 'D': target_code = 'D1'
                elif parent_code == 'G': target_code = 'G1'
                elif parent_code == 'H': target_code = 'H1'
                elif parent_code == 'I': target_code = 'I1'

            # EKSEKUSI
            if target_code and target_code in code_to_id:
                tid = code_to_id[target_code]
                if tid != current_id:
                    cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (tid, exp_id))
                    updated_count += 1

        conn.commit()
        print(f"✅ SELESAI! {updated_count} item berhasil dirapikan.")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_master_fix()
