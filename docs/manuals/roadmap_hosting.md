# Roadmap Migrasi ke Hosting Profesional (Niagahoster)

Dokumen ini menjelaskan langkah-langkah dan biaya yang diperlukan saat Anda siap memindahkan aplikasi dari laptop ke internet permanen.

## 1. Persiapan Biaya (Estimasi Niagahoster)
Berdasarkan paket yang Anda pilih (Premium):
- **Hosting:** ± Rp 39.000 / bulan (Pembayaran 12 bulan di muka).
- **Domain:** Biasanya gratis untuk tahun pertama jika beli paket Premium (misal: `exspan-app.id`).
- **Total Tahun Pertama:** ± Rp 500.000 - Rp 700.000 (termasuk pajak).

## 2. Kenapa Harus Menggunakan Firebase? (Gratis)
Meskipun pakai hosting Niagahoster, kita tetap butuh **Firebase Authentication** agar:
1. Login Google di Android/iOS sangat stabil.
2. Keamanan data user terjamin oleh Google.
3. **Gratis:** Paket Spark Firebase tidak memungut biaya untuk autentikasi pengguna.

## 3. Komponen Tambahan yang Diperlukan
Setelah punya hosting, Anda perlu menyiapkan:
- **Server Email (SMTP):** Niagahoster biasanya memberikan akun email gratis (misal: `admin@exspan-app.id`). Kita akan pakai ini untuk mengirim kode OTP Lupa Password.
- **SSL Certificate:** Gratis dari Niagahoster (Let's Encrypt). Wajib agar aplikasi bisa login Google.

## 4. Alur Kerja Lokal vs Cloud

| Fitur | Status Lokal (Sekarang) | Status di Hosting (Nanti) |
| :--- | :--- | :--- |
| **Akses HP** | Pakai Cloudflare (Berubah-ubah) | Pakai Domain (Tetap selamanya) |
| **Login Google** | Harus di HP (Windows terbatas) | Bisa di semua platform (lewat Browser) |
| **OTP Email** | Simulasi di terminal | Terkirim ke inbox email user |
| **Laptop Mati** | Aplikasi HP ikut mati | Aplikasi HP tetap jalan 24 jam |

## 5. Langkah Migrasi (Nanti)
1. Beli Hosting & Domain di Niagahoster.
2. Buat database PostgreSQL di panel Niagahoster.
3. Upload folder `backend` via FTP/Git.
4. Update file `.env` dengan Client ID Google yang permanen.
5. Publish aplikasi Flutter ke Play Store atau bagi-bagi file APK-nya.

---
*Dibuat oleh Gemini CLI - 24 April 2026*
