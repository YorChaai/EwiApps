# Panduan Teknis Operasional (EwiApps)

Panduan ini berisi cara menjalankan, membersihkan, dan merilis aplikasi.

---

## 1. Python & Flask (Backend)

### A. Cara Menjalankan
Buka terminal di folder `backend`, lalu ketik:
```bash
python app.py
```

### B. Cara Membersihkan (Clean)
Jika ada error aneh setelah update kode, hapus folder cache:
1. **Cara Manual**: Cari folder bernama `__pycache__` di folder `backend`, klik kanan lalu **Delete**.
2. **Cara Cepat (PowerShell)**: Buka terminal di folder utama proyek, lalu copy-paste perintah ini:
   ```powershell
   Get-ChildItem -Path . -Include __pycache__ -Recurse | Remove-Item -Force -Recurse
   ```
   *Perintah ini akan mencari semua folder `__pycache__` di seluruh proyek dan menghapusnya sekaligus.*
3. Jalankan kembali `python app.py`.

### C. Update Library
Jika ada fitur baru yang butuh library tambahan:
```bash
pip install -r requirements.txt
```

---

## 2. Flutter (Frontend)

### A. Membersihkan & Update (Clean & Pub)
Wajib dilakukan jika aplikasi "berat" atau error setelah update:
```bash
flutter clean
flutter pub get
```

### B. Menjalankan Aplikasi (Run)
*   **Di Windows (Desktop)**:
    ```bash
    flutter run -d windows
    ```
*   **Di HP (Android)**:
    1. Colok HP ke laptop/PC.
    2. Pastikan "USB Debugging" di HP sudah aktif.
    3. Ketik: `flutter run` (pilih HP kamu jika muncul pilihan).

### C. Membuat Versi Rilis (Release)
Untuk membuat file APK yang siap diinstal atau dikirim ke orang lain:
```bash
flutter build apk --release
```
*Hasilnya ada di: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 3. Cloudflare Tunnel (Akses Online)

Gunakan ini agar aplikasi di HP bisa akses backend di laptop tanpa kabel (lewat internet).

### Langkah-langkah:
1.  Buka folder `tools\cloudflare`.
2.  Klik kanan file `start_tunnel.ps1` -> **Run with PowerShell**.
3.  Tunggu sampai muncul link seperti: `https://abcd-123.trycloudflare.com`.
4.  **PENTING**: Copy link tersebut, lalu tambahkan `/api` di belakangnya (contoh: `https://abcd-123.trycloudflare.com/api`).
5.  Masukkan link tersebut ke dalam pengaturan IP/URL di aplikasi Android kamu.

> [!WARNING]
> Jangan tutup jendela PowerShell selama kamu masih memakai aplikasi di HP. Jika ditutup, koneksi akan terputus.

---

## Ringkasan Perintah Cepat

| Target | Perintah | Fungsi |
| :--- | :--- | :--- |
| **Backend** | `python app.py` | Jalankan server |
| **Frontend** | `flutter run` | Jalankan mode debug |
| **Release** | `flutter build apk` | Buat file instalasi (APK) |
| **Tunnel** | (Jalankan file .ps1) | Akses online gratis |
| **Clean** | `flutter clean` | Hapus sampah build |
