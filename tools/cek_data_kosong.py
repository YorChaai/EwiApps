import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, Settlement

def cek_data_kosong():
    app = create_app()
    with app.app_context():
        print(f"{'TAHUN LAPORAN':<15} | {'SETTLE KOSONG':<15} | {'KASBON KOSONG':<15}")
        print("-" * 50)

        # Ambil semua report_year yang unik dari kedua tabel
        years_stl = db.session.query(Settlement.report_year).distinct().all()
        years_adv = db.session.query(Advance.report_year).distinct().all()

        all_years = sorted(list(set(
            [y[0] for y in years_stl if y[0] is not None] +
            [y[0] for y in years_adv if y[0] is not None]
        )))

        # Tambahkan baris untuk yang report_year-nya NULL
        all_years.append(None)

        for year in all_years:
            # Hitung Settlement kosong (0 expense) untuk tahun ini
            stl_empty = Settlement.query.filter_by(report_year=year).filter(~Settlement.expenses.any()).count()

            # Hitung Kasbon kosong (0 item) untuk tahun ini
            adv_empty = Advance.query.filter_by(report_year=year).filter(~Advance.items.any()).count()

            year_display = str(year) if year is not None else "Tanpa Tahun"

            if stl_empty > 0 or adv_empty > 0:
                print(f"{year_display:<15} | {stl_empty:<15} | {adv_empty:<15}")

        print("-" * 50)
        total_stl_empty = Settlement.query.filter(~Settlement.expenses.any()).count()
        total_adv_empty = Advance.query.filter(~Advance.items.any()).count()
        print(f"{'TOTAL KESELURUHAN':<15} | {total_stl_empty:<15} | {total_adv_empty:<15}")

if __name__ == "__main__":
    cek_data_kosong()
