
import os
import sqlite3
from datetime import datetime

# Path to database
db_path = os.path.join('backend', 'database.db')
if not os.path.exists(db_path):
    db_path = 'backend/database.db'

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
cursor = conn.cursor()

print('--- Category Structure for A ---')
cursor.execute("SELECT id, code, name, parent_id FROM categories WHERE code LIKE 'A%' OR code = 'A'")
rows = cursor.fetchall()
for row in rows:
    print(dict(row))

print('\n--- Expenses in January 2024 (Status Approved) ---')
query = """
    SELECT e.id, e.date, e.category_id, c.code, c.name as cat_name, e.description, e.idr_amount, e.amount, e.currency
    FROM expenses e
    JOIN categories c ON e.category_id = c.id
    WHERE (c.code LIKE 'A%' OR c.code = 'A')
      AND e.date >= '2024-01-01' AND e.date <= '2024-01-31'
      AND e.status = 'approved'
"""
cursor.execute(query)
expenses = cursor.fetchall()
total_jan = 0
for exp in expenses:
    total_jan += (exp['idr_amount'] or 0)
    print(dict(exp))

print(f"\nTotal Jan (Calculated): {total_jan}")
conn.close()
