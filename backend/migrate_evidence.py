import sqlite3

def upgrade():
    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()
    
    # cek apakah kolom sudah ada
    cursor.execute("PRAGMA table_info(advance_items)")
    columns = [row[1] for row in cursor.fetchall()]
    
    if 'evidence_path' not in columns:
        print("Adding evidence_path to advance_items...")
        cursor.execute("ALTER TABLE advance_items ADD COLUMN evidence_path VARCHAR(500) DEFAULT NULL")
    
    if 'evidence_filename' not in columns:
        print("Adding evidence_filename to advance_items...")
        cursor.execute("ALTER TABLE advance_items ADD COLUMN evidence_filename VARCHAR(200) DEFAULT NULL")
        
    conn.commit()
    conn.close()
    print("Migration complete.")

if __name__ == '__main__':
    upgrade()
