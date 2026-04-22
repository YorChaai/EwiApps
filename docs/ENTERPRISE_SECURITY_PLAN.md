# Strategi Keamanan & Deployment Enterprise (MiniProjectKPI_EWI)

Dokumen ini menjelaskan langkah-langkah teknis untuk mempersiapkan aplikasi agar aman, stabil, dan layak digunakan oleh perusahaan besar.

---

## 1. Masalah Keamanan Utama: Secret Key Hardcoded
**Masalah saat ini:** Di file `config.py`, terdapat kode:
```python
SECRET_KEY = os.environ.get('SECRET_KEY', 'expense-settlement-secret-key-2026')
```
Jika file `.env` tidak ditemukan atau tidak dikonfigurasi di server, aplikasi menggunakan *default key* yang tertulis di kode. Hacker yang mengetahui kode ini bisa memalsukan token login (JWT) dan menyamar sebagai siapa pun, termasuk Admin.

**Solusi Enterprise:**
- Hapus nilai default di dalam kode.
- Pastikan aplikasi **gagal berjalan (crash by design)** jika kunci rahasia tidak ditemukan di variabel lingkungan server. Ini memaksa admin server untuk selalu mengatur kunci yang unik dan kuat.

## 2. Transisi Database (SQLite ke PostgreSQL)
**Masalah saat ini:** SQLite menyimpan data dalam satu file (`database.db`). Jika hacker berhasil menembus celah lain di server, mereka bisa langsung mengunduh file database tersebut dan mencuri seluruh data perusahaan. Selain itu, SQLite akan melambat jika banyak orang menulis data secara bersamaan.

**Solusi Enterprise:** Gunakan **PostgreSQL**.
- **Pemisahan Data:** Database berjalan sebagai layanan terpisah, bukan sekadar file di folder aplikasi.
- **Hak Akses:** Bisa diatur agar database hanya bisa menerima koneksi dari IP server aplikasi saja (Firewall).

## 3. Keamanan Jalur API & CORS (Cross-Origin Resource Sharing)
Aplikasi Anda berbicara dengan server melalui API. Ini harus diproteksi dengan ketat.

### A. Masalah CORS (Origin: "*")
- **Masalah:** Saat ini server mengizinkan semua sumber (`*`). Hacker bisa membuat website palsu yang mengirimkan perintah jahat ke API Anda saat pengguna sedang login di browser mereka.
- **Solusi:** Ganti `*` dengan domain resmi (misal: `https://apps.perusahaan.com`). Server akan menolak semua permintaan yang datang dari alamat yang tidak terdaftar.

### B. HTTPS (SSL/TLS) - **Wajib**
- **Masalah:** Tanpa HTTPS, data (seperti nomor rekening atau nominal) bisa "diintip" saat dikirim melalui jaringan WiFi.
- **Solusi:** Gunakan sertifikat SSL agar semua jalur komunikasi dienkripsi.

## 4. Perlindungan dari Serangan Bot & Brute Force
**Masalah:** Hacker bisa menggunakan bot untuk mencoba menebak password ribuan kali dalam satu menit.

**Solusi Enterprise:**
- **Rate Limiting:** Membatasi jumlah permintaan per detik untuk setiap alamat IP. Jika ada yang mencoba login salah berkali-kali, IP mereka akan diblokir sementara secara otomatis.
- **Input Validation:** Melakukan pengecekan ketat pada setiap data yang dikirim pengguna agar tidak mengandung karakter aneh yang bisa merusak sistem.

## 5. Strategi Hosting & Infrastruktur

Untuk perusahaan besar, jangan gunakan hosting murah. Gunakan layanan profesional:

| Opsi | Layanan | Rekomendasi Teknis |
| :--- | :--- | :--- |
| **AWS (Amazon)** | **AWS RDS & EC2** | Pilihan terbaik untuk kepatuhan keamanan internasional (ISO/SOC2). |
| **DigitalOcean** | **App Platform** | Lebih mudah dikelola namun tetap memiliki infrastruktur keamanan yang kuat. |
| **On-Premise** | **Server Internal** | Data tetap di dalam kantor, namun butuh tim IT internal untuk maintenance. |

---

## 6. Rencana Aksi (Action Plan)

1. **Audit Konfigurasi:** Pindahkan semua Secret Key ke `.env` dan hapus nilai default di kode.
2. **Setup PostgreSQL:** Menyiapkan server database terpisah untuk uji coba.
3. **Konfigurasi CORS:** Mengunci akses API hanya untuk alamat domain resmi.
4. **Implementasi Rate Limiter:** Menambahkan pengamanan terhadap serangan bot di bagian login.

---
**Catatan Penting:** Dokumen ini bersifat perencanaan. Tidak ada perubahan kode program yang dilakukan selama pembuatan dokumen ini.
