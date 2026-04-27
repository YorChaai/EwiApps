import sys
import os
from sqlalchemy import func

# Add backend path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))

from app import create_app
from models import db, Revenue, Expense, Settlement, Category

app = create_app()

with app.app_context():
    print("=== RINGKASAN DATA DATABASE (POSTGRESQL) TAHUN 2024 ===")

    # 1. Total Revenue 2024
    total_rev = db.session.query(func.sum(Revenue.invoice_value)).filter(Revenue.report_year == 2024).scalar() or 0
    total_recv = db.session.query(func.sum(Revenue.amount_received)).filter(Revenue.report_year == 2024).scalar() or 0
    print(f"\n[PENDAPATAN / REVENUE 2024]")
    print(f"- Total Invoice Value   : Rp {total_rev:,.2f}")
    print(f"- Total Amount Received : Rp {total_recv:,.2f}")

    # 2. Total Expense dari Settlement "EXCEL MIGRATION 2024"
    mig_settlement = Settlement.query.filter_by(title="EXCEL MIGRATION 2024").first()
    if mig_settlement:
        print(f"\n[PENGELUARAN / EXPENSE MIGRATION (Dari Excel Asli)]")
        print(f"- ID Settlement         : {mig_settlement.id}")

        # Calculate amount IDR directly since the property might need to be evaluated in python or via query
        expenses = Expense.query.filter_by(settlement_id=mig_settlement.id).all()
        total_exp_asli = sum(e.amount for e in expenses)
        total_exp_idr = sum(e.idr_amount for e in expenses)

        print(f"- Total Item Pengeluaran: {len(expenses)} transaksi")
        print(f"- Total Nominal (Asli)  : Rp {total_exp_asli:,.2f}")
        print(f"- Total Nominal (IDR)   : Rp {total_exp_idr:,.2f}")

    # 3. Bandingkan dengan seluruh pengeluaran 2024 di sistem
    print(f"\n[PENGELUARAN KESELURUHAN 2024 DI SISTEM]")
    all_expenses = db.session.query(Expense).join(Settlement).filter(
        db.extract('year', Expense.date) == 2024,
        Expense.status == 'approved'
    ).all()
    total_all_idr = sum(e.idr_amount for e in all_expenses)
    print(f"- Total Item Pengeluaran: {len(all_expenses)} transaksi")
    print(f"- Total Nominal (IDR)   : Rp {total_all_idr:,.2f}")
