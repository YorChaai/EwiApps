
# 🚀 Rencana Migrasi Data Excel ke PostgreSQL

Dokumen ini menjelaskan tahapan transformasi data dari file perusahaan yang berantakan (Excel 1) hingga menjadi data SQL yang bersih dan rapi (seperti Excel 3).

## 📋 Ringkasan File
1.  **Excel_1 (Original)**: Data manual, banyak baris gabungan (merged), rumus salah, dan kotor.
2.  **Excel_2 (Semi-Clean)**: Hasil pembersihan awal, kategori sudah mulai terbentuk tapi subkategori belum sempurna.
3.  **Excel_3 (Ideal)**: Format tujuan. Data flat (tidak ada merge), kategori rapi, dan siap dipakai dashboard.

---

## 🛠️ Tahapan Migrasi Spesifik (Roadmap Detail)

### Tahap 1: Ekstraksi Data Multi-Sheet (Excel 1)
Script `excel_to_postgres.py` akan membagi pengambilan data menjadi 3 bagian:
1.  **Sheet 1 (Revenue-Cost_2024)**:
    *   Mengambil seluruh data transaksi (Revenue, Tax, Settlement, Kasbon).
    *   Melakukan *unmerging* baris agar setiap transaksi punya tanggal yang lengkap.
2.  **Sheet 2 (Laba rugi -2024)**:
    *   Fokus pada tabel **Neraca** (Balance Sheet).
    *   Mengambil nilai Saldo Awal, Kas, Piutang, Modal, dan Laba Ditahan untuk di-input ke tabel `dividend_settings`.
3.  **Sheet 3 (Business Summary)**:
    *   Mengambil data pembayaran **Deviden** (Dividen yang dibagikan).
    *   Memasukkan data tersebut ke tabel `dividends` agar sinkron dengan laporan tahunan.

### Tahap 2: Pemetaan Kategori & Subkategori (Kunci Rapi)
Ini adalah tahap agar hasil di aplikasi seindah Excel 3:
- **Mapping Script**: Membuat kamus pencocokan. Contoh: Jika di File 1 ada "ALFA Service", otomatis beri ID Kategori "Biaya Operasi".
- **Grup Utama**: Memastikan `main_group` (Beban Langsung vs Adm & Umum) sudah terisi agar Laba Rugi di aplikasi muncul dengan benar.

### Tahap 3: Validasi & Pembersihan Typo
- **Cross-Check Excel 3**: Membandingkan hasil query SQL dengan baris-baris yang ada di Excel 3 (File Ideal).
- **Penanganan Typo**: Script akan mendeteksi jika ada angka yang tidak masuk akal (misal: 1jt di deskripsi tapi 10jt di kolom nilai).

### Tahap 4: Final Injection ke PostgreSQL
Data yang sudah bersih dari ketiga sheet tersebut dimasukkan ke:
- `revenues`, `taxes`, `expenses`, `advance_items`, `dividends`, dan `dividend_settings`.

---

## ⚠️ Catatan Ketelitian
- **Neraca (Sheet 2)**: Harus sangat teliti mengambil koordinat sel (misal: B12 atau E15) karena formatnya manual dan berisiko salah ambil angka jika ada pergeseran baris.
- **Deviden (Sheet 3)**: Pastikan tahun laporannya sesuai (2024).

## 💡 Rekomendasi Strategis (Saran Langkah Selanjutnya)

Berdasarkan pengecekan terakhir, terdapat selisih besar antara SQL dan Excel 1. Berikut adalah saran langkah demi langkah:

1.  **Backup Database**: Sebelum melakukan migrasi apapun, pastikan backup `backup_postgres_2026-04-28_00-04-50.sql` sudah aman.
2.  **Pembersihan Data SQL (Opsi)**: Jika data 3,1 Miliar di SQL dianggap data kotor/dummy, disarankan untuk menghapus data transaksi tahun 2024 di SQL agar tidak terjadi duplikasi saat data Excel 1 masuk.
3.  **Fokus Tahap 1 (Neraca & Deviden)**: Mengisi data yang kosong di SQL (Neraca Sheet 2 & Deviden Sheet 3) adalah prioritas agar laporan finansial di aplikasi mulai muncul angkanya.
4.  **Iterasi Sheet 1**: Membangun script pembersih Sheet 1 yang bisa menangani sel gabungan (merged) dan salah ketik (typo) secara otomatis.
5.  **Uji Coba Export**: Setiap kali data masuk, langsung uji coba download Excel dari aplikasi dan bandingkan dengan **Excel 3**.

---
*Rencana ini akan menjadi panduan teknis dalam pembuatan script `excel_to_postgres.py`.*
