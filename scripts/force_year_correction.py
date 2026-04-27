import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, Settlement, Revenue, Tax, Dividend, Expense, AdvanceItem

def force_fix_all_years():
    app = create_app()
    with app.app_context():
        print("--- MEMULAI KOREKSI TAHUN SECARA TEGAS ---")

        # Fungsi pembantu untuk menentukan Tahun Laporan sesuai aturan User
        def get_target_report_year(actual_year):
            if not actual_year: return 2024
            if actual_year <= 2024:
                return 2024
            return actual_year

        # 1. Perbaiki Settlement & Advance (Berdasarkan tahun item terlama)
        def fix_headers(model_cls, item_relation, date_attr):
            items = model_cls.query.all()
            changed = 0
            for h in items:
                rel_items = getattr(h, item_relation)
                actual_year = None
                if rel_items:
                    years = [getattr(i, date_attr).year for i in rel_items if getattr(i, date_attr)]
                    if years:
                        actual_year = min(years)
                else:
                    # Jika tidak ada item, pakai tahun created_at
                    actual_year = h.created_at.year

                target_year = get_target_report_year(actual_year)
                if h.report_year != target_year:
                    h.report_year = target_year
                    changed += 1
            db.session.commit()
            return changed

        # 2. Perbaiki Model Single (Revenue, Tax, Dividend)
        def fix_single_model(model_cls, date_attr):
            items = model_cls.query.all()
            changed = 0
            for i in items:
                actual_date = getattr(i, date_attr)
                actual_year = actual_date.year if actual_date else None
                target_year = get_target_report_year(actual_year)
                if i.report_year != target_year:
                    i.report_year = target_year
                    changed += 1
            db.session.commit()
            return changed

        print("Memproses Settlement...")
        c1 = fix_headers(Settlement, 'expenses', 'date')
        print(f"Settlement dipindahkan: {c1}")

        print("Memproses Kasbon...")
        c2 = fix_headers(Advance, 'items', 'date')
        print(f"Kasbon dipindahkan: {c2}")

        print("Memproses Revenue...")
        c3 = fix_single_model(Revenue, 'invoice_date')
        print(f"Revenue dipindahkan: {c3}")

        print("Memproses Pajak...")
        c4 = fix_single_model(Tax, 'date')
        print(f"Pajak dipindahkan: {c4}")

        print("Memproses Dividen...")
        c5 = fix_single_model(Dividend, 'date')
        print(f"Dividen dipindahkan: {c5}")

        print("\n--- KOREKSI SELESAI ---")

if __name__ == "__main__":
    force_fix_all_years()
