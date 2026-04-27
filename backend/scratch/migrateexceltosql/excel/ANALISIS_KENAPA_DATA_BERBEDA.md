
# ❓ Analisis: Mengapa Data Excel 1 & SQL Berbeda?

Laporan ini menjelaskan penyebab teknis ketidaksesuaian angka antara file manual perusahaan (Excel 1) dan database aplikasi (SQL) saat ini.

## 1. Masalah Sel Gabungan (Merged Cells)
File **Excel 1** banyak menggunakan fitur *Merge & Center* (misal pada kolom Tanggal atau Kategori).
- **Kendalanya**: Secara teknis, komputer hanya membaca data pada baris pertama di sel yang digabung. Baris-baris di bawahnya dianggap **KOSONG (NaN)**.
- **Dampaknya**: Jika satu tanggal digabung untuk 10 transaksi, sistem audit cepat mungkin hanya menghitung 1 transaksi dan melewatkan 9 lainnya.

## 2. Format Angka Manual (Human Error)
Karena Excel 1 diisi secara manual ("hasil tangan"), terdapat ketidakkonsistenan format:
- **Pemisah Ribuan**: Ada yang menggunakan titik (`.`), koma (`,`), atau bahkan spasi.
- **Teks vs Angka**: Seringkali angka ditulis bersama teks (misal: "Rp 1.000.000" atau "1.000.000,-"). 
- **Dampaknya**: Sistem database SQL membutuhkan angka bersih (pure numeric). Jika ada karakter teks sedikit saja, angka tersebut dianggap **NOL** atau **ERROR** saat proses import manual sebelumnya.

## 3. Perbedaan Struktur Kolom (Header Offset)
- **Excel 1**: Data baru dimulai pada baris ke-7. Ada banyak kolom kosong di sebelah kiri (Unnamed).
- **SQL**: Database mengharapkan data yang sudah "flat" dan konsisten.
- **Dampaknya**: Jika proses import sebelumnya tidak melakukan "skipping" baris dengan benar, maka kolom yang masuk ke SQL bisa tertukar (misal: Kolom 'Client' masuk ke kolom 'Nominal').

## 4. Data Neraca & Deviden yang Terlupakan
Berdasarkan audit, tabel `dividend_settings` (Neraca) dan `dividends` di SQL Anda masih berisi **Rp 0**.
- **Penyebabnya**: Kemungkinan besar proses import Anda sebelumnya hanya fokus pada **Sheet 1 (Transaksi)**, sementara data di **Sheet 2** dan **Sheet 3** tidak ikut ditarik ke dalam SQL.

## 5. Sumber Data SQL yang Berbeda
Ada kemungkinan database SQL Anda saat ini adalah hasil import dari **Excel 2 (Semi-Clean)** atau file lain yang versinya berbeda dengan **Excel 1 (Original)** yang Anda berikan sekarang. Inilah yang menyebabkan total pengeluaran di SQL (3,1 Miliar) jauh lebih besar dibanding hasil pembacaan cepat di Excel 1.

---

### **Solusi Agar Berhasil (Target Menjadi Excel 3):**
Untuk membuat data SQL Anda selaras dengan Excel 1 dan menghasilkan output seindah Excel 3, kita harus menggunakan script Python yang melakukan:
1.  **Auto-Fill**: Otomatis mengisi baris kosong akibat *merged cells*.
2.  **String Cleaning**: Membersihkan semua karakter non-angka (Rp, titik, koma) sebelum data masuk ke SQL.
3.  **Multi-Sheet Mapping**: Secara sadar mengambil data dari ketiga sheet (Transaksi, Neraca, dan Deviden) sekaligus.

---
*Laporan ini disimpan di folder `\excel` sebagai referensi kendala teknis.*
