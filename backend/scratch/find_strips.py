import psycopg2
from urllib.parse import urlparse
import os

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def find_strips():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Mencari kategori yang mengandung strip...")

        # 1. Cari kategori yang namanya mengandung '-' atau ' ' atau '0' atau kosong yang mencurigakan
        cur.execute("SELECT id, name, code, parent_id FROM categories WHERE name ~ '^[ -]+$' OR code ~ '^[ -]+$' OR name = '0' OR code = '0'")
        suspicious_categories = cur.fetchall()
        
        if not suspicious_categories:
            print("[-] Tidak ditemukan kategori dengan nama/kode strip murni.")
            # Coba cari yang mengandung strip tapi mungkin ada spasi lain
            cur.execute("SELECT id, name, code FROM categories WHERE name ILIKE '%-%' OR code ILIKE '%-%'")
            all_dash_cats = cur.fetchall()
            print(f"[*] Info: Ada {len(all_dash_cats)} kategori yang mengandung karakter '-' (total).")
        else:
            print(f"[+] Ditemukan {len(suspicious_categories)} kategori 'strip' murni:")
            for cat in suspicious_categories:
                print(f"    ID: {cat[0]}, Name: '{cat[1]}', Code: '{cat[2]}', Parent: {cat[3]}")

        cat_ids = [c[0] for c in suspicious_categories]
        
        if not cat_ids:
            # Jika tidak ada yang murni, coba cari yang kodenya '0' atau semacamnya yang sering dipakai untuk strip
            cur.execute("SELECT id FROM categories WHERE name = '-' OR code = '-' OR name = '0' OR code = '0'")
            cat_ids = [r[0] for r in cur.fetchall()]

        if not cat_ids:
            print("[!] Tidak ada ID kategori strip yang ditemukan. Mencoba mencari di Expense secara langsung...")
        else:
            ids_str = ",".join(map(str, cat_ids))
            
            # 2. Cari di expenses (direct category)
            query_direct = f"""
                SELECT e.id, e.description, c.name, e.amount, e.date
                FROM expenses e
                JOIN categories c ON e.category_id = c.id
                WHERE e.category_id IN ({ids_str})
            """
            cur.execute(query_direct)
            direct_items = cur.fetchall()
            print(f"[+] Ditemukan {len(direct_items)} item dengan kategori utama strip.")

            # 3. Cari di expenses (subcategories many-to-many)
            query_sub = f"""
                SELECT e.id, e.description, c.name, e.amount, e.date
                FROM expenses e
                JOIN expense_subcategories es ON e.id = es.expense_id
                JOIN categories c ON es.category_id = c.id
                WHERE es.category_id IN ({ids_str})
            """
            cur.execute(query_sub)
            sub_items = cur.fetchall()
            print(f"[+] Ditemukan {len(sub_items)} item dengan subkategori (M2M) strip.")

        # 4. Cari item yang deskripsinya mengandung '-' di bagian awal (biasanya [Kategori] - ...)
        cur.execute("SELECT id, description, amount, date FROM expenses WHERE description LIKE '%[-]%' OR description LIKE '%- -%'")
        desc_items = cur.fetchall()
        print(f"[+] Ditemukan {len(desc_items)} item dengan deskripsi mengandung strip.")

        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    find_strips()
