import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def generate_category_mapping_sorted():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Mengambil data kategori (Urut berdasarkan Kode)...")

        # Query dengan urutan berdasarkan Kode
        query = """
            SELECT 
                c.id as category_id,
                c.name as nama,
                c.code as kode,
                p.name as kategori_induk,
                (CASE WHEN p.name IS NULL THEN 'Kategori Induk' ELSE 'Subkategori' END) as tipe
            FROM categories c
            LEFT JOIN categories p ON c.parent_id = p.id
            ORDER BY 
                SUBSTRING(c.code, 1, 1), -- Urutkan huruf depannya (A, B, C)
                LENGTH(c.code),          -- Urutkan panjang kodenya
                c.code                   -- Baru alfabetis
        """
        cur.execute(query)
        rows = cur.fetchall()

        md = "# 🗺️ DAFTAR MAPPING KATEGORI (URUT KODE A-Z)\n\n"
        md += "| ID | Kode | Nama | Induk | Tipe |\n"
        md += "| :--- | :--- | :--- | :--- | :--- |\n"
        
        for r in rows:
            # r: (id, nama, kode, induk, tipe)
            induk = r[3] if r[3] else "-"
            md += f"| **{r[0]}** | `{r[2]}` | {r[1]} | {induk} | {r[4]} |\n"

        output_file = "MAPPING_KATEGORI_URUT_KODE.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Selesai! File dibuat: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    generate_category_mapping_sorted()
