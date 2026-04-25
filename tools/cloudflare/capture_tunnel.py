import subprocess
import re
import sys
import os

def run_tunnel():
    print("==================================================")
    print("   CLOUDFLARE TUNNEL AUTOMATION")
    print("==================================================")
    print("[*] Memulai tunnel... Mohon tunggu...")

    # Path ke cloudflared.exe (asumsi di folder yang sama)
    cmd = ["cloudflared.exe", "tunnel", "--url", "http://localhost:5000"]

    # Jalankan proses
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1
    )

    url_found = False

    # Baca output baris demi baris
    for line in process.stdout:
        # Print output asli ke terminal supaya tetap bisa liat log
        print(line, end="")

        # Cari pola URL trycloudflare
        if not url_found:
            match = re.search(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", line)
            if match:
                url = match.group(0)
                url_found = True

                # Tampilkan box khusus yang mencolok
                print("\n" + "="*55)
                print("   URL CLOUDFLARE DITEMUKAN!")
                print("="*55)
                print(f"\n   LINK: {url}")
                print(f"   API : {url}/api")
                print("\n" + "="*55)
                print("   (Silakan COPY link API di atas ke HP Anda)")
                print("="*55 + "\n")

    process.wait()

if __name__ == "__main__":
    try:
        run_tunnel()
    except KeyboardInterrupt:
        print("\n[*] Tunnel dihentikan.")
        sys.exit(0)
    except Exception as e:
        print(f"\n[ERROR] Terjadi kesalahan: {e}")
        input("Tekan Enter untuk keluar...")
