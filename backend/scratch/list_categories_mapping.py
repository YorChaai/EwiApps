import psycopg2
from urllib.parse import urlparse

# Konfigurasi Database
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def generate_category_mapping():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Mengambil data kategori dan subkategori...")

        # Query untuk mendapatkan mapping Kategori > Subkategori
        query = """
            SELECT 
                p.name as kategori_induk,
                c.name as nama_sub,
                c.id as category_id,
                c.code as kode
            FROM categories c
            LEFT JOIN categories p ON c.parent_id = p.id
            ORDER BY kategori_induk NULLS FIRST, c.code
        """
        cur.execute(query)
        rows = cur.fetchall()

        md = "# 🗺️ MAPPING KATEGORI & ID DATABASE\n\n"
        md += "Laporan ini digunakan sebagai referensi ID untuk perbaikan data.\n\n"
        md += "| Kategori Induk | Subkategori | ID (category_id) | Kode |\n"
        md += "| :--- | :--- | :--- | :--- |\n"
        
        for r in rows:
            induk = r[0] if r[0] else "--- (INI INDUK) ---"
            md += f"| {induk} | {r[1]} | **{r[2]}** | {r[3]} |\n"

        output_file = "MAPPING_ID_KATEGORI_FINAL.md"
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] Mapping selesai: {output_file}")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    generate_category_mapping()
