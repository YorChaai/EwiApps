
import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def fix_all_expenses():
    """
    Skrip untuk merapikan data pengeluaran yang salah kategori.
    Memindahkan data dari kategori Root (A, B, C) ke Sub-kategori (A10, B1, dll)
    berdasarkan deteksi kata kunci di deskripsi.
    """
    # Peta Kata Kunci ke Kode Kategori
    KEYWORD_MAP = {
        'sales': 'A11',
        'gaji': 'A10',
        'transport': 'A1',
        'akomodasi': 'A2',
        'accommodation': 'A2',
        'allowance': 'A3',
        'meal': 'A4',
        'makan': 'A4',
        'shipping': 'A5',
        'laundry': 'A6',
        'operation': 'A7',
        'trip': 'A8',
        'perjalanan': 'A8',
        'training': 'A9',
        'maintenance': 'A14',
        'service': 'A14',
        'bank': 'E2',
    }

    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        # Ambil map ID kategori berdasarkan kodenya
        cur.execute("SELECT code, id FROM categories")
        code_to_id = {row[0]: row[1] for row in cur.fetchall()}

        # Ambil SEMUA data pengeluaran
        cur.execute("SELECT id, description, category_id FROM expenses")
        expenses = cur.fetchall()

        print(f"Menganalisis {len(expenses)} data...")

        updated_count = 0
        for exp_id, desc, current_cat_id in expenses:
            if not desc: continue

            desc_low = desc.lower()
            target_code = None

            # Cari kata kunci di deskripsi
            for kw, code in KEYWORD_MAP.items():
                if kw in desc_low:
                    target_code = code
                    break

            if target_code and target_code in code_to_id:
                target_id = code_to_id[target_code]
                if target_id != current_cat_id:
                    cur.execute("UPDATE expenses SET category_id = %s WHERE id = %s", (target_id, exp_id))
                    updated_count += 1

        conn.commit()
        print(f"SELESAI: {updated_count} data diperbaiki.")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    fix_all_expenses()
