
import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

# Peta Kata Kunci yang Lebih Lengkap berdasarkan screenshot user
MEGA_MAP = {
    'A1': ['ticket', 'airplane', 'taxi', 'toll', 'fee', 'rental', 'pajero', 'transport'],
    'A2': ['hotel', 'penginapan'],
    'A4': ['makan', 'meal', 'lunch', 'dinner'],
    'A7': ['fuel', 'bensin', 'solar'],
    'A10': ['gaji', 'payroll'],
    'A11': ['sales'],
    'F1': ['logistic', 'pengiriman'],
    'F2': ['gloves', 'steker', 'hand tools', 'kunci'],
    'F3': ['battery', 'baterai', 'sparepart', 'accu']
}

try:
    conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
    cur = conn.cursor()

    # Ambil map ID kategori berdasarkan kodenya
    cur.execute("SELECT code, id FROM categories")
    code_to_id = {row[0]: row[1] for row in cur.fetchall()}

    cur.execute("SELECT id, description, category_id FROM expenses")
    expenses = cur.fetchall()

    print(f"Mulai memperbaiki {len(expenses)} data berdasarkan temuan screenshot...")

    updated_count = 0
    for exp_id, desc, current_cat_id in expenses:
        if not desc: continue

        desc_low = desc.lower()
        target_code = None

        # Cek setiap kelompok kata kunci
        for code, keywords in MEGA_MAP.items():
            if any(kw in desc_low for kw in keywords):
                target_code = code
                break

        if target_code and target_code in code_to_id:
            target_id = code_to_id[target_code]
            if target_id != current_cat_id:
                cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (target_id, exp_id))
                updated_count += 1

    conn.commit()
    print(f"✅ BERHASIL: {updated_count} data pengeluaran telah dipindahkan ke sub-kategori yang spesifik.")
    conn.close()

except Exception as e:
    print(f"Error: {e}")
