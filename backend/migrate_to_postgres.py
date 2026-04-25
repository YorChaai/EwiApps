import os
import sqlite3
import pandas as pd
from sqlalchemy import create_engine
from app import create_app
from models import db

def migrate_data():
    """
    Script otomatis untuk memindahkan data dari SQLite ke PostgreSQL.
    Langkah-langkah:
    1. Pastikan PostgreSQL sudah diinstall dan DATABASE_URL di .env sudah benar.
    2. Jalankan script ini: python migrate_to_postgres.py
    """
    # 1. Load aplikasi
    app = create_app()

    # 2. Periksa apakah kita sedang pakai PostgreSQL
    target_uri = app.config['SQLALCHEMY_DATABASE_URI']
    if not target_uri.startswith('postgresql'):
        print("❌ ERROR: DATABASE_URL di .env harus diawali dengan 'postgresql://'")
        print("Silakan install PostgreSQL dulu dan ganti alamatnya di .env.")
        return

    print(f"🚀 Memulai migrasi ke: {target_uri}")

    # 3. Cari database SQLite lama
    sqlite_path = r"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\backup_sqlite\database_lama_sqlite_sebelum_postgres.db"

    if not os.path.exists(sqlite_path):
        print(f"❌ ERROR: File SQLite tidak ditemukan di {sqlite_path}")
        return

    print(f"📂 Menggunakan database sumber: {sqlite_path}")

    # 4. Buat tabel di PostgreSQL (jika belum ada)
    with app.app_context():
        db.create_all()
        print("✅ Tabel di PostgreSQL berhasil disiapkan.")

    # 5. Proses Pemindahan Data
    tables = [
        'expenses', 'settlements', 'advance_items', 'advances',
        'notifications', 'dividend_settings', 'dividends', 'taxes',
        'revenues', 'categories', 'users'
    ]

    try:
        sqlite_conn = sqlite3.connect(sqlite_path)
        pg_engine = create_engine(target_uri)

        print("🧹 Membersihkan data di PostgreSQL...")
        with pg_engine.begin() as conn:
            for table in tables:
                conn.execute(db.text(f'TRUNCATE TABLE "{table}" CASCADE'))

        tables.reverse()

        for table in tables:
            print(f"⏳ Memindahkan tabel: {table}...")
            df = pd.read_sql_query(f"SELECT * FROM {table}", sqlite_conn)

            # --- HANDLING KHUSUS TABEL EXPENSES ---
            if table == 'expenses':
                # idr_amount adalah hybrid_property, bukan kolom fisik di DB
                if 'idr_amount' in df.columns:
                    df = df.drop(columns=['idr_amount'])

                # Pastikan kolom status tidak null
                if 'status' in df.columns:
                    df['status'] = df['status'].fillna('approved')

            # --- HANDLING KHUSUS TABEL ADVANCE_ITEMS ---
            if table == 'advance_items':
                # idr_amount juga hybrid_property di sini
                if 'idr_amount' in df.columns:
                    df = df.drop(columns=['idr_amount'])
            # --- HANDLING KHUSUS TABEL CATEGORIES ---
            if table == 'categories':
                 if 'status' in df.columns:
                    df['status'] = df['status'].fillna('approved')

            # Perbaikan Boolean
            for col in df.columns:
                if col in ['read_status', 'is_verified']:
                     df[col] = df[col].astype(bool)
                elif col.startswith('is_'):
                    try:
                        df[col] = df[col].map({1: True, 0: False, None: None})
                    except:
                        pass

            # Tulis ke PostgreSQL
            df.to_sql(table, pg_engine, if_exists='append', index=False)
            print(f"✅ Tabel {table} selesai dipindah.")

        # 6. RESET SEQUENCES (SANGAT PENTING UNTUK POSTGRES)
        # Ini agar saat tambah data baru, ID-nya tidak tabrakan (Duplicate Key Error)
        print("\n🔄 Mereset urutan ID (Sequences) agar tidak tabrakan...")
        with pg_engine.begin() as conn:
            for table in tables:
                try:
                    # Mencari nama kolom ID (biasanya 'id') dan mengupdate nomor urut terakhir
                    query = f"SELECT setval(pg_get_serial_sequence('\"{table}\"', 'id'), COALESCE(MAX(id), 1)) FROM \"{table}\""
                    conn.execute(db.text(query))
                    print(f"✅ Urutan ID tabel {table} telah diperbarui.")
                except Exception as e:
                    # Lewati jika tabel tidak punya auto-increment ID
                    continue

        print("\n✨ MIGRASI SELESAI & DATABASE SIAP DIGUNAKAN! ✨")
        print("Aplikasi sekarang sudah bisa menambah data baru tanpa tabrakan ID.")


    except Exception as e:
        print(f"❌ Terjadi kesalahan saat migrasi: {str(e)}")
        print("Pastikan nama tabel dan kolom sudah sesuai.")

if __name__ == "__main__":
    migrate_data()
