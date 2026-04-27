import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, AdvanceItem, Settlement, Expense, Revenue, Tax
from sqlalchemy import func, extract

def run_dual_audit():
    app = create_app()
    with app.app_context():
        # --- TABEL 1: BERDASARKAN TANGGAL AKTUAL (YEAR) ---
        print("\n" + "="*60)
        print("TABLE 1: BERDASARKAN TANGGAL AKTUAL (YEAR/CASH BASIS)")
        print("="*60)
        print(f"{'YEAR':<10} | {'SETTLE':<8} | {'KASBON':<8} | {'REVENUE':<8} | {'PAJAK':<8}")
        print("-" * 60)

        # Query Year (Actual)
        s_act = db.session.query(extract('year', Expense.date).label('y'), func.count(func.distinct(Settlement.id))).join(Expense).group_by('y').all()
        a_act = db.session.query(extract('year', AdvanceItem.date).label('y'), func.count(func.distinct(Advance.id))).join(AdvanceItem).group_by('y').all()
        r_act = db.session.query(extract('year', Revenue.invoice_date).label('y'), func.count(Revenue.id)).group_by('y').all()
        t_act = db.session.query(extract('year', Tax.date).label('y'), func.count(Tax.id)).group_by('y').all()

        # Combine
        years = sorted(list(set([int(y[0]) for y in s_act+a_act+r_act+t_act if y[0]])))
        s_map = {int(y[0]): y[1] for y in s_act if y[0]}
        a_map = {int(y[0]): y[1] for y in a_act if y[0]}
        r_map = {int(y[0]): y[1] for y in r_act if y[0]}
        t_map = {int(y[0]): y[1] for y in t_act if y[0]}

        for y in years:
            if 2020 <= y <= 2035:
                print(f"{y:<10} | {s_map.get(y,0):<8} | {a_map.get(y,0):<8} | {r_map.get(y,0):<8} | {t_map.get(y,0):<8}")

        # --- TABEL 2: BERDASARKAN TAHUN LAPORAN (REPORT YEAR/ACCRUAL) ---
        print("\n" + "="*60)
        print("TABLE 2: BERDASARKAN TAHUN LAPORAN (REPORT YEAR/ACCRUAL)")
        print("="*60)
        print(f"{'LAPORAN':<10} | {'SETTLE':<8} | {'KASBON':<8} | {'REVENUE':<8} | {'PAJAK':<8}")
        print("-" * 60)

        # Query Report Year
        s_rep = db.session.query(Settlement.report_year, func.count(Settlement.id)).group_by(Settlement.report_year).all()
        a_rep = db.session.query(Advance.report_year, func.count(Advance.id)).group_by(Advance.report_year).all()
        r_rep = db.session.query(Revenue.report_year, func.count(Revenue.id)).group_by(Revenue.report_year).all()
        t_rep = db.session.query(Tax.report_year, func.count(Tax.id)).group_by(Tax.report_year).all()

        # Combine
        r_years = sorted(list(set([y[0] for y in s_rep+a_rep+r_rep+t_rep if y[0] is not None])))
        sr_map = {y[0]: y[1] for y in s_rep if y[0]}
        ar_map = {y[0]: y[1] for y in a_rep if y[0]}
        rr_map = {y[0]: y[1] for y in r_rep if y[0]}
        tr_map = {y[0]: y[1] for y in t_rep if y[0]}

        for y in r_years:
            print(f"Laporan {y:<2} | {sr_map.get(y,0):<8} | {ar_map.get(y,0):<8} | {rr_map.get(y,0):<8} | {tr_map.get(y,0):<8}")

        print("="*60 + "\n")

if __name__ == "__main__":
    run_dual_audit()
