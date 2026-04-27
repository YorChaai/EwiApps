
import psycopg2
from urllib.parse import urlparse
import os

# Database URI from .env
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql"
md_path = os.path.join(output_dir, "final_recap_matrix.md")

def generate_matrix():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        # --- 1. DATA REPORT YEAR ---
        def get_report_counts(cur, table, col='report_year'):
            if table == 'dividend_settings': col = 'year'
            cur.execute(f'SELECT {col}, COUNT(*) FROM "{table}" WHERE {col} IS NOT NULL GROUP BY 1')
            return {int(row[0]): row[1] for row in cur.fetchall()}

        s_rep = get_report_counts(cur, 'settlements')
        a_rep = get_report_counts(cur, 'advances')
        r_rep = get_report_counts(cur, 'revenues')
        t_rep = get_report_counts(cur, 'taxes')
        d_rep = get_report_counts(cur, 'dividends')
        n_rep = get_report_counts(cur, 'dividend_settings')

        # --- 2. DATA ACTUAL YEAR ---
        cur.execute("SELECT EXTRACT(YEAR FROM date), COUNT(DISTINCT settlement_id) FROM expenses GROUP BY 1")
        s_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}
        cur.execute("SELECT EXTRACT(YEAR FROM date), COUNT(DISTINCT advance_id) FROM advance_items GROUP BY 1")
        a_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}
        cur.execute("SELECT EXTRACT(YEAR FROM invoice_date), COUNT(*) FROM revenues GROUP BY 1")
        r_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}
        cur.execute("SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM taxes GROUP BY 1")
        t_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}
        cur.execute("SELECT EXTRACT(YEAR FROM date), COUNT(*) FROM dividends GROUP BY 1")
        d_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}
        cur.execute("SELECT year, COUNT(*) FROM dividend_settings GROUP BY 1")
        n_act = {int(row[0]): row[1] for row in cur.fetchall() if row[0]}

        def build_table(s_map, a_map, r_map, t_map, d_map, n_map, is_report=True):
            header = "| TAHUN | SETTLE | KASBON | REVENUE | PAJAK | DEVIDEN | NERACA |\n"
            sep = "| :--- | :---: | :---: | :---: | :---: | :---: | :---: |\n"
            body = ""
            for yr in range(2020, 2036):
                label = f"Laporan {yr}" if is_report else str(yr)
                s = s_map.get(yr, 0)
                a = a_map.get(yr, 0)
                r = r_map.get(yr, 0)
                t = t_map.get(yr, 0)
                d = d_map.get(yr, 0)
                n = n_map.get(yr, 0)
                row = f"| {label} | {s} | {a} | {r} | {t} | {d} | {n} |\n"
                body += row
            return header + sep + body

        md = "# 📊 Matriks Rekapitulasi Data (2020 - 2035)\n\n"
        md += "### 📂 Laporan (Berdasarkan Tahun Laporan)\n"
        md += build_table(s_rep, a_rep, r_rep, t_rep, d_rep, n_rep, is_report=True)
        md += "\n\n### 📅 Year (Berdasarkan Tanggal Transaksi Aktual)\n"
        md += build_table(s_act, a_act, r_act, t_act, d_act, n_act, is_report=False)

        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md)

        print(f"[+] final_recap_matrix.md dipulihkan.")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    generate_matrix()
