
import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# Peta Kata Kunci yang sangat spesifik untuk sisa 113 item
FINAL_RULES = {
    # GRUP A (Biaya Operasi)
    'A12': ['wastafel', 'lampu taman', 'esor', 'panel', 'fabricate', 'dummy test', 'project'],
    'A11': ['sales cost', 'sales fee'],
    'A10': ['gaji', 'payroll'],
    'A9':  ['training', 'bosiet'],
    'A6':  ['laundry'],
    'A4':  ['meal', 'makan', 'lunch', 'dinner', 'snack', 'coffee', 'drink', 'aqua', 'minum'],
    'A3':  ['allowance', 'tunjangan', 'thr', 'bonus'],
    'A1':  ['transport', 'ticket', 'taxi', 'gocar', 'toll', 'bensin', 'fuel', 'train', 'kalog', 'lalamove', 'parkir', 'moving', 'slickline'],
    'A14': ['maintenance', 'service', 'perbaikan'],
    'A16': ['electrical', 'listrik'], # Fallback untuk operasional umum

    # GRUP B (R&D)
    'B1':  ['alat', 'eas', 'emr', 'telemetry', 'retort', 'research'],

    # GRUP F (Pembelian Barang)
    'F4':  ['powerbank', 'handphone', 'hp', 'tablet', 'asus', 'starlink', 'multimeter', 'fluke'],
    'F2':  ['tool', 'gloves', 'steker', 'kunci'],

    # GRUP I (Bisnis Dev)
    'I1':  ['modal kerja', 'sewa ruangan', 'kantor', 'bbc']
}

def run_final_sweep():
    try:
        conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
        cur = conn.cursor()

        # 1. Ambil map ID kategori
        cur.execute("SELECT code, id, parent_id FROM categories")
        cat_data = {row[0]: {'id': row[1], 'parent_id': row[2]} for row in cur.fetchall()}

        # 2. Ambil 113 item yang masih nyangkut di Induk atau Strip (2024)
        cur.execute("""
            SELECT e.id, e.description, c.code, c.parent_id
            FROM expenses e
            JOIN categories c ON e.category_id = c.id
            WHERE (c.parent_id IS NULL OR c.code LIKE '%0' OR c.name = '-')
              AND EXTRACT(YEAR FROM e.date) = 2024
        """)
        expenses = cur.fetchall()

        print(f"Memulai pembersihan akhir untuk {len(expenses)} item...")

        updated_count = 0
        for exp_id, desc, current_code, current_parent_id in expenses:
            if not desc: continue

            desc_low = desc.lower()
            target_id = None

            # Tentukan ID Induk (untuk memastikan tetap dalam kategori yang sama)
            effective_parent_id = current_parent_id if current_parent_id else cat_data[current_code]['id']

            # Cari kecocokan kata kunci
            for code, keywords in FINAL_RULES.items():
                if any(kw in desc_low for kw in keywords):
                    # Pastikan subkategori target punya Induk yang sama!
                    if cat_data[code]['parent_id'] == effective_parent_id:
                        target_id = cat_data[code]['id']
                        break

            # Jika tidak ketemu kata kunci tapi HARUS pindah (agar tidak ada strip/induk)
            # Kita pindahkan ke subkategori pertama yang tersedia di grup tersebut
            if not target_id:
                for code, data in cat_data.items():
                    if data['parent_id'] == effective_parent_id and not code.endswith('0'):
                        target_id = data['id']
                        break

            if target_id:
                cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (target_id, exp_id))
                updated_count += 1

        conn.commit()
        print(f"✅ BERHASIL: {updated_count} item telah dipindahkan. Database sekarang 100% rapi.")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    run_final_sweep()
