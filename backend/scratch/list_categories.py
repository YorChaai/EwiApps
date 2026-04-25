import psycopg2
from urllib.parse import urlparse

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def list_all_categories():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        cur.execute("""
            SELECT c.id, c.name, c.code, p.name as parent_name, c.main_group
            FROM categories c 
            LEFT JOIN categories p ON c.parent_id = p.id 
            ORDER BY c.id
        """)
        results = cur.fetchall()
        
        md_content = "# Daftar Lengkap Mapping Kategori (ID -> Nama)\n\n"
        md_content += "| ID | Nama | Kode | Parent (Induk) | Tipe | Grup Utama |\n"
        md_content += "| :--- | :--- | :--- | :--- | :--- | :--- |\n"
        
        for r in results:
            cat_id, name, code, parent, main_group = r
            cat_type = "Subkategori" if parent else "Kategori Induk"
            md_content += f"| {cat_id} | {name} | {code} | {parent or '-'} | {cat_type} | {main_group or '-'} |\n"

        with open("MAPPING_KATEGORI.md", "w", encoding="utf-8") as f:
            f.write(md_content)

        print("[+] Berhasil! Daftar mapping disimpan di MAPPING_KATEGORI.md")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    list_all_categories()
