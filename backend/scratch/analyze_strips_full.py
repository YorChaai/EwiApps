import psycopg2
from urllib.parse import urlparse
import os

db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

def analyze_all_strips():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai audit menyeluruh item strip...")

        # 1. Cari Kategori Strip
        cur.execute("""
            SELECT id, name, code, parent_id 
            FROM categories 
            WHERE name ~ '^[ -]+$' OR code ~ '^[ -]+$' OR name = '0' OR code = '0'
        """)
        strip_cats = cur.fetchall()
        strip_cat_ids = [c[0] for c in strip_cats]
        
        md_content = "# Laporan Analisis Semua Kategori Strip (-)\n\n"
        md_content += "Berikut adalah rincian pengeluaran yang menggunakan sub-kategori strip atau kode '0' di seluruh grup kategori.\n\n"

        if not strip_cat_ids:
            md_content += "⚠️ **Peringatan:** Tidak ditemukan kategori yang secara eksplisit bernama '-' atau '0'.\n"
        else:
            # Cari item di EXPENSES (Settlement)
            query_expenses = f"""
                SELECT 
                    s.title as settlement_title,
                    p.name as kategori_induk,
                    c.code as kode_sub,
                    c.name as nama_sub,
                    e.description,
                    e.amount,
                    e.date,
                    e.id as expense_id
                FROM expenses e
                JOIN settlements s ON e.settlement_id = s.id
                JOIN categories c ON e.category_id = c.id
                LEFT JOIN categories p ON c.parent_id = p.id
                WHERE e.category_id IN ({",".join(map(str, strip_cat_ids))})
                ORDER BY s.title, e.date
            """
            cur.execute(query_expenses)
            expense_rows = cur.fetchall()

            # Cari item di EXPENSES (via M2M subcategories)
            query_expenses_m2m = f"""
                SELECT 
                    s.title as settlement_title,
                    p.name as kategori_induk,
                    c.code as kode_sub,
                    c.name as nama_sub,
                    e.description,
                    e.amount,
                    e.date,
                    e.id as expense_id
                FROM expenses e
                JOIN settlements s ON e.settlement_id = s.id
                JOIN expense_subcategories es ON e.id = es.expense_id
                JOIN categories c ON es.category_id = c.id
                LEFT JOIN categories p ON c.parent_id = p.id
                WHERE es.category_id IN ({",".join(map(str, strip_cat_ids))})
                ORDER BY s.title, e.date
            """
            cur.execute(query_expenses_m2m)
            expense_m2m_rows = cur.fetchall()

            # Gabungkan dan hilangkan duplikat
            all_expenses = {}
            for r in expense_rows + expense_m2m_rows:
                all_expenses[r[7]] = r # r[7] is expense_id

            grand_total = sum(r[5] for r in all_expenses.values())
            md_content += f"# GRAND TOTAL SELURUH STRIP: Rp {grand_total:,.0f}\n\n"

            if not all_expenses:
                md_content += "✅ **Bagus!** Tidak ditemukan pengeluaran (Settlement) yang menggunakan kategori strip.\n\n"
            else:
                md_content += f"## Rincian Item di Settlement ({len(all_expenses)} item)\n\n"
                current_settlement = ""
                for exp_id in sorted(all_expenses.keys()):
                    settlement, parent, sub_code, sub_name, desc, amount, date, _ = all_expenses[exp_id]
                    
                    if settlement != current_settlement:
                        md_content += f"### Settlement: {settlement}\n"
                        md_content += "| Tanggal | Induk | Kode | Deskripsi | Amount |\n"
                        md_content += "| :--- | :--- | :--- | :--- | :--- |\n"
                        current_settlement = settlement
                    
                    md_content += f"| {date} | {parent or '-'} | {sub_code} | {desc} | Rp {amount:,.0f} |\n"
                md_content += "\n"

            # 2. Cari di ADVANCES (Kasbon)
            query_advances = f"""
                SELECT 
                    a.title as advance_title,
                    p.name as kategori_induk,
                    c.code as kode_sub,
                    c.name as nama_sub,
                    ai.description,
                    ai.estimated_amount,
                    ai.date,
                    ai.id as item_id
                FROM advance_items ai
                JOIN advances a ON ai.advance_id = a.id
                JOIN categories c ON ai.category_id = c.id
                LEFT JOIN categories p ON c.parent_id = p.id
                WHERE ai.category_id IN ({",".join(map(str, strip_cat_ids))})
                ORDER BY a.title, ai.date
            """
            cur.execute(query_advances)
            advance_rows = cur.fetchall()

            if advance_rows:
                md_content += f"## Rincian Item di Kasbon (Advance) ({len(advance_rows)} item)\n\n"
                current_advance = ""
                for r in advance_rows:
                    title, parent, sub_code, sub_name, desc, amount, date, _ = r
                    if title != current_advance:
                        md_content += f"### Kasbon: {title}\n"
                        md_content += "| Tanggal | Induk | Kode | Deskripsi | Amount |\n"
                        md_content += "| :--- | :--- | :--- | :--- | :--- |\n"
                        current_advance = title
                    md_content += f"| {date} | {parent or '-'} | {sub_code} | {desc} | Rp {amount:,.0f} |\n"

        with open("ANALISIS_STRIP_LENGKAP.md", "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] Selesai! Laporan dibuat di ANALISIS_STRIP_LENGKAP.md")
        conn.close()
    except Exception as e:
        print(f"[!] Error: {e}")

if __name__ == "__main__":
    analyze_all_strips()
