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

    # 3. Cari database SQLite lama (Cari di tempat biasa atau di folder backup)
    sqlite_path = os.path.join(os.path.dirname(__file__), "database.db")
    backup_path = os.path.join(os.path.dirname(__file__), "backup_sqlite", "database_lama_sqlite_sebelum_postgres.db")

    if not os.path.exists(sqlite_path):
        if os.path.exists(backup_path):
            sqlite_path = backup_path
            print("📂 Menggunakan database sumber dari folder backup.")
        else:
            print(f"❌ ERROR: File SQLite tidak ditemukan.")
            return

    # 4. Buat tabel di PostgreSQL (jika belum ada)
    with app.app_context():
        db.create_all()
        print("✅ Tabel di PostgreSQL berhasil disiapkan.")

    # 5. Proses Pemindahan Data (menggunakan jembatan SQLAlchemy)
    # Urutan tabel sangat penting karena adanya relasi (Foreign Key)
    # Kita hapus dulu data yang mungkin ada di PG agar tidak duplikat
    tables = [
        'expenses', 'settlements', 'advance_items', 'advances',
        'notifications', 'dividend_settings', 'dividends', 'taxes',
        'revenues', 'categories', 'users'
    ]

    try:
        # Koneksi ke SQLite
        sqlite_conn = sqlite3.connect(sqlite_path)

        # Koneksi ke PostgreSQL
        pg_engine = create_engine(target_uri)

        # Hapus data lama di PG (jika ada) dalam urutan terbalik
        print("🧹 Membersihkan data contoh di PostgreSQL...")
        with pg_engine.begin() as conn:
            for table in tables:
                conn.execute(db.text(f'TRUNCATE TABLE "{table}" CASCADE'))

        # Pindahkan data (urutan dari bawah ke atas agar relasi terjaga)
        tables.reverse()

        for table in tables:
            print(f"⏳ Memindahkan tabel: {table}...")
            # Baca dari SQLite
            df = pd.read_sql_query(f"SELECT * FROM {table}", sqlite_conn)

            # Perbaikan Boolean: PostgreSQL butuh True/False, bukan 1/0
            if table == 'notifications' and 'read_status' in df.columns:
                df['read_status'] = df['read_status'].astype(bool)

            if table == 'expenses' and 'is_verified' in df.columns:
                df['is_verified'] = df['is_verified'].astype(bool)

            # Tambahkan konvensional boolean lain jika ada (misal di advance_items atau advances)
            # Kita buat loop otomatis untuk kolom yang mengandung 'is_' atau 'status' yang mungkin boolean
            for col in df.columns:
                if col.startswith('is_') or col.endswith('_status') or col == 'active':
                    try:
                        # Hanya jika kolom tersebut memang didefinisikan sebagai Boolean di Model
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
