import psycopg2
from urllib.parse import urlparse

db_uri = 'postgresql://postgres:yorchai12@localhost:5432/miniproject_db'
url = urlparse(db_uri)

conn = psycopg2.connect(dbname=url.path[1:], user=url.username, password=url.password, host=url.hostname, port=url.port)
cur = conn.cursor()

query = """
    SELECT status, COUNT(*), SUM(amount)
    FROM (
        -- Dari Expenses (Settlement)
        SELECT 
            (CASE 
                WHEN c.parent_id IS NULL THEN 'INDUK_LANGSUNG'
                WHEN c.name = '-' THEN 'SUBKATEGORI_STRIP'
                ELSE 'VALID'
            END) as status,
            e.amount
        FROM expenses e
        JOIN categories c ON e.category_id = c.id
        WHERE EXTRACT(YEAR FROM e.date) = 2024
        
        UNION ALL
        
        -- Dari Advance Items (Kasbon)
        SELECT 
            (CASE 
                WHEN c.parent_id IS NULL THEN 'INDUK_LANGSUNG'
                WHEN c.name = '-' THEN 'SUBKATEGORI_STRIP'
                ELSE 'VALID'
            END) as status,
            ai.estimated_amount as amount
        FROM advance_items ai
        JOIN categories c ON ai.category_id = c.id
        WHERE EXTRACT(YEAR FROM ai.date) = 2024
    ) combined
    GROUP BY status
"""
cur.execute(query)
results = cur.fetchall()

print('PERBANDINGAN KATEGORI 2024 (SETTLEMENT + KASBON):')
total_items = 0
total_money = 0
for r in results:
    print(f'{r[0]}: {r[1]} item, Total: Rp {r[2]:,.0f}')
    total_items += r[1]
    total_money += r[2]

print('-' * 45)
print(f'GRAND TOTAL 2024: {total_items} item, Total: Rp {total_money:,.0f}')
conn.close()
