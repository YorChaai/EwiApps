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
    EXPORT_FOLDER = os.path.join(BASE_DIR, '..', 'data', 'exports')

    REPORT_DEFAULT_YEAR = int(os.environ.get('REPORT_DEFAULT_YEAR', '2024'))
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16mb max upload
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf', 'webp'}

    # Flask-Mail configuration (Gmail SMTP)
    MAIL_SERVER = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.environ.get('MAIL_PORT', 587))
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS', 'True') == 'True'
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')  # Your Gmail
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')  # Your App Password
    MAIL_DEFAULT_SENDER = os.environ.get('MAIL_DEFAULT_SENDER', MAIL_USERNAME)

    # Google OAuth (for Google Login)
    GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID')

    # Daftar domain yang diizinkan (CORS)
    ALLOWED_ORIGINS = os.environ.get('ALLOWED_ORIGINS', '*').split(',')
