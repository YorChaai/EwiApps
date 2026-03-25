"""
Migration script untuk tambah kolom last_login ke tabel users
Jalankan: python migrate_add_last_login.py
"""

import sqlite3
import os

# Path ke database
db_path = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'app.db')

print(f"📍 Database path: {db_path}")

try:
    # Connect ke SQLite database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Cek apakah kolom sudah ada
    cursor.execute("PRAGMA table_info(users)")
    columns = [row[1] for row in cursor.fetchall()]

    if 'last_login' in columns:
        print("✅ Kolom last_login sudah ada di tabel users")
    else:
        print("⏳ Menambahkan kolom last_login ke tabel users...")
        cursor.execute("ALTER TABLE users ADD COLUMN last_login DATETIME")
        conn.commit()
        print("✅ Kolom last_login berhasil ditambahkan!")

    conn.close()

except Exception as e:
    print(f"❌ Error: {e}")
    raise
