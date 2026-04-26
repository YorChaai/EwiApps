Berikut adalah dokumentasi teknis mengenai perubahan aplikasi dari versi lama ke versi baru yang lebih responsif dan padat (TikTok Style).

---

# 📄 Dokumentasi Perubahan UI: Adaptive Compact Mode

Dokumentasi ini menjelaskan transisi dari desain statis ke desain responsif yang cerdas, serta alasan teknis di balik penggunaan logika `useCompact` dibandingkan hanya menggunakan `isAndroid`.

## 1. Konsep Utama: `isAndroid` vs `useCompact`

Dalam pengembangan Flutter untuk multi-platform (Android, Tablet, Windows), ada dua cara untuk membedakan tampilan:

### A. `isAndroid` (Berdasarkan Sistem Operasi)
*   **Cara Kerja:** Mengecek "KTP" perangkat. Jika sistem operasinya Android, maka jalankan perintah A.
*   **Masalah:** Jika Anda membuka aplikasi di **Windows** lalu mengecilkan jendelanya seukuran HP, sistem tetap menganggap itu Windows. Akibatnya, tampilan tetap "gemuk" dan meluber (overflow) karena tidak mau mengecil.

### B. `useCompact` (Berdasarkan Lebar Layar / Responsif)
*   **Cara Kerja:** Mengecek "Sensor Ruangan". Tidak peduli apa perangkatnya, jika lebar layar sempit (misal < 500px), maka otomatis jalankan mode **Compact (Padat)**.
*   **Rumus Koding:** `useCompact = (isMobileDevice) || (screenWidth < 500px)`
*   **Keuntungan:** Aplikasi menjadi sangat fleksibel. Tampilan akan mengecil secara otomatis saat jendela ditarik di Laptop, dan akan otomatis padat saat dibuka di HP.

---

## 2. Detail Perubahan per Komponen

| Bagian | Versi Lama (Statis) | Versi Baru (Adaptive Compact) | Alasan Perubahan |
| :--- | :--- | :--- | :--- |
| **Tema Global** | Ukuran font dan jarak (padding) selalu sama di semua perangkat. | `VisualDensity` dibuat otomatis padat dan font mengecil 8% saat `useCompact` aktif. | Agar tampilan di Android tidak terlihat "segede gaban" dan muat banyak informasi. |
| **AppBar (Atas)** | Tinggi 64px, teks besar. | Tinggi dipangkas jadi 56px, teks nama dan role diperkecil. | Memberikan ruang lebih luas untuk melihat isi konten di bawahnya. |
| **Tombol Filter** | Padding 14px, font 13px. | Padding 10px, font 11.5px. | Agar tombol "Semua, Draft, Approved" tidak meluber keluar layar. |
| **Kolom Pencarian** | Desain lebar dan tinggi. | Desain `isDense: true` (langsing) dan font 13px. | Standar aplikasi modern (TikTok/WhatsApp) yang mengutamakan kepadatan data. |
| **Kartu Settlement/Kasbon** | Margin 12px, Padding 16px, Font 15px. | Margin 8px, Padding 12px, Font 14px (Judul) & 11px (Detail). | Agar dalam satu layar HP, user bisa melihat 4-5 kartu sekaligus tanpa banyak scroll. |
| **Tabel Laporan** | Lebar tetap (sering terpotong di HP). | Menggunakan `SingleChildScrollView` horizontal (Bisa di-swipe ke kanan). | Memungkinkan data Jan-Des yang lebar tetap bisa dibaca di layar HP yang sempit. |
| **Tombol Aksi Laporan** | Berbaris ke samping (sering bertabrakan). | Menggunakan `Wrap` (Otomatis menumpuk ke bawah jika tidak muat). | Menghindari error garis kuning-hitam (Overflow). |

---

## 3. Perbaikan Khusus Laporan Tahunan (Tabel 4)

Kami telah melakukan restorasi (pengembalian) logika pengelompokan yang sangat krusial agar selaras dengan database dan Excel:

1.  **Penomoran Batch:** Mengembalikan label **"Expense#1", "Expense#2"** secara otomatis berdasarkan ID database terkecil ke terbesar.
2.  **Hirarki Subkategori:** Mengembalikan sistem grouping **"(A) Biaya Operasi"**, **"(B) Biaya Research"**, dst.
3.  **Label Navigasi:** Mengembalikan teks **"Kategori Tabular"** di samping ikon agar user tidak bingung.
4.  **Scrollbar:** Menambahkan scrollbar manual yang terlihat jelas di sisi kanan untuk memudahkan navigasi mouse di Windows.

---

## 4. Kesimpulan

Perubahan ini tidak mengubah **Logika Bisnis** (cara hitung uang, ambil data, dll), melainkan hanya mengubah **"Baju" (UI)** aplikasi agar lebih pintar. 

Aplikasi sekarang memiliki **Satu Sumber Kode** yang bisa tampil luar biasa di dua kondisi:
1.  **Laptop/Windows:** Tampilan luas, lega, dan lengkap.
2.  **Android/Small Window:** Tampilan padat, efisien, dan informasi melimpah (TikTok Style).

---
**Status Kode:** *Verified, Clean Linter, and Responsive Optimized.