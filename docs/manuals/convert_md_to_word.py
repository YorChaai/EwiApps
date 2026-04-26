import os
import re
import subprocess
import sys

# Konfigurasi Path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# INPUT_FILE = os.path.join(BASE_DIR, "6. skripsi 1-5.md")
# OUTPUT_FILE = os.path.join(BASE_DIR, "Skripsi_Full_Selesai.docx")
INPUT_FILE = os.path.join(BASE_DIR, "CHECKLIST_UJI_MANUAL_REVISI2.md")
OUTPUT_FILE = os.path.join(BASE_DIR, "CHECKLIST_UJI_MANUAL_REVISI2.docx")
PANDOC_PATH = r"C:\Users\diofa\AppData\Local\Pandoc\pandoc.exe"

def fix_table_separators(content):
    """
    Memperbaiki separator tabel markdown yang tidak valid.
    Mengubah |-| atau | -- | menjadi |---| agar dikenali Pandoc.
    """
    fixed_lines = []
    lines = content.splitlines()
    
    count_fixed = 0
    
    for line in lines:
        stripped = line.strip()
        # Cek apakah baris ini adalah separator tabel (hanya berisi |, -, :, spasi)
        if stripped.startswith('|') and stripped.endswith('|') and len(stripped) > 2:
            inner_content = stripped[1:-1]
            # Jika karakter di dalamnya hanya simbol separator tabel
            if all(c in '-|: ' for c in inner_content):
                # Hitung jumlah kolom
                cols = stripped.count('|') - 1
                if cols > 0:
                    # Buat separator standar |---|---|
                    new_sep = '|' + '---|' * cols
                    
                    # Jika separator aslinya beda dengan yang baru, berarti kita fix
                    if stripped.replace(" ", "") != new_sep.replace(" ", ""):
                        fixed_lines.append(new_sep)
                        count_fixed += 1
                        continue
        
        fixed_lines.append(line)
    
    print(f"✅ Berhasil memperbaiki {count_fixed} baris tabel.")
    return '\n'.join(fixed_lines)

def main():
    print(f"📂 Input: {INPUT_FILE}")
    
    if not os.path.exists(INPUT_FILE):
        print(f"❌ File tidak ditemukan: {INPUT_FILE}")
        return

    # 1. Baca File
    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    # 2. Perbaiki Tabel
    print("🛠️  Memeriksa dan memperbaiki format tabel...")
    fixed_content = fix_table_separators(content)

    # 3. Simpan ke File Temporary
    temp_file = os.path.join(BASE_DIR, "temp_for_convert.md")
    with open(temp_file, 'w', encoding='utf-8') as f:
        f.write(fixed_content)

    # 4. Jalankan Pandoc
    print("docx  Mengkonversi ke Word (proses ini mungkin memakan waktu)...")
    try:
        cmd = [
            PANDOC_PATH,
            temp_file,
            '-f', 'markdown+pipe_tables',
            '-o', OUTPUT_FILE
        ]
        subprocess.run(cmd, check=True)
        print(f"✅ SUKSES! File Word tersimpan di:\n   {OUTPUT_FILE}")
    except subprocess.CalledProcessError as e:
        print(f"❌ Gagal menjalankan Pandoc: {e}")
    except FileNotFoundError:
        print(f"❌ Pandoc tidak ditemukan di: {PANDOC_PATH}")
    finally:
        # Bersihkan file temp
        if os.path.exists(temp_file):
            os.remove(temp_file)

if __name__ == "__main__":
    main()
