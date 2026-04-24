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
        # Ambil folder penyimpanan dinamis dari config
        base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))
        export_base_dir = os.path.join(base_data_dir, 'exportdb')

        # Buat timestamp untuk folder dan nama file
        now = datetime.now()
        timestamp = now.strftime("%Y-%m-%d_%H-%M-%S")
        target_dir = os.path.join(export_base_dir, timestamp)

        # Buat folder jika belum ada
        os.makedirs(target_dir, exist_ok=True)

        # Cek tipe database dari config
        db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')

        if db_uri.startswith('postgresql'):
            # EKSPOR POSTGRESQL (Menggunakan pg_dump)
            target_filename = f"database_backup_{timestamp}.sql"
            target_path = os.path.join(target_dir, target_filename)

            url = urlparse(db_uri)
            env = os.environ.copy()
            env["PGPASSWORD"] = url.password

            command = [
                'pg_dump',
                '-h', url.hostname,
                '-p', str(url.port or 5432),
                '-U', url.username,
                '-F', 'p', # Plain SQL format
                '-f', target_path,
                url.path[1:] # Nama database
            ]

            process = subprocess.run(command, env=env, capture_output=True, text=True)
            if process.returncode != 0:
                return jsonify({'error': f'Gagal pg_dump: {process.stderr}'}), 500
        else:
            # EKSPOR SQLITE (Lama)
            source_db = os.path.join(BASE_DIR, 'database.db')
            if not os.path.exists(source_db):
                return jsonify({'error': 'File database SQLite tidak ditemukan'}), 404

            target_filename = f"database_{timestamp}.db"
            target_path = os.path.join(target_dir, target_filename)
            shutil.copy2(source_db, target_path)

        return jsonify({
            'message': 'Database berhasil dieksport.',
            'path': os.path.abspath(target_path),
            'folder': timestamp
        })
    except Exception as e:
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

    # Cek tipe database
    db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')
    is_postgres = db_uri.startswith('postgresql')

    # Simpan sementara
    ext = '.sql' if is_postgres else '.db'
    temp_path = os.path.join(base_data_dir, f'temp_import{ext}')
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
    try:
        from config import BASE_DIR
        base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))
        db_uri = current_app.config.get('SQLALCHEMY_DATABASE_URI', '')
        is_postgres = db_uri.startswith('postgresql')

        ext = '.sql' if is_postgres else '.db'
        temp_path = os.path.join(base_data_dir, f'temp_import{ext}')

        if not os.path.exists(temp_path):
            return jsonify({'error': 'File import tidak ditemukan. Silakan upload ulang.'}), 404

        if is_postgres:
            # RESTORE POSTGRESQL (Menggunakan psql)
            url = urlparse(db_uri)
            env = os.environ.copy()
            env["PGPASSWORD"] = url.password

            # Perintah untuk membersihkan database dan restore
            # Kita gunakan psql -f (file)
            command = [
                'psql',
                '-h', url.hostname,
                '-p', str(url.port or 5432),
                '-U', url.username,
                '-d', url.path[1:],
                '-f', temp_path
            ]

            # Catatan: Ini akan menimpa data yang ada jika file .sql berisi perintah DROP/CREATE
            process = subprocess.run(command, env=env, capture_output=True, text=True)
            if process.returncode != 0:
                return jsonify({'error': f'Gagal restore PostgreSQL: {process.stderr}'}), 500
        else:
            # RESTORE SQLITE (Lama)
            target_db = os.path.join(BASE_DIR, 'database.db')
            shutil.copy2(temp_path, target_db)

        if os.path.exists(temp_path):
            os.remove(temp_path)

        return jsonify({'message': 'Database berhasil dipulihkan (Import Selesai).'})
    except Exception as e:
        return jsonify({'error': f'Gagal import database: {str(e)}'}), 500
