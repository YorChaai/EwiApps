import psycopg2
from psycopg2.extras import RealDictCursor

DB_URL = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"

def duplicate_data_pg(table_name, report_year=2024, multiplier=40):
    try:
        conn = psycopg2.connect(DB_URL)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get column names (excluding 'id')
        cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = %s AND column_name != 'id'", (table_name,))
        columns = [row['column_name'] for row in cursor.fetchall()]
        cols_str = ", ".join(columns)
        
        # Query original data
        if table_name == 'expenses':
            # Special case for expenses because they don't have report_year, settlements does
            query = f"""
                SELECT {", ".join([f"e.{c}" for c in columns])} 
                FROM expenses e
                JOIN settlements s ON e.settlement_id = s.id
                WHERE s.report_year = %s
            """
            cursor.execute(query, (report_year,))
        else:
            cursor.execute(f"SELECT {cols_str} FROM {table_name} WHERE report_year = %s", (report_year,))
            
        rows = cursor.fetchall()
        
        if not rows:
            print(f"[-] No data found in {table_name} for report_year {report_year}")
            conn.close()
            return
            
        print(f"[+] Found {len(rows)} original rows in {table_name}")
        
        # Prepare data for insertion (multiplier times)
        total_to_insert = []
        for _ in range(multiplier):
            for r in rows:
                total_to_insert.append(tuple(r[c] for c in columns))
        
        # Insert data
        placeholders = ", ".join(["%s"] * len(columns))
        query = f"INSERT INTO {table_name} ({cols_str}) VALUES ({placeholders})"
        cursor.executemany(query, total_to_insert)
        
        conn.commit()
        print(f"[+] Successfully inserted {len(total_to_insert)} duplicated rows into {table_name}")
        
        # Final count
        if table_name == 'expenses':
            cursor.execute("SELECT COUNT(e.id) FROM expenses e JOIN settlements s ON e.settlement_id = s.id WHERE s.report_year = %s", (report_year,))
        else:
            cursor.execute(f"SELECT COUNT(*) FROM {table_name} WHERE report_year = %s", (report_year,))
        final_count = cursor.fetchone()['count']
        print(f"[*] Final count in {table_name} for {report_year}: {final_count}")
        
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # multiplier = 3 as requested by user ("di kali 3")
    m = 3
    print(f"[*] Starting stress test duplication ({m}x)...")
    
    # Hide revenues and taxes duplication as requested
    # duplicate_data_pg('revenues', multiplier=m)
    # duplicate_data_pg('taxes', multiplier=m)
    
    # Add expenses duplication
    duplicate_data_pg('expenses', multiplier=m)
    
    print("[*] All done!")
