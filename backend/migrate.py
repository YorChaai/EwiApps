import os
from flask_migrate import Migrate
from app import create_app
from models import db

app = create_app()
migrate = Migrate(app, db)

if __name__ == '__main__':
    print("Database Migration Script")
    print("-------------------------")
    print("Pilih opsi:")
    print("1. Inisialisasi folder migrasi (hanya 1x di awal)")
    print("2. Buat file migrasi baru (setelah edit models.py)")
    print("3. Terapkan migrasi ke database (Update skema tanpa hapus data)")
    print("-------------------------")
    
    choice = input("Masukkan angka (1/2/3): ")
    
    with app.app_context():
        if choice == '1':
            print("⏳ Membuat folder migrations...")
            os.system('flask db init')
            print("✅ Selesai inisialisasi!")
        elif choice == '2':
            msg = input("Masukkan pesan migrasi (cth: 'tambah kolom catatan'): ")
            print(f"⏳ Membuat migrasi: {msg}")
            os.system(f'flask db migrate -m "{msg}"')
            print("✅ File migrasi berhasil dibuat!")
            print("💡 Sekarang pilih Opsi 3 untuk menerapkan perubahannya.")
        elif choice == '3':
            print("⏳ Menerapkan struktur baru ke database...")
            os.system('flask db upgrade')
            print("✅ Migrasi sukses! Database Anda sudah diperbarui tanpa menghilangkan data.")
        else:
            print("Pilihan tidak valid.")
