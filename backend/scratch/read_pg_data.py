import psycopg2
from psycopg2.extras import RealDictCursor

DB_URL = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"

def read_data():
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print("--- REVENUES (Report Year 2024) ---")
        cursor.execute("SELECT * FROM revenues WHERE report_year = 2024 ORDER BY invoice_date ASC")
        revenues = cursor.fetchall()
        for rev in revenues:
            print(f"ID: {rev['id']} | Date: {rev['invoice_date']} | Desc: {rev['description']} | Value: {rev['invoice_value']} | Year: {rev['report_year']}")
        
        print(f"\nTotal Revenues: {len(revenues)}")
        
        print("\n--- TAXES (Report Year 2024) ---")
        cursor.execute("SELECT * FROM taxes WHERE report_year = 2024 ORDER BY date ASC")
        taxes = cursor.fetchall()
        for tax in taxes:
            print(f"ID: {tax['id']} | Date: {tax['date']} | Desc: {tax['description']} | Value: {tax['transaction_value']} | Year: {tax['report_year']}")
            
        print(f"\nTotal Taxes: {len(taxes)}")
        
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    read_data()
