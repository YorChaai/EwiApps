import pandas as pd
import numpy as np
import datetime
import os

excel_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"

def clean_amount(val):
    if pd.isna(val): return 0.0
    if isinstance(val, (int, float)): return float(val)
    # clean string
    val_str = str(val).upper().replace('RP', '').replace(' ', '')
    val_str = val_str.replace('.', '').replace(',', '.')
    try:
        return float(val_str)
    except:
        return 0.0

try:
    df_raw = pd.read_excel(excel_path, sheet_name='Revenue-Cost_2024')

    revenues = []
    expenses = []

    mode = None
    current_expense_group = None
    current_expense_subgroup = None

    for idx, row in df_raw.iterrows():
        row_str = " ".join([str(x).upper() for x in row.values])
        if "REVENUE & TAX" in row_str:
            mode = 'REVENUE'
            continue
        elif "OPERATION COST AND OFFICE" in row_str or "PENGELUARAN" in row_str:
            mode = 'EXPENSE'
            continue

        if mode == 'REVENUE':
            date_val = row.iloc[1]
            if isinstance(date_val, (pd.Timestamp, datetime.datetime)) or (isinstance(date_val, str) and '-' in date_val and len(date_val) > 5):
                desc = str(row.iloc[3]) if pd.notna(row.iloc[3]) else ''
                inv_val = clean_amount(row.iloc[5])
                curr = str(row.iloc[6]).strip() if pd.notna(row.iloc[6]) else 'IDR'
                exc = clean_amount(row.iloc[7]) if pd.notna(row.iloc[7]) else 1.0
                inv_num = str(row.iloc[8]) if pd.notna(row.iloc[8]) else ''
                client = str(row.iloc[9]) if pd.notna(row.iloc[9]) else ''

                recv_date = row.iloc[10]
                amt_recv = clean_amount(row.iloc[11])
                ppn = clean_amount(row.iloc[12])
                pph23 = clean_amount(row.iloc[13])
                trf_fee = clean_amount(row.iloc[14])
                remark = str(row.iloc[15]) if pd.notna(row.iloc[15]) else ''

                if inv_val > 0 or amt_recv > 0:
                    revenues.append({
                        'invoice_date': date_val, 'description': desc, 'invoice_value': inv_val,
                        'currency': curr, 'currency_exchange': exc, 'invoice_number': inv_num,
                        'client': client, 'receive_date': recv_date, 'amount_received': amt_recv,
                        'ppn': ppn, 'pph_23': pph23, 'transfer_fee': trf_fee, 'remark': remark
                    })

        elif mode == 'EXPENSE':
            col1 = str(row.iloc[1]).strip()
            col3 = str(row.iloc[3]).strip()

            if col1.startswith('Expense#'):
                current_expense_group = col3
                current_expense_subgroup = None
                continue

            date_val = row.iloc[1]
            amt_val = row.iloc[5]

            if pd.isna(date_val) and pd.isna(amt_val) and col3 != 'nan' and col3 != '':
                current_expense_subgroup = col3
                continue

            if isinstance(date_val, (pd.Timestamp, datetime.datetime)) or (isinstance(date_val, str) and '-' in date_val and len(date_val) > 5):
                desc = col3
                source = str(row.iloc[4]) if pd.notna(row.iloc[4]) else ''
                amt = clean_amount(row.iloc[5])
                curr = str(row.iloc[6]).strip() if pd.notna(row.iloc[6]) else 'IDR'
                exc = clean_amount(row.iloc[7])
                if exc == 0.0: exc = 1.0

                if amt > 0:
                    expenses.append({
                        'date': date_val, 'description': desc, 'source': source,
                        'amount': amt, 'currency': curr, 'currency_exchange': exc,
                        'expense_group': current_expense_group, 'expense_subgroup': current_expense_subgroup
                    })

    df_rev = pd.DataFrame(revenues)
    df_exp = pd.DataFrame(expenses)

    print(f"Total Data Revenue Diekstrak : {len(df_rev)}")
    if len(df_rev) > 0:
        print(f"Total Invoice Value          : Rp {df_rev['invoice_value'].sum():,.2f}")
        print(f"Total Amount Received        : Rp {df_rev['amount_received'].sum():,.2f}")

    print(f"\nTotal Data Expense Diekstrak : {len(df_exp)}")
    if len(df_exp) > 0:
        print(f"Total Amount Expense (Asli)  : Rp {df_exp['amount'].sum():,.2f}")
        df_exp['amount_idr'] = df_exp['amount'] * df_exp['currency_exchange']
        print(f"Total Amount Expense (IDR)   : Rp {df_exp['amount_idr'].sum():,.2f}")

except Exception as e:
    print(f"Error: {e}")
