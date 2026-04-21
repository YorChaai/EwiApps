import os
from flask import current_app

def delete_evidence_file(file_path):
    """
    Menghapus file lampiran dari storage secara aman.
    file_path: path relatif yang tersimpan di database (misal: 'receipts/2025/02/xxx.jpg')
    """
    if not file_path:
        return False

    try:
        full_path = os.path.join(current_app.config['UPLOAD_FOLDER'], file_path)
        if os.path.exists(full_path):
            os.remove(full_path)
            return True
    except Exception as e:
        print(f"⚠️ Gagal menghapus file {file_path}: {e}")

    return False
