import os

from dotenv import load_dotenv

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
# load dotenv
load_dotenv(os.path.join(BASE_DIR, '.env'))

class Config:
    # Membaca SECRET_KEY dari .env. Jika tidak ada, aplikasi akan tetap jalan
    # tetapi sangat disarankan untuk selalu mengaturnya di server produksi.
    SECRET_KEY = os.environ.get('SECRET_KEY', 'expense-settlement-fallback-2026')

    # URL Database (SQLite atau PostgreSQL)
    # Default tetap SQLite agar aplikasi tidak error sekarang
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', f'sqlite:///{os.path.join(BASE_DIR, "database.db")}')

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT Secret Key untuk otentikasi login
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-fallback-2026')

    # Lokasi upload file
    UPLOAD_FOLDER = os.environ.get('UPLOAD_DIR', os.path.join(BASE_DIR, '..', 'data'))
    EXPORT_FOLDER = os.path.join(BASE_DIR, 'exports')

    REPORT_DEFAULT_YEAR = int(os.environ.get('REPORT_DEFAULT_YEAR', '2024'))
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16mb max upload
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf', 'webp'}

    # Daftar domain yang diizinkan (CORS)
    ALLOWED_ORIGINS = os.environ.get('ALLOWED_ORIGINS', '*').split(',')
