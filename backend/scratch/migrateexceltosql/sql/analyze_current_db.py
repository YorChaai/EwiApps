
import psycopg2
from urllib.parse import urlparse
import os

# Database URI from .env
db_uri = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"
url = urlparse(db_uri)

output_dir = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql"
md_path = os.path.join(output_dir, "db_analysis.md")

def analyze_db():
    try:
        conn = psycopg2.connect(
            dbname=url.path[1:],
            user=url.username,
            password=url.password,
            host=url.hostname,
            port=url.port
        )
        cur = conn.cursor()

        print("[*] Memulai analisis struktur dan data database...")

        md_content = "# 📊 Analisis Struktur & Data Database (PostgreSQL)\n\n"
        md_content += "Laporan ini merangkum isi database saat ini untuk panduan migrasi.\n\n"

        # 1. List Semua Tabel
        cur.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name
        """)
        tables = [t[0] for t in cur.fetchall()]

        md_content += "## 📋 Daftar Tabel & Jumlah Data\n"
        md_content += "| Nama Tabel | Jumlah Baris |\n"
        md_content += "| :--- | :--- |\n"

        for table in tables:
            cur.execute(f'SELECT COUNT(*) FROM "{table}"')
            count = cur.fetchone()[0]
            md_content += f"| {table} | {count} |\n"
        
        md_content += "\n---\n\n"

        # 2. Daftar Pengguna (Accounts & Roles)
        md_content += "## 👤 Daftar Pengguna (Accounts & Roles)\n"
        md_content += "Informasi akun yang terdaftar di dalam sistem.\n\n"
        cur.execute("SELECT username, full_name, role, email FROM users ORDER BY role")
        md_content += "| Username | Nama Lengkap | Role | Email |\n"
        md_content += "| :--- | :--- | :--- | :--- |\n"
        for user, name, role, email in cur.fetchall():
            md_content += f"| {user} | {name} | {role} | {email or '-'} |\n"
        md_content += "\n---\n\n"

        # 3. Analisis Tahun (Berdasarkan Tanggal Transaksi)
        md_content += "## 📅 Rentang Tahun (Actual Transaction Year)\n"
        md_content += "Tahun yang terdeteksi berdasarkan tanggal transaksi asli di dalam data.\n\n"
        
        md_content += "| Tabel | Tahun yang Tersedia |\n"
        md_content += "| :--- | :--- |\n"

        queries = {
            "expenses": "SELECT DISTINCT EXTRACT(YEAR FROM date) FROM expenses ORDER BY 1",
            "advances": "SELECT DISTINCT EXTRACT(YEAR FROM date) FROM advance_items ORDER BY 1",
            "revenues": "SELECT DISTINCT EXTRACT(YEAR FROM invoice_date) FROM revenues ORDER BY 1",
            "taxes": "SELECT DISTINCT EXTRACT(YEAR FROM date) FROM taxes ORDER BY 1",
            "dividends": "SELECT DISTINCT EXTRACT(YEAR FROM date) FROM dividends ORDER BY 1",
            "neraca (settings)": "SELECT DISTINCT year FROM dividend_settings ORDER BY 1"
        }

        for label, q in queries.items():
            cur.execute(q)
            years = [str(int(y[0])) for y in cur.fetchall() if y[0]]
            md_content += f"| {label} | {', '.join(years) if years else '-'} |\n"

        md_content += "\n---\n\n"

        # 4. Ringkasan Finansial Detail
        md_content += "## 💰 Ringkasan Finansial Detail\n\n"

        # REVENUE
        cur.execute("SELECT SUM(invoice_value) FROM revenues")
        total_revenue = cur.fetchone()[0] or 0
        md_content += f"### 🟢 Revenue (Pendapatan)\n"
        md_content += f"- **Total Nominal:** Rp {total_revenue:,.2f}\n"
        cur.execute("SELECT revenue_type, COUNT(*) FROM revenues GROUP BY revenue_type")
        for rtype, count in cur.fetchall():
            md_content += f"- **Tipe {rtype}:** {count} transaksi\n"
        md_content += "\n"

        # TAXES
        cur.execute("SELECT SUM(ppn), SUM(pph_21), SUM(pph_23), SUM(pph_26) FROM taxes")
        ppn, pph21, pph23, pph26 = cur.fetchone()
        md_content += f"### 🔴 Pajak (Taxes)\n"
        md_content += f"- **Total PPN:** Rp {(ppn or 0):,.2f}\n"
        md_content += f"- **Total PPh 21:** Rp {(pph21 or 0):,.2f}\n"
        md_content += f"- **Total PPh 23:** Rp {(pph23 or 0):,.2f}\n"
        md_content += f"- **Total PPh 26:** Rp {(pph26 or 0):,.2f}\n"
        md_content += "\n"

        # EXPENSES
        cur.execute("SELECT SUM(amount) FROM expenses")
        total_expense = cur.fetchone()[0] or 0
        md_content += f"### 💸 Pengeluaran (Expenses)\n"
        md_content += f"- **Total Seluruh Pengeluaran:** Rp {total_expense:,.2f}\n"
        cur.execute("SELECT status, COUNT(*) FROM expenses GROUP BY status")
        for status, count in cur.fetchall():
            md_content += f"- **Status {status}:** {count} item\n"
        md_content += "\n"

        # 5. Neraca (Dividend Settings)
        md_content += "## ⚖️ Komponen Neraca (Balance Sheet)\n"
        md_content += "Data saldo akun neraca dari tabel `dividend_settings`.\n\n"
        cur.execute("SELECT year, opening_cash_balance, accounts_receivable, share_capital, retained_earnings_balance FROM dividend_settings ORDER BY year DESC LIMIT 1")
        row = cur.fetchone()
        if row:
            y, cash, ar, capital, retained = row
            md_content += f"**Data Terbaru (Tahun {y}):**\n"
            md_content += f"- **Opening Cash:** Rp {cash:,.2f}\n"
            md_content += f"- **Accounts Receivable:** Rp {ar:,.2f}\n"
            md_content += f"- **Share Capital:** Rp {capital:,.2f}\n"
            md_content += f"- **Retained Earnings:** Rp {retained:,.2f}\n"
        md_content += "\n"

        # 6. Struktur Tabel Detail
        md_content += "## 🛠️ Struktur Kolom Tabel Penting\n"
        important_tables = ['revenues', 'taxes', 'expenses', 'dividend_settings', 'dividends', 'categories']
        for table in important_tables:
            md_content += f"### Tabel: `{table}`\n"
            cur.execute(f"""
                SELECT column_name, data_type, is_nullable 
                FROM information_schema.columns 
                WHERE table_name = '{table}'
                ORDER BY ordinal_position
            """)
            md_content += "| Kolom | Tipe Data | Null? |\n"
            md_content += "| :--- | :--- | :--- |\n"
            for col, dtype, null in cur.fetchall():
                md_content += f"| {col} | {dtype} | {null} |\n"
            md_content += "\n"

        with open(md_path, "w", encoding="utf-8") as f:
            f.write(md_content)

        print(f"[+] db_analysis.md diperbarui dengan data user.")
        conn.close()

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    analyze_db()
