import sys
sys.path.append('d:/2. Organize/1. Projects/MiniProjectKPI_EWI/backend')
from app import app
from routes.reports.annual import _build_annual_payload_from_db, _normalize_subtitle, _extract_expense_subcategory

ctx = app.app_context()
ctx.push()

payload = _build_annual_payload_from_db(2024)
expenses = payload.get('operation_cost', {}).get('data', [])

print(f"Total expenses: {len(expenses)}")

batch_expenses = [e for e in expenses if e.get('settlement_type') == 'batch']
print(f"Batch expenses: {len(batch_expenses)}")

# tampilkan hasil kembalian _extract_expense_subcategory untuk beberapa item batch
import json
print("\nSample batch items Subcategories mapped by annual.py:")
for e in batch_expenses[:5]:
    desc = e.get('description', '')
    cat = e.get('category_name', '')
    extracted = _extract_expense_subcategory(e)
    print(f"  [{e['id']}] Desc: {desc[:30]:<30} | Cat: {cat[:20]:<20} | Extracted: '{extracted}'")

template_subtitles = [
    "Gaji Januari 2024_Yufitri",
    "ALFA Service PDP-075 Pertamina Zona#4 - Rental Tool",
    "Data proccesing MTD 4 well, project Tomori-Alan"
]
print("\nTemplate normalize subtitle testing:")
for t in template_subtitles:
    norm = _normalize_subtitle(t)
    print(f"  '{t}' -> '{norm}'")

