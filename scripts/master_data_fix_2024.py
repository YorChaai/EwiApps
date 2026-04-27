import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, Settlement, Revenue, Tax, Dividend, Expense, AdvanceItem
from sqlalchemy import text, extract

def run_fix():
    app = create_app()
    with app.app_context():
        print("--- MEMULAI MASTER DATA FIX 2024 ---")

        # 1. Pastikan kolom report_year ada di semua tabel (Migration Manual)
        tables_to_check = ['revenues', 'taxes', 'dividends']
        for table in tables_to_check:
            try:
                db.session.execute(text(f"ALTER TABLE {table} ADD COLUMN report_year INTEGER"))
                db.session.commit()
                print(f"Berhasil menambah kolom report_year ke tabel {table}")
            except Exception as e:
                db.session.rollback()
                if "duplicate column name" in str(e).lower() or "already exists" in str(e).lower():
                    print(f"Kolom report_year sudah ada di tabel {table}")
                else:
                    print(f"Gagal menambah kolom ke {table}: {e}")

        # 2. LOGIKA KONSOLIDASI 2024 (Data 2022, 2023, 2024 -> Laporan 2024)
        print("\n--- MENJALANKAN LOGIKA KONSOLIDASI 2024 ---")

        # A. Settlement & Advance (Berdasarkan report_year saat ini atau tanggal item)
        # Update report_year ke 2024 jika tanggal kuitansinya 2022-2024
        # Atau jika report_year saat ini adalah 2030 (Data Cleaning)

        def consolidate_model(model_cls, date_field):
            # Case 1: report_year is 2030 or null, and date is 2022-2024
            # Case 2: date is 2030
            # Kita fokus ke Logika: Semua yang tanggal aktualnya 2022, 2023, 2024 MASUK Laporan 2024
            items = model_cls.query.all()
            count = 0
            for item in items:
                # Ambil tahun dari kuitansi
                actual_date = getattr(item, date_field)
                actual_year = actual_date.year if actual_date else None

                old_report_year = item.report_year

                # Rule 1: 2022-2024 -> Laporan 2024
                if actual_year in [2022, 2023, 2024]:
                    item.report_year = 2024
                # Rule 2: 2030 -> Laporan 2024 (Data Cleaning as requested)
                elif actual_year == 2030 or old_report_year == 2030:
                    item.report_year = 2024
                # Rule 3: Jika kosong, isi sesuai tahun aktual
                elif item.report_year is None and actual_year:
                    item.report_year = actual_year

                if item.report_year != old_report_year:
                    count += 1

            db.session.commit()
            return count

        # Settlement (Cek dari Expenses)
        # Untuk Settlement dan Advance, kita harus hati-hati karena report_year ada di level header.
        # Kita ambil tahun minimal dari item-itemnya.

        def fix_headers(header_cls, item_relation, date_attr):
            headers = header_cls.query.all()
            count = 0
            for h in headers:
                items = getattr(h, item_relation)
                if not items:
                    # Jika kosong dan report_year nyasar, pindahkan ke 2024
                    if h.report_year == 2030 or h.report_year is None:
                        h.report_year = 2024
                        count += 1
                    continue

                # Cari tahun paling dominan atau tahun pertama
                actual_years = [getattr(i, date_attr).year for i in items if getattr(i, date_attr)]
                if not actual_years:
                    continue

                min_year = min(actual_years)
                old_year = h.report_year

                if any(y in [2022, 2023, 2024] for y in actual_years) or h.report_year == 2030:
                    h.report_year = 2024
                elif h.report_year is None:
                    h.report_year = min_year

                if h.report_year != old_year:
                    count += 1
            db.session.commit()
            return count

        c1 = fix_headers(Settlement, 'expenses', 'date')
        print(f"Settlement diperbarui: {c1}")

        c2 = fix_headers(Advance, 'items', 'date')
        print(f"Advance diperbarui: {c2}")

        c3 = consolidate_model(Revenue, 'invoice_date')
        print(f"Revenue diperbarui: {c3}")

        c4 = consolidate_model(Tax, 'date')
        print(f"Tax diperbarui: {c4}")

        c5 = consolidate_model(Dividend, 'date')
        print(f"Dividend diperbarui: {c5}")

        print("\n--- MASTER DATA FIX SELESAI ---")

if __name__ == "__main__":
    run_fix()
