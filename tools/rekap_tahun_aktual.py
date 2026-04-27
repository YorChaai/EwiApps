import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, AdvanceItem, Settlement, Expense, Revenue, Tax
from sqlalchemy import func, extract

def rekap_tahunan_lengkap():
    app = create_app()
    with app.app_context():
        print(f"{'TAHUN':<10} | {'SETTLE':<8} | {'ADV':<8} | {'REVENUE':<8} | {'PAJAK':<8}")
        print("-" * 55)

        # 1. Settlement (berdasarkan tanggal item Expense)
        settle_counts = db.session.query(
            extract('year', Expense.date).label('yr'),
            func.count(func.distinct(Settlement.id))
        ).join(Expense).group_by('yr').all()
        settle_map = {int(yr): count for yr, count in settle_counts if yr}

        # 2. Kasbon (berdasarkan tanggal AdvanceItem)
        adv_counts = db.session.query(
            extract('year', AdvanceItem.date).label('yr'),
            func.count(func.distinct(Advance.id))
        ).join(AdvanceItem).group_by('yr').all()
        adv_map = {int(yr): count for yr, count in adv_counts if yr}

        # 3. Revenue (berdasarkan invoice_date)
        rev_counts = db.session.query(
            extract('year', Revenue.invoice_date).label('yr'),
            func.count(Revenue.id)
        ).group_by('yr').all()
        rev_map = {int(yr): count for yr, count in rev_counts if yr}

        # 4. Pajak (berdasarkan date)
        tax_counts = db.session.query(
            extract('year', Tax.date).label('yr'),
            func.count(Tax.id)
        ).group_by('yr').all()
        tax_map = {int(yr): count for yr, count in tax_counts if yr}

        # Gabungkan semua tahun yang unik
        all_years = sorted(list(set(
            list(settle_map.keys()) +
            list(adv_map.keys()) +
            list(rev_map.keys()) +
            list(tax_map.keys())
        )))

        for year in all_years:
            # Batasi tampilan dari 2020 sampai 2035 agar tidak terlalu panjang
            if 2020 <= year <= 2035:
                s = settle_map.get(year, 0)
                a = adv_map.get(year, 0)
                r = rev_map.get(year, 0)
                t = tax_map.get(year, 0)
                print(f"{year:<10} | {s:<8} | {a:<8} | {r:<8} | {t:<8}")

if __name__ == "__main__":
    rekap_tahunan_lengkap()
