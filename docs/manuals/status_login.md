# Panduan Lengkap Sistem Autentikasi ExspanApp

Dokumen ini memberikan rincian teknis mengenai sistem login, keamanan, dan integrasi Google Sign-In yang ada di aplikasi ini.

## 1. Arsitektur Autentikasi
Aplikasi menggunakan sistem **State Management Provider** dengan **JWT (JSON Web Token)** untuk mengelola sesi pengguna.

- **File Utama:** `frontend/lib/providers/auth_provider.dart`
- **Alur Kerja:**
  1. Pengguna memasukkan kredensial.
  2. Frontend mengirim request ke backend `/api/auth/login`.
  3. Backend mengembalikan Token JWT dan data User.
  4. Token disimpan secara lokal menggunakan `SharedPreferences`.
  5. Setiap request API berikutnya akan menyertakan token ini di dalam Header `Authorization: Bearer <token>`.

## 2. Fitur Login & Role Pengguna
Sistem mendukung multi-role yang menentukan akses ke dashboard:
- **Admin:** Akses penuh ke manajemen data, settlement, dan pengaturan.
- **Reviewer:** Akses untuk melihat laporan dan melakukan validasi/review data.
- **User:** Akses terbatas sesuai dengan izin yang diberikan.

## 3. Fitur Lupa Password & Reset OTP
Berbeda dengan aplikasi sederhana, ExspanApp sudah memiliki UI untuk alur pemulihan kata sandi:
- **UI Dialog:** Terdapat di `login_screen.dart` melalui fungsi `_showForgotPasswordDialog`.
- **Alur OTP:**
  1. Pengguna memasukkan Email/Username.
  2. Sistem mengirim kode OTP (memerlukan konfigurasi SMTP di Backend).
  3. Pengguna memverifikasi OTP dan memasukkan password baru.
- **Status Teknis:** UI sudah siap, namun pastikan di sisi Backend (`app.py` atau route terkait) fungsi pengiriman email sudah aktif.

## 4. Integrasi Google Sign-In (Gmail)
Saat ini tombol Google Sign-In bersifat kondisional.

### A. Kenapa Tombol Mati di Windows?
Google Sign-In secara resmi didukung oleh plugin `google_sign_in` untuk platform mobile dan web. Untuk Windows Desktop, plugin tersebut tidak mendukung secara native. 
- **Solusi Windows:** Jika ingin diaktifkan, kita harus menggunakan metode OAuth2 melalui browser external atau plugin pihak ketiga seperti `google_sign_in_dart`.

### B. Cara Mengaktifkan di Android/iOS
Agar tombol menjadi aktif dan bisa digunakan, langkah berikut **Wajib** dilakukan:
1. **Firebase Console:** Buat proyek baru dan daftarkan App ID (contoh: `com.example.miniprojectkpi`).
2. **SHA-1 Fingerprint:** Ambil SHA-1 dari PC Anda (lewat `keytool`) dan masukkan ke pengaturan Firebase.
3. **Google Service File:** Download `google-services.json` (Android) atau `GoogleService-Info.plist` (iOS) dan letakkan di folder masing-masing di Flutter.
4. **Backend Verify:** Backend harus memiliki endpoint untuk menerima `id_token` dari Google dan memverifikasinya menggunakan library `google-auth`.

## 5. Koneksi Jarak Jauh (Cloudflare Tunnel)
Jika Anda ingin mengakses aplikasi dari HP tanpa menggunakan WiFi yang sama dengan laptop (misal pakai paket data), Anda bisa menggunakan mode Cloudflare:
1. Jalankan **`start_all.bat`**.
2. Pilih nomor **4 (Start Backend + Cloudflare Tunnel)**.
3. Tunggu hingga jendela baru muncul dan cari teks yang berisi URL: `https://xxxx-xxxx-xxxx.trycloudflare.com`.
4. Salin URL tersebut.
5. Di aplikasi Android, ketuk teks **"Server: http://..."** pada halaman login, lalu ganti dengan URL dari Cloudflare tadi (jangan lupa tambahkan `/api` di ujungnya, contoh: `https://xxxx.trycloudflare.com/api`).

## 6. Pemecahan Masalah (Troubleshooting)
- **Error "Invalid Credentials":** Periksa apakah username/password sudah terdaftar di database (cek tabel `users` di Postgres/SQLite).
- **Tombol Login Tidak Bereaksi:** Pastikan URL Server sudah benar. Anda bisa mengetuk teks "Server: http://..." di halaman login untuk mengubahnya.
- **Token Expired:** Jika tiba-tiba logout, itu berarti token JWT sudah kadaluarsa (default biasanya 24 jam).

## 7. Lokasi File Kunci
- `frontend/lib/screens/auth/login_screen.dart`: UI Halaman Login & Dialog Lupa Password.
- `frontend/lib/services/api_service.dart`: Logika komunikasi HTTP ke backend.
- `backend/routes/auth.py` (Asumsi): Logika backend untuk validasi login.

---
*Terakhir diperbarui: 24 April 2026 oleh Gemini CLI*
