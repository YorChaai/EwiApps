# Panduan Migrasi Database & Keamanan (Bahasa Sederhana)

Dokumen ini menjelaskan rencana untuk memindahkan data dari SQLite ke PostgreSQL dan cara mengamankan aplikasi dari peretasan (jailbreak/hacking).

---

## 1. Apa itu PostgreSQL dan Mengapa Kita Pindah?

Bayangkan **SQLite** (yang Anda pakai sekarang) seperti sebuah **Buku Catatan Fisik**.
- **Kelebihan:** Gampang dibawa-bawa, tidak butuh listrik (server) khusus.
- **Kekurangan:** Jika buku itu hilang atau dicuri, data hilang. Jika dua orang ingin menulis di halaman yang sama bersamaan, mereka akan berebut.

Bayangkan **PostgreSQL** seperti sebuah **Bank Data Digital**.
- **Kelebihan:** Sangat aman, punya satpam sendiri (sistem keamanan), dan bisa diakses oleh ribuan orang sekaligus tanpa berebut.
- **Penting untuk Perusahaan Besar:** Perusahaan besar butuh "Bank Data", bukan "Buku Catatan".

---

## 2. Bagaimana Cara Memindahkan Data (Migrasi)?

Anda tidak perlu memindahkan data satu per satu secara manual. Prosesnya adalah:

1. **Siapkan "Rumah Baru":** Kita install PostgreSQL (di laptop Anda untuk tes, atau di internet untuk nanti).
2. **Gunakan Jembatan (SQLAlchemy):** Karena aplikasi Anda sudah memakai "jembatan" bernama SQLAlchemy, aplikasi Anda sebenarnya sudah "bisa bahasa PostgreSQL". Kita hanya perlu mengganti satu baris alamat di file `config.py`.
3. **Proses Pindahan (Transfer):** Saya akan buatkan sebuah script Python kecil yang tugasnya:
   - Membuka database SQLite lama.
   - Membaca isinya.
   - Menyalin semuanya ke database PostgreSQL baru.
   - **Hasilnya:** Data lama Anda (laporan, user, kategori) tidak akan hilang.

---

## 3. Apa itu "Jailbreak/Hacking" di Aplikasi Ini?

Dalam konteks aplikasi web/backend, "Jailbreak" atau peretasan biasanya berarti hacker berhasil masuk ke server dan melakukan hal yang tidak seharusnya.

**Tiga Celah yang Harus Kita Tutup:**
1. **Kunci yang Tertinggal (Secret Key):** Saat ini kuncinya tertulis di dalam kode. Jika hacker mencuri kode Anda, mereka punya kuncinya. Kita akan pindahkan kunci ini ke tempat rahasia bernama `.env`.
2. **Pintu yang Terbuka untuk Semua (CORS):** Saat ini server menerima perintah dari mana saja. Kita akan atur agar server hanya mau bicara dengan aplikasi resmi Anda saja.
3. **Data Tanpa Sandi (HTTP):** Saat data dikirim melalui internet, datanya tidak dikunci. Kita akan gunakan **HTTPS** (Sertifikat SSL) agar datanya tidak bisa diintip di tengah jalan.

---

## 4. Rencana Langkah Demi Langkah (Step-by-Step)

Jangan lakukan semuanya sekaligus. Mari kita bagi:

**Minggu 1: Pembersihan & Keamanan Dasar**
- Merapikan file `.env` (tempat menyimpan password rahasia).
- Mengunci akses API (CORS) agar hanya untuk aplikasi Anda.

**Minggu 2: Persiapan PostgreSQL**
- Saya akan bantu Anda install PostgreSQL di komputer Anda untuk latihan.
- Kita tes apakah aplikasi bisa berjalan dengan PostgreSQL (tanpa data lama dulu).

**Minggu 3: Migrasi Data**
- Kita jalankan script pindahan data dari SQLite ke PostgreSQL.
- Kita pastikan semua laporan tahunan dan data pengeluaran sudah muncul di database baru.

**Minggu 4: Hosting (Naik ke Internet)**
- Memilih tempat hosting (seperti AWS atau DigitalOcean).
- Menghubungkan aplikasi ke server internet tersebut.

---
**Pertanyaan Anda:** *"Harus gimana ajh jgn ubah koding kita diskusi dulu"*
**Jawaban saya:** Setuju. Saat ini kita hanya berdiskusi dan membuat rencana di file `.md`. Tidak ada perubahan pada kode aplikasi Anda sampai Anda benar-benar paham dan setuju.

Apakah ada bagian dari rencana pindahan data ini yang masih membingungkan Anda?
