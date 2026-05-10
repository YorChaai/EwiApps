import secrets
import os
from pathlib import Path

def generate_secure_keys():
    """
    Script ini akan menghasilkan kunci rahasia yang sangat kuat secara otomatis
    menggunakan modul 'secrets' Python yang aman, lalu menyimpannya ke .env
    """
    print("\n" + "=" * 50)
    print("🛡️  PENYIAPAN KEAMANAN OTOMATIS (SECURITY SETUP)")
    print("=" * 50)

    # 1. Generate kunci acak (64 karakter hexadecimal)
    # Ini dibuat di komputer Anda, jadi tidak ada yang tahu kuncinya
    new_secret_key = secrets.token_hex(32)
    new_jwt_key = secrets.token_hex(32)

    env_path = Path(__file__).resolve().parent / ".env"
    
    if not env_path.exists():
        print(f"❌ Error: File .env tidak ditemukan di {env_path}")
        return

    # 2. Baca file .env
    with open(env_path, 'r') as f:
        lines = f.readlines()

    # 3. Update nilai kunci
    new_lines = []
    updated_secret = False
    updated_jwt = False

    for line in lines:
        if line.startswith("SECRET_KEY="):
            new_lines.append(f"SECRET_KEY={new_secret_key}\n")
            updated_secret = True
        elif line.startswith("JWT_SECRET_KEY="):
            new_lines.append(f"JWT_SECRET_KEY={new_jwt_key}\n")
            updated_jwt = True
        else:
            new_lines.append(line)

    # Jika baris tidak ditemukan, tambahkan di akhir
    if not updated_secret:
        new_lines.append(f"SECRET_KEY={new_secret_key}\n")
    if not updated_jwt:
        new_lines.append(f"JWT_SECRET_KEY={new_jwt_key}\n")

    # 4. Tulis kembali ke .env
    with open(env_path, 'w') as f:
        f.writelines(new_lines)

    print(f"✅ BERHASIL: Kunci keamanan baru telah dibuat secara acak.")
    print(f"📂 Lokasi File: {env_path}")
    print("-" * 50)
    print("⚠️  PENTING: Jangan berikan isi file .env kepada siapa pun.")
    print("=" * 50)
    print("\nTekan Enter untuk selesai...")
    input()

if __name__ == "__main__":
    generate_secure_keys()
