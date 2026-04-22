import os
import shutil
import sqlite3
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

        # Lokasi database asli (di folder backend)
        source_db = os.path.join(BASE_DIR, 'database.db')
        if not os.path.exists(source_db):
            return jsonify({'error': 'File database tidak ditemukan'}), 404

        # Nama file dengan timestamp
        target_filename = f"database_{timestamp}.db"
        target_path = os.path.join(target_dir, target_filename)

        # Proses Copy
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

    # Simpan sementara di folder data
    temp_path = os.path.join(base_data_dir, 'temp_import.db')
    file.save(temp_path)

    try:
        # Cek apakah ini file SQLite valid
        conn = sqlite3.connect(temp_path)
        cursor = conn.cursor()

        # Ambil daftar tabel
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in cursor.fetchall() if t[0] not in ('sqlite_sequence',)]

        summary = []
        for table in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                summary.append({
                    'table': table,
                    'rows': count
                })
            except:
                continue

        conn.close()

        return jsonify({
            'message': 'Preview database berhasil dimuat.',
            'summary': summary,
            'filename': file.filename
        })
    except Exception as e:
        if os.path.exists(temp_path):
            os.remove(temp_path)
        return jsonify({'error': f'File tidak valid atau bukan database SQLite: {str(e)}'}), 400


@settings_bp.route('/db/import-confirm', methods=['POST'])
@jwt_required()
def import_database_confirm():
    try:
        from config import BASE_DIR
        base_data_dir = current_app.config.get('UPLOAD_FOLDER', os.path.join(BASE_DIR, '..', 'data'))
        temp_path = os.path.join(base_data_dir, 'temp_import.db')

        if not os.path.exists(temp_path):
            return jsonify({'error': 'File import tidak ditemukan. Silakan unggah ulang.'}), 404

        target_db = os.path.join(BASE_DIR, 'database.db')

        # 1. Putus semua koneksi aktif ke database
        db.session.remove()
        db.engine.dispose()

        # 2. Backup database lama sebagai pencegahan (extra safety)
        if os.path.exists(target_db):
            backup_path = target_db + '.bak'
            shutil.copy2(target_db, backup_path)

        # 3. Ganti database utama dengan file temp
        # Gunakan copy + remove agar lebih aman antar drive jika perlu
        shutil.copy2(temp_path, target_db)
        os.remove(temp_path)

        return jsonify({
            'message': 'Database berhasil dipulihkan (Restore). Sistem sekarang menggunakan data baru.'
        })
    except Exception as e:
        return jsonify({'error': f'Gagal mengganti database: {str(e)}'}), 500
