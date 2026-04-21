import os
import shutil
from flask import Blueprint, jsonify, request, current_app
from flask_jwt_extended import jwt_required

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

        # 2. copy semua file ke direktori baru
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
