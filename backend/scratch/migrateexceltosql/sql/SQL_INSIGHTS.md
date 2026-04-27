
# 💡 Key Insights & Referensi Penting SQL

Berdasarkan analisis struktur dan data dari 3 file sebelumnya, berikut adalah hal-hal penting yang perlu Anda ketahui untuk referensi pengelolaan atau migrasi data:

## 1. Perbedaan "Report Year" vs "Actual Year"
Sistem Anda membedakan antara kapan transaksi **terjadi** (Actual) dan untuk anggaran tahun mana transaksi itu **dilaporkan** (Report).
- **Temuan:** Ada data yang nota-nya tahun 2023 tapi dilaporkan untuk anggaran 2024.
- **Penting:** Saat import dari Excel, pastikan Anda mengisi kedua kolom ini. Jika hanya satu, laporan tahunan mungkin akan terlihat kosong atau tidak akurat.

## 2. Struktur Kategori (Induk & Sub)
Tabel `categories` menggunakan sistem `parent_id`.
- **Induk (Parent):** Memiliki `parent_id` bernama NULL (Contoh: BIAYA OPERASI).
- **Sub-Kategori:** Memiliki `parent_id` yang merujuk ke ID induknya.
- **Tips:** Jangan menginput transaksi langsung ke ID Induk. Selalu gunakan ID Sub-Kategori agar laporan breakdown kategori muncul dengan benar.

## 3. Data Masa Depan (Tahun 2029 - 2030)
- **Temuan:** Ditemukan cukup banyak data di tahun 2029 dan 2030 (terutama di Settle dan Kasbon).
- **Analisis:** Kemungkinan ini adalah data dummy (percobaan) atau kesalahan input tahun saat testing. 
- **Saran:** Jika ini bukan data asli, sebaiknya dibersihkan sebelum migrasi final agar tidak mengacaukan statistik dashboard.

## 4. Komponen Neraca (Balance Sheet) di `dividend_settings`
Berbeda dengan pengeluaran yang dihitung per transaksi, data Neraca di sistem ini disimpan secara **tahunan** di tabel `dividend_settings`.
- **Kolom Penting:** `opening_cash_balance`, `accounts_receivable`, `retained_earnings_balance`.
- **Catatan:** Data ini sangat sedikit (hanya 3 baris untuk 3 tahun). Pastikan saldo awal (Opening Cash) setiap tahun sudah benar karena ini akan menjadi dasar perhitungan saldo di dashboard.

## 5. Status Transaksi (Approved vs Pending)
- **Expenses:** Memiliki kolom `status`. Hanya data dengan status `approved` yang biasanya muncul di laporan keuangan final.
- **Pajak & Revenue:** Tabel ini tidak memiliki kolom status eksplisit (dianggap selalu valid jika sudah masuk).

## 6. Relasi User ke Data
- Setiap data `settlements` dan `advances` memiliki `user_id`.
- **Penting:** Jika Anda menghapus seorang user dari tabel `users`, data transaksi yang dibuat oleh user tersebut mungkin akan bermasalah (Foreign Key Error) kecuali sistem diatur untuk `ON DELETE CASCADE` atau `SET NULL`.

## 7. Format Mata Uang (Currency)
- Tabel pengeluaran dan pendapatan memiliki kolom `currency` dan `currency_exchange`.
- **Penting:** Pastikan jika mata uang bukan IDR, kolom `currency_exchange` (kurs) harus diisi agar sistem bisa mengkonversi nilai tersebut ke Rupiah untuk laporan total.

## 8. Logika Bisnis & Pemetaan (Mapping)
- **Pendapatan Lain-lain**: Di tahun 2024, kategori ini khusus digunakan untuk **"Bunga Bank"**. Data ini biasanya memiliki `revenue_type` = `pendapatan_lain_lain`.
- **Beban Langsung vs Administrasi**: Pengelompokan ini diatur melalui `main_group` di tabel kategori. 
    - Jika pengeluaran berkaitan dengan operasional lapangan (Sewa Alat, R&D, Log Data), masuk ke **BEBAN LANGSUNG**.
    - Jika berkaitan dengan kantor/umum (Sewa Kantor, Kesehatan, Pembelian Barang Umum), masuk ke **BIAYA ADMINISTRASI DAN UMUM**.

---
*Laporan ini dibuat sebagai referensi tambahan untuk memudahkan Anda memahami karakteristik data di dalam SQL.*
