import os

from dotenv import load_dotenv

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
# load dotenv
load_dotenv(os.path.join(BASE_DIR, '.env'))

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'expense-settlement-secret-key-2026')
    SQLALCHEMY_DATABASE_URI = f'sqlite:///{os.path.join(BASE_DIR, "database.db")}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'jwt-settlement-secret-key-2026-min-32-char')
    # default directory - use relative path from backend folder
    UPLOAD_FOLDER = os.environ.get('UPLOAD_DIR', os.path.join(BASE_DIR, '..', 'data'))
    EXPORT_FOLDER = os.path.join(BASE_DIR, 'exports')
    REPORT_DEFAULT_YEAR = int(os.environ.get('REPORT_DEFAULT_YEAR', '2024'))
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16mb max upload
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf', 'webp'}
