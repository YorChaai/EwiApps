
import sys
import os

# Tambahkan path backend ke sys.path agar bisa import models
backend_path = os.path.abspath('backend')
if backend_path not in sys.path:
    sys.path.append(backend_path)

from app import create_app
from models import db, Revenue, Tax, Expense, Settlement, Category
from sqlalchemy import text as sql_text

app = create_app()

def _get_tagged_ids(table_name, year):
    try:
        rows = db.session.execute(
            sql_text("SELECT row_id FROM report_entry_tags WHERE table_name = :t AND report_year = :y"),
            {'t': table_name, 'y': year}
        ).fetchall()
        return [int(r[0]) for r in rows]
    except Exception:
        return []

def check_data_2024():
    with app.app_context():
        year = 2024
        print(f"=== ANALISIS DATA TAHUN {year} ===")

        # 1. CEK REVENUE
        all_revenues = Revenue.query.all()
        rev_2024_all = [r for r in all_revenues if r.invoice_date and r.invoice_date.year == year]

        tagged_rev_ids = _get_tagged_ids('revenues', year)

        print(f"\n[REVENUE]")
        print(f"Total Revenue di DB untuk {year}: {len(rev_2024_all)}")

        if tagged_rev_ids:
            print(f"Ada TAGS untuk revenue (hanya ID ini yang masuk report): {len(tagged_rev_ids)} IDs")
            rev_in_report = [r for r in rev_2024_all if r.id in tagged_rev_ids]
            rev_excluded = [r for r in rev_2024_all if r.id not in tagged_rev_ids]

            print(f"Revenue yang MASUK report: {len(rev_in_report)}")
            print(f"Revenue yang TERBUANG (karena tidak di-tag): {len(rev_excluded)}")
        else:
            print("Tidak ada tags, semua data 2024 masuk report.")

        # 2. CEK TAX
        all_taxes = Tax.query.all()
        tax_2024_all = [t for t in all_taxes if t.date and t.date.year == year]

        tagged_tax_ids = _get_tagged_ids('taxes', year)

        print(f"\n[TAX]")
        print(f"Total Tax di DB untuk {year}: {len(tax_2024_all)}")

        if tagged_tax_ids:
            print(f"Ada TAGS untuk tax: {len(tagged_tax_ids)} IDs")
            tax_in_report = [t for t in tax_2024_all if t.id in tagged_tax_ids]
            tax_excluded = [t for t in tax_2024_all if t.id not in tagged_tax_ids]
            print(f"Tax yang MASUK report: {len(tax_in_report)}")
            print(f"Tax yang TERBUANG: {len(tax_excluded)}")
        else:
            print("Tidak ada tags, semua data tax 2024 masuk report.")

        # 3. CEK EXPENSE (OPERATIONAL COST)
        all_expenses_2024 = Expense.query.filter(db.extract('year', Expense.date) == year).all()

        expense_approved = []
        expense_rejected_or_pending = []

        for e in all_expenses_2024:
            s = Settlement.query.get(e.settlement_id)
            if s and s.status in ('approved', 'completed'):
                expense_approved.append(e)
            else:
                expense_rejected_or_pending.append(e)

        print(f"\n[EXPENSE / OPERATION COST]")
        print(f"Total Expense di DB untuk {year}: {len(all_expenses_2024)}")
        print(f"Expense MASUK (Approved/Completed): {len(expense_approved)}")
        print(f"Expense TERBUANG (Pending/Rejected/Draft): {len(expense_rejected_or_pending)}")

        if expense_rejected_or_pending:
            statuses = {}
            for e in expense_rejected_or_pending:
                s = Settlement.query.get(e.settlement_id)
                status = s.status if s else 'No Settlement'
                statuses[status] = statuses.get(status, 0) + 1
            print("Status pengeluaran yang terbuang:", statuses)

        print("\n=== RINGKASAN DATA YANG AKAN KELUAR DI EXCEL ===")
        print(f"Revenue: {len(rev_in_report) if tagged_rev_ids else len(rev_2024_all)} items")
        print(f"Tax: {len(tax_in_report) if tagged_tax_ids else len(tax_2024_all)} items")
        print(f"Expenses: {len(expense_approved)} items")

if __name__ == "__main__":
    check_data_2024()
