import os
import sys

# Add backend to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import create_app
from models import db, Advance, AdvanceItem, Settlement, Expense, Revenue, Tax
from sqlalchemy import func, extract

def print_template_rekap():
    app = create_app()
    with app.app_context():
        # --- PREPARE DATA YEAR (ACTUAL) ---
        s_act = db.session.query(extract('year', Expense.date).label('y'), func.count(func.distinct(Settlement.id))).join(Expense).group_by('y').all()
        a_act = db.session.query(extract('year', AdvanceItem.date).label('y'), func.count(func.distinct(Advance.id))).join(AdvanceItem).group_by('y').all()
        r_act = db.session.query(extract('year', Revenue.invoice_date).label('y'), func.count(Revenue.id)).group_by('y').all()
        t_act = db.session.query(extract('year', Tax.date).label('y'), func.count(Tax.id)).group_by('y').all()

        s_map = {int(y[0]): y[1] for y in s_act if y[0]}
        a_map = {int(y[0]): y[1] for y in a_act if y[0]}
        r_map = {int(y[0]): y[1] for y in r_act if y[0]}
        t_map = {int(y[0]): y[1] for y in t_act if y[0]}

        # --- PREPARE DATA LAPORAN (REPORT YEAR) ---
        s_rep = db.session.query(Settlement.report_year, func.count(Settlement.id)).group_by(Settlement.report_year).all()
        a_rep = db.session.query(Advance.report_year, func.count(Advance.id)).group_by(Advance.report_year).all()
        r_rep = db.session.query(Revenue.report_year, func.count(Revenue.id)).group_by(Revenue.report_year).all()
        t_rep = db.session.query(Tax.report_year, func.count(Tax.id)).group_by(Tax.report_year).all()

        sr_map = {y[0]: y[1] for y in s_rep if y[0]}
        ar_map = {y[0]: y[1] for y in a_rep if y[0]}
        rr_map = {y[0]: y[1] for y in r_rep if y[0]}
        tr_map = {y[0]: y[1] for y in t_rep if y[0]}

        def print_table(data_s, data_a, data_r, data_t, is_report=False):
            print("| TAHUN | SETTLE | KASBON | REVENUE | PAJAK |")
            print("| :--- | :---: | :---: | :---: | :---: |")
            for y in range(2022, 2032):
                label = f"Laporan {y}" if is_report else str(y)
                s = data_s.get(y, 0)
                a = data_a.get(y, 0)
                r = data_r.get(y, 0)
                t = data_t.get(y, 0)

                # Highlight 2024
                if y == 2024:
                    print(f"| {'**' if not is_report else ''}{label}{'**' if not is_report else ''} | {s} | {a} | {r} | {t} |")
                else:
                    print(f"| {label} | {s} | {a} | {r} | {t} |")

        # --- FINAL OUTPUT ---
        print("\nlaporan (tahun)")
        print_table(sr_map, ar_map, rr_map, tr_map, is_report=True)

        print("\nkalo year(tahun)")
        print_table(s_map, a_map, r_map, t_map, is_report=False)
        print("")

if __name__ == "__main__":
    print_template_rekap()
