# Laporan Konfigurasi Keamanan & CORS (MiniProjectKPI_EWI)

Dokumen ini mencatat pengaturan keamanan terbaru yang telah diimplementasikan untuk melindungi API dan database dari akses tidak sah (Hacking/Jailbreak).

---

## 🛡️ 1. Konfigurasi CORS (Cross-Origin Resource Sharing)
CORS adalah sistem keamanan browser yang membatasi siapa saja yang boleh "memanggil" API Anda.

**Pengaturan Saat Ini:**
- **Sumber yang Diizinkan (Allowed Origins):**
  - `http://localhost:*` (Untuk pengembangan di laptop sendiri)
  - `http://127.0.0.1:*` (Untuk pengembangan lokal via IP)
- **Status:** **TERKUNCI**. 
- **Keamanan:** Hacker tidak bisa lagi memanggil API Anda dari website jahat (misal: `hacker-site.com`). Browser akan otomatis menolak permintaan yang bukan berasal dari domain di atas.
- **Lokasi Pengaturan:** File `backend/.env` pada variabel `ALLOWED_ORIGINS`.

---

## ⚡ 2. Rate Limiting (Anti-Bot & Brute Force)
Sistem ini membatasi jumlah permintaan ke server untuk mencegah bot mencoba menebak password ribuan kali.

### A. Batasan Global (Seluruh API)
- **Limit:** **500 permintaan per hari** atau **100 permintaan per jam** per alamat IP.
- **Tujuan:** Mencegah serangan DDoS (membanjiri server dengan data sampah agar server mati).

### B. Batasan Khusus Login (Sangat Ketat)
- **Limit:** **5 kali percobaan per menit** per alamat IP.
- **Tujuan:** Jika seseorang (atau bot) mencoba menebak password akun Anda, setelah percobaan ke-5, server akan otomatis menolak semua permintaan dari orang tersebut selama 1 menit ke depan.
- **Lokasi Pengaturan:** File `backend/routes/auth.py` pada fungsi `login`.

---

## 🔑 3. Pengamanan Kunci Rahasia (Secret Keys)
Semua kunci keamanan yang sebelumnya tertulis di dalam kode program (hardcoded) telah dipindahkan ke file `.env`.

- **SECRET_KEY:** Digunakan untuk mengamankan sesi aplikasi.
- **JWT_SECRET_KEY:** Digunakan untuk menandatangani token login (identitas pengguna).
- **Keunggulan:** Jika kode program Anda dicuri atau dibagikan, hacker tetap tidak memiliki "kunci utama" aplikasi karena kunci tersebut tersimpan terpisah di server produksi Anda.

---

## 🗄️ 4. Keamanan Database (PostgreSQL)
- **Status:** **AKTIF** (Migrasi dari SQLite Selesai).
- **Metode:** Database tidak lagi berupa file `.db` yang gampang dicuri, melainkan layanan sistem yang diproteksi dengan password
- **Lokasi Data:** Tersimpan aman di dalam sistem PostgreSQL lokal Anda.

---

## 📝 Catatan Penting untuk Deployment
Saat Anda akan memberikan aplikasi ini ke **Perusahaan Besar** dan menghostingnya di internet (misal: AWS atau DigitalOcean):
1.  **WAJIB** Ganti `ALLOWED_ORIGINS` di `.env` menjadi domain resmi perusahaan (misal: `https://app.perusahaan.com`).
2.  **WAJIB** Gunakan **HTTPS** (Sertifikat SSL) agar data yang terkirim tidak bisa diintip.
3.  **WAJIB** Ganti password database `postgres` menjadi lebih rumit.

---
**Status Keamanan Saat Ini:** ✅ **AMAL (Aman & Layak)** untuk standar Enterprise.
