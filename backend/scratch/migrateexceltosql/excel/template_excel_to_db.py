
import pd
import psycopg2
from sqlalchemy import create_engine
import os

# --- KONFIGURASI ---
EXCEL_FILE = 'data_import.xlsx' 
DB_URI = "postgresql://postgres:yorchai12@localhost:5432/miniproject_db"

def import_excel_to_db():
    if not os.path.exists(EXCEL_FILE):
        print(f"❌ File {EXCEL_FILE} tidak ditemukan.")
        return
    print(f"🚀 Membaca file: {EXCEL_FILE}")
    engine = create_engine(DB_URI)
    try:
        # Template
        print("✅ Data berhasil diimpor (Contoh template).")
    except Exception as e:
        print(f"❌ Terjadi kesalahan: {e}")

if __name__ == "__main__":
    import_excel_to_db()
