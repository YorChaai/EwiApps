
import subprocess
import os
from urllib.parse import urlparse

# Konfigurasi
db_uri = 'postgresql://postgres:yorchai12@localhost:5432/miniproject_db'
sql_file = r'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\data\exportdb\2026-04-25_00-17-07\backup_postgres_2026-04-25_00-17-07.sql'
psql_path = r'D:\Program Files\PostgreSQL\16\bin\psql.exe'

url = urlparse(db_uri)
env = os.environ.copy()
env['PGPASSWORD'] = url.password
db_name = url.path[1:]

def run_migration():
    if not os.path.exists(sql_file):
        print(f"File SQL tidak ditemukan: {sql_file}")
        return

    print(f"[*] Memulai migrasi database: {db_name}")

    # 1. Putus koneksi lain
    print("[*] Memutus koneksi aktif...")
    kill_cmd = f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '{db_name}' AND pid <> pg_backend_pid();"
    subprocess.run([psql_path, '-h', url.hostname, '-U', url.username, '-d', 'postgres', '-c', kill_cmd], env=env, capture_output=True)

    # 2. Wipe Schema
    print("[*] Membersihkan schema public...")
    wipe_cmd = 'DROP SCHEMA public CASCADE; CREATE SCHEMA public;'
    subprocess.run([psql_path, '-h', url.hostname, '-U', url.username, '-d', db_name, '-c', wipe_cmd], env=env, capture_output=True)

    # 3. Restore
    print(f"[*] Mengimpor data...")
    process = subprocess.run([psql_path, '-h', url.hostname, '-U', url.username, '-d', db_name, '-f', sql_file], env=env, capture_output=True, text=True)

    if process.returncode == 0:
        print("[+] MIGRASI SELESAI DENGAN SUKSES!")
    else:
        print(f"[!] GAGAL RESTORE:\n{process.stderr}")

if __name__ == "__main__":
    run_migration()
