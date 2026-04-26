import os
import shutil
import sqlite3
import subprocess
from urllib.parse import urlparse
from datetime import datetime
from flask import Blueprint, jsonify, request, current_app
from flask_jwt_extended import jwt_required
from models import db

settings_bp = Blueprint('settings', __name__, url_prefix='/api/settings')

@settings_bp.route('/storage', methods=['GET', 'POST'])
@jwt_required()
def manage_storage():
    if request.method == 'GET':
        return jsonify({
            'current_directory': os.path.abspath(current_app.config['UPLOAD_FOLDER']),
        })

    data = request.get_json(silent=True) or {}
    new_dir = data.get('new_directory')

    if not new_dir:
        return jsonify({'error': 'Parameter new_directory tidak boleh kosong'}), 400

    new_dir = os.path.abspath(new_dir)
    old_dir = os.path.abspath(current_app.config['UPLOAD_FOLDER'])

    if new_dir == old_dir:
        return jsonify({'message': 'Direktori baru sama dengan direktori saat ini.'})

    try:
        # 1. buat direktori baru jika belum ada
        os.makedirs(new_dir, exist_ok=True)

        # 2. copy semua file ke direktori baru (termasuk exportdb jika ada)
        if os.path.exists(old_dir):
            for item in os.listdir(old_dir):
                s = os.path.join(old_dir, item)
                d = os.path.join(new_dir, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)

        # 3. update file .env
        from config import BASE_DIR
        env_path = os.path.join(BASE_DIR, '.env')
        env_vars = {}

        # parse .env lama
        if os.path.exists(env_path):
            with open(env_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, val = line.split('=', 1)
                        env_vars[key.strip()] = val.strip()

        # update upload dir
        env_vars['UPLOAD_DIR'] = new_dir

        # simpan kembali ke .env
        with open(env_path, 'w', encoding='utf-8') as f:
            for key, val in env_vars.items():
                f.write(f"{key}={val}\n")

        # 4. update config app berjalan
        current_app.config['UPLOAD_FOLDER'] = new_dir

        return jsonify({
            'message': 'Penyimpanan berhasil dipindahkan ke lokasi baru.',
            'new_directory': new_dir
        })
    except Exception as e:
        return jsonify({'error': f'Gagal memindahkan penyimpanan: {str(e)}'}), 500


@settings_bp.route('/report-year', methods=['GET', 'POST'])
@jwt_required()
def manage_report_year():
    # get: return default report year berjalan
    # post: update default report year dan simpan ke .env
    if request.method == 'GET':
        return jsonify({
            'default_report_year': int(current_app.config.get('REPORT_DEFAULT_YEAR', 2024)),
        })

    data = request.get_json(silent=True) or {}
    year_raw = data.get('default_report_year')
    try:
        year = int(year_raw)
    except (TypeError, ValueError):
        return jsonify({'error': 'default_report_year harus berupa angka tahun'}), 400

    if year < 2000 or year > 2100:
        return jsonify({'error': 'default_report_year di luar rentang valid (2000-2100)'}), 400

    try:
        from config import BASE_DIR
        env_path = os.path.join(BASE_DIR, '.env')
        env_vars = {}

        if os.path.exists(env_path):
            with open(env_path, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, val = line.split('=', 1)
                        env_vars[key.strip()] = val.strip()

        env_vars['REPORT_DEFAULT_YEAR'] = str(year)

        with open(env_path, 'w', encoding='utf-8') as f:
            for key, val in env_vars.items():
                f.write(f'{key}={val}\n')

        current_app.config['REPORT_DEFAULT_YEAR'] = year
        return jsonify({
            'message': 'Default tahun laporan berhasil diperbarui.',
            'default_report_year': year,
        })
    except Exception as e:
        return jsonify({'error': f'Gagal menyimpan setting tahun laporan: {str(e)}'}), 500


@settings_bp.route('/db/export', methods=['POST'])
@jwt_required()
def export_database():
    try:
        from config import BASE_DIR
        # Folder utama: data/Database/Backups
        base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))
        export_base_dir = os.path.join(base_data_dir, 'Database', 'Backups')

        # Buat timestamp folder (Contoh: 2026-04-24_14-30-00)
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        target_dir = os.path.join(export_base_dir, timestamp)
        os.makedirs(target_dir, exist_ok=True)

        db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')
        exported_files = []

        # 1. EKSPOR POSTGRESQL (Jika aktif)
        if db_uri.startswith('postgresql'):
            try:
                url = urlparse(db_uri)
                env = os.environ.copy()
                env["PGPASSWORD"] = url.password

                target_sql = os.path.join(target_dir, f"backup_postgres_{timestamp}.sql")

                # Cari pg_dump: Coba di PATH dulu, kalau gagal coba jalur spesifik user
                pg_dump_path = 'pg_dump'
                potential_paths = [
                    'pg_dump',
                    r"D:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
                    r"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",
                ]

                success = False
                last_error = ""

                for path in potential_paths:
                    try:
                        command = [
                            path,
                            '-h', url.hostname,
                            '-p', str(url.port or 5432),
                            '-U', url.username,
                            '-F', 'p',
                            '-f', target_sql,
                            url.path[1:]
                        ]
                        process = subprocess.run(command, env=env, capture_output=True, text=True)
                        if process.returncode == 0:
                            exported_files.append(f"PostgreSQL (.sql)")
                            success = True
                            break
                        else:
                            last_error = process.stderr
                    except FileNotFoundError:
                        continue

                if not success and last_error:
                    print(f"[!] pg_dump error: {last_error}")
                elif not success:
                    print("[!] Error: 'pg_dump' utility not found in PATH or common locations.")

            except Exception as pe:
                print(f"[!] Unexpected PostgreSQL export error: {str(pe)}")

        if not exported_files:
            return jsonify({'error': 'Tidak ada database PostgreSQL yang bisa diekspor. Pastikan tools pg_dump terinstall.'}), 404

        return jsonify({
            'message': f'Export Berhasil: {", ".join(exported_files)}',
            'path': os.path.abspath(target_dir),
            'folder': timestamp
        })
    except Exception as e:
        print(f"[!] Global Export Exception: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Gagal eksport database: {str(e)}'}), 500


@settings_bp.route('/db/import-preview', methods=['POST'])
@jwt_required()
def import_database_preview():
    if 'file' not in request.files:
        return jsonify({'error': 'Tidak ada file yang diunggah'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'Nama file kosong'}), 400

    # Lokasi data folder saat ini
    from config import BASE_DIR
    base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))

    # Gunakan subfolder tmp agar folder data tetap bersih
    tmp_dir = os.path.join(base_data_dir, 'tmp')
    os.makedirs(tmp_dir, exist_ok=True)

    # Cek tipe database
    db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')
    is_postgres = db_uri.startswith('postgresql')

    # Simpan sementara
    ext = '.sql' if is_postgres else '.db'
    temp_path = os.path.join(tmp_dir, f'temp_import{ext}')

    # Hapus file lama jika ada
    if os.path.exists(temp_path): os.remove(temp_path)
    file.save(temp_path)

    try:
        if is_postgres:
            # PREVIEW POSTGRESQL (Sederhana: Cek ukuran file)
            file_size = os.path.getsize(temp_path) / 1024 # KB
            return jsonify({
                'message': 'File cadangan PostgreSQL terdeteksi.',
                'summary': [{'table': 'Database SQL Dump', 'rows': f'{file_size:.1f} KB'}],
                'filename': file.filename,
                'is_postgres': True
            })
        else:
            # PREVIEW SQLITE (Lama)
            conn = sqlite3.connect(temp_path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [t[0] for t in cursor.fetchall() if t[0] not in ('sqlite_sequence',)]
            summary = []
            for table in tables:
                try:
                    cursor.execute(f"SELECT COUNT(*) FROM {table}")
                    count = cursor.fetchone()[0]
                    summary.append({'table': table, 'rows': count})
                except: continue
            conn.close()
            return jsonify({
                'message': 'Preview database SQLite berhasil dimuat.',
                'summary': summary,
                'filename': file.filename,
                'is_postgres': False
            })
    except Exception as e:
        if os.path.exists(temp_path): os.remove(temp_path)
        return jsonify({'error': f'File tidak valid: {str(e)}'}), 400


@settings_bp.route('/db/import-confirm', methods=['POST'])
@jwt_required()
def import_database_confirm():
    temp_path = None
    try:
        from config import BASE_DIR
        base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))
        export_base_dir = os.path.join(base_data_dir, 'Database', 'Backups')

        db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')
        is_postgres = db_uri.startswith('postgresql')

        ext = '.sql' if is_postgres else '.db'
        temp_path = os.path.join(base_data_dir, 'tmp', f'temp_import{ext}')

        if not os.path.exists(temp_path):
            return jsonify({'error': 'File import tidak ditemukan. Silakan upload ulang.'}), 404

        # --- FOLDER RIWAYAT IMPOR (Sesuai Permintaan User) ---
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        history_dir = os.path.join(export_base_dir, f"{timestamp}(import)")
        os.makedirs(history_dir, exist_ok=True)

        # Simpan salinan file yang diimpor sebagai arsip
        archived_import_file = os.path.join(history_dir, f"file_yang_diimpor_{timestamp}{ext}")
        shutil.copy2(temp_path, archived_import_file)

        if is_postgres:
            # RESTORE POSTGRESQL
            url = urlparse(db_uri)
            env = os.environ.copy()
            env["PGPASSWORD"] = url.password

            # --- BACKUP DATA LAMA KE FOLDER RIWAYAT ---
            try:
                backup_path = os.path.join(history_dir, f"backup_data_lama_sebelum_import_{timestamp}.sql")

                pg_dump_path = 'pg_dump'
                for p in ['pg_dump', r"D:\Program Files\PostgreSQL\16\bin\pg_dump.exe", r"C:\Program Files\PostgreSQL\16\bin\pg_dump.exe"]:
                    if os.path.exists(p) or p == 'pg_dump':
                        pg_dump_path = p
                        break

                subprocess.run([
                    pg_dump_path, '-h', url.hostname, '-p', str(url.port or 5432),
                    '-U', url.username, '-F', 'p', '-f', backup_path, url.path[1:]
                ], env=env, capture_output=True)
                print(f"[*] Pre-import backup saved to: {backup_path}")
            except Exception as e:
                print(f"[!] Pre-import backup warning: {e}")

            # --- PROSES RESTORE ---
            print(f"[*] Memulai Restore PostgreSQL dari file: {temp_path}")

            # --- PENTING: TUTUP SEMUA KONEKSI FLASK AGAR TIDAK DEADLOCK ---
            from models import db
            db.session.remove()
            db.engine.dispose()
            print("[*] Koneksi internal dilepaskan untuk menghindari deadlock.")

            psql_path = 'psql'
            for p in ['psql', r"D:\Program Files\PostgreSQL\16\bin\psql.exe", r"C:\Program Files\PostgreSQL\16\bin\psql.exe"]:
                if os.path.exists(p) or p == 'psql':
                    psql_path = p
                    break

            # 1. BERSIHKAN DATABASE TERLEBIH DAHULU (Wipe Schema)
            print("[*] Membersihkan schema public lama...")
            # Tambahkan perintah untuk memutus koneksi lain yang mungkin nyangkut
            kill_conns = f"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '{url.path[1:]}' AND pid <> pg_backend_pid();"
            subprocess.run([
                psql_path, '-h', url.hostname, '-p', str(url.port or 5432),
                '-U', url.username, '-d', 'postgres', # Connect ke db 'postgres' untuk drop db target
                '-c', kill_conns
            ], env=env, capture_output=True)

            wipe_cmd = "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
            subprocess.run([
                psql_path, '-h', url.hostname, '-p', str(url.port or 5432),
                '-U', url.username, '-d', url.path[1:],
                '-c', wipe_cmd
            ], env=env, capture_output=True)

            # 2. JALANKAN RESTORE
            print("[*] Menjalankan perintah psql restore...")
            process = subprocess.run([
                psql_path, '-h', url.hostname, '-p', str(url.port or 5432),
                '-U', url.username, '-d', url.path[1:],
                '-v', 'ON_ERROR_STOP=1',
                '-f', temp_path
            ], env=env, capture_output=True, text=True)
            if process.returncode != 0:
                print(f"[!] PSQL RESTORE ERROR:\n{process.stderr}")
                return jsonify({'error': f'Gagal restore PostgreSQL: {process.stderr}'}), 500
            print("[*] Restore Selesai. Melakukan verifikasi data...")

            # --- VERIFIKASI DATA (Cek apakah tabel ada isinya) ---
            from models import db, Expense, User
            try:
                # Kita perlu me-refresh sesi database karena koneksi psql tadi di luar SQLAlchemy
                db.session.remove()
                user_count = db.session.query(db.func.count(User.id)).scalar()
                exp_count = db.session.query(db.func.count(Expense.id)).scalar()
                print(f"[+] Verifikasi Berhasil: Ditemukan {user_count} User dan {exp_count} Pengeluaran di database baru.")
                debug_info = f"Import OK. Users: {user_count}, Expenses: {exp_count}"
            except Exception as ve:
                print(f"[!] Verifikasi Gagal: {ve}")
                debug_info = f"Import selesai tapi verifikasi gagal: {str(ve)}"

        else:
            # RESTORE SQLITE (LAMA)
            target_db = os.path.join(BASE_DIR, 'database.db')
            if os.path.exists(target_db):
                backup_path = os.path.join(history_dir, f"backup_data_lama_sebelum_import_{timestamp}.db")
                shutil.copy2(target_db, backup_path)
            shutil.copy2(temp_path, target_db)
            debug_info = "SQLite Import OK"

        # Hapus file sampah
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

        return jsonify({
            'message': 'Database berhasil dipulihkan.',
            'debug': debug_info,
            'history_folder': f"{timestamp}(import)"
        })

    except Exception as e:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
        return jsonify({'error': f'Gagal import database: {str(e)}'}), 500
