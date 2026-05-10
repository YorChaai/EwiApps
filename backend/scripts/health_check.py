import os
import sys
import importlib
import importlib.metadata
import socket
from pathlib import Path
from datetime import datetime

# Add backend to path so we can import things if needed
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

def get_lib_version(mod_name):
    try:
        # Try to get version using metadata
        pkg_name = mod_name.replace('_', '-')
        if mod_name == "PIL": pkg_name = "Pillow"
        if mod_name == "google.auth": pkg_name = "google-auth"
        if mod_name == "flask_jwt_extended": pkg_name = "Flask-JWT-Extended"
        
        return importlib.metadata.version(pkg_name)
    except:
        try:
            # Fallback to __version__
            mod = importlib.import_module(mod_name)
            return getattr(mod, '__version__', 'unknown')
        except:
            return None

def check_port(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(1)
        return s.connect_ex(('127.0.0.1', port)) == 0

def check_setup():
    """
    HEALTH CHECK PREMIUM: Memeriksa environment secara menyeluruh.
    """
    print("\n" + "═" * 70)
    print("🔍 AUDIT KESEHATAN SISTEM LENGKAP - MiniProject KPI EWI")
    print("═" * 70)

    # 1. INFORMASI DASAR
    print("\n[ ℹ️  INFORMASI DASAR ]")
    print(f"   📅 Waktu Audit      : {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"   🐍 Python Version   : {sys.version.split()[0]}")
    print(f"   🏠 Project Root     : {BASE_DIR}")
    
    in_venv = sys.prefix != sys.base_prefix
    print(f"   📦 Virtualenv       : {'✅ Aktif' if in_venv else '⚠️  TIDAK AKTIF (Sangat disarankan memakai venv)'}")

    # 2. AUDIT LIBRARIES (FULL)
    print("\n[ 📦 AUDIT LIBRARY & DEPEDENCY ]")
    libs = {
        "flask": "Flask",
        "flask_cors": "Flask-CORS",
        "flask_sqlalchemy": "Flask-SQLAlchemy",
        "flask_jwt_extended": "Flask-JWT-Extended",
        "werkzeug": "Werkzeug",
        "openpyxl": "Openpyxl (Excel)",
        "reportlab": "ReportLab (PDF)",
        "PIL": "Pillow (Image)",
        "psycopg2": "Psycopg2 (Postgres)",
        "pandas": "Pandas (Data)",
        "flask_limiter": "Flask-Limiter",
        "flask_mail": "Flask-Mail",
        "google.auth": "Google-Auth",
        "requests": "Requests",
        "dotenv": "Python-Dotenv"
    }

    all_libs_ok = True
    for mod_name, pkg_name in libs.items():
        ver = get_lib_version(mod_name)
        if ver:
            print(f"   ✅ {pkg_name.ljust(22)} : v{ver}")
        else:
            print(f"   ❌ {pkg_name.ljust(22)} : TIDAK DITEMUKAN!")
            all_libs_ok = False

    # 3. AUDIT KEAMANAN & ENV
    print("\n[ 🛡️  AUDIT KEAMANAN & CONFIG (.env) ]")
    from dotenv import load_dotenv
    load_dotenv(BASE_DIR / ".env")
    
    env_keys = ["SECRET_KEY", "JWT_SECRET_KEY", "DATABASE_URL", "UPLOAD_DIR"]
    env_ok = True
    for key in env_keys:
        val = os.environ.get(key)
        if not val:
            print(f"   ❌ {key.ljust(18)} : KUNCI HILANG!")
            env_ok = False
        else:
            status = "✅ OK"
            if key.endswith("_KEY"):
                if len(val) < 16 or "fixed-secure-key" in val:
                    status = "⚠️  Lemah (Ganti dengan string random panjang)"
            print(f"   {status} {key.ljust(18)}")

    # 4. AUDIT DATABASE DEEP-CHECK
    print("\n[ 🗄️  AUDIT INTEGRITAS DATABASE ]")
    db_url = os.environ.get("DATABASE_URL")
    if db_url:
        try:
            from sqlalchemy import create_engine, inspect, text
            engine = create_engine(db_url)
            with engine.connect() as conn:
                inspector = inspect(engine)
                tables = inspector.get_table_names()
                
                required_tables = ['users', 'categories', 'advances', 'settlements', 'expenses', 'revenues']
                missing_tables = [t for t in required_tables if t not in tables]
                
                if not missing_tables:
                    print(f"   ✅ Koneksi & Struktur : BERHASIL ({len(tables)} tabel ditemukan)")
                    # Cek jumlah data penting
                    user_count = conn.execute(text("SELECT count(*) FROM users")).scalar()
                    exp_count = conn.execute(text("SELECT count(*) FROM expenses")).scalar()
                    print(f"   📊 Statistik Data     : {user_count} User, {exp_count} Transaksi Pengeluaran")
                else:
                    print(f"   ❌ Tabel Hilang       : {', '.join(missing_tables)}")
                    print(f"      (Jalankan: flask db upgrade atau python app.py untuk migrasi)")
        except Exception as e:
            print(f"   ❌ Kegagalan DB       : {str(e)}")
    else:
        print("   ❌ DATABASE_URL tidak ditemukan.")

    # 5. AUDIT OPERASIONAL & NETWORK
    print("\n[ 🌐 AUDIT OPERASIONAL & NETWORK ]")
    
    # Cek Port Backend (Default 5000)
    port = 5000
    if check_port(port):
        print(f"   ✅ Server Status      : Berjalan di Port {port}")
    else:
        print(f"   💤 Server Status      : Tidak Berjalan (Normal jika memang belum di-start)")

    # Cek Writable Folders
    folders = ["uploads", "exports", "../data"]
    for f in folders:
        p = BASE_DIR / f
        if not p.exists(): p = BASE_DIR.parent / f.replace('../', '')
        
        if p.exists():
            # Check write permission
            is_writable = os.access(p, os.W_OK)
            print(f"   {'✅' if is_writable else '⚠️'}  Folder '{f.split('/')[-1]}' : {'Siap (Writable)' if is_writable else 'Hanya Baca (Read-only!)'}")
        else:
            print(f"   ❌ Folder '{f.split('/')[-1]}' : TIDAK ADA")

    print("\n" + "═" * 70)
    if all_libs_ok and env_ok:
        print("🚀 STATUS AKHIR: SEMUA SISTEM SIAP DIGUNAKAN!")
    else:
        print("⚠️  STATUS AKHIR: ADA BEBERAPA HAL YANG PERLU DIPERBAIKI (Cek tanda ❌/⚠️)")
    print("═" * 70)
    input("\nTekan Enter untuk kembali...")

if __name__ == "__main__":
    check_setup()
