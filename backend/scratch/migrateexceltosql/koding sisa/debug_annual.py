import sqlite3
import json

db_path = r"d:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\database.db"

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row

expenses = conn.execute("""
    SELECT e.id, e.description, s.id as settlement_id, s.title, s.settlement_type, s.description as s_desc
    FROM expenses e
    JOIN settlements s ON e.settlement_id = s.id
    WHERE s.settlement_type = 'batch'
""").fetchall()

print(f"Total batch expenses: {len(expenses)}")

unique_settlements = {}
for e in expenses:
    if e['settlement_id'] not in unique_settlements:
        unique_settlements[e['settlement_id']] = e
        
print(f"Unique batch settlements: {len(unique_settlements)}")
for s_id, e in list(unique_settlements.items())[:5]:
    print(f"Settlement: {e['title']} - Desc: {e['s_desc']}")

conn.close()
