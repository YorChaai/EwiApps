# BLUEPRINT: SISTEM DUAL-FILTERING (YEAR VS LAPORAN)
## Proyek: MiniProjectKPI_EWI

### 1. PENDAHULUAN
Dokumen ini merinci rencana transformasi sistem pencatatan keuangan untuk memisahkan logika penyaringan data menjadi dua mode utama:
*   **Mode Year (Tahun Aktual)**: Berdasarkan tanggal transaksi fisik/kuitansi (Cash Basis). Digunakan untuk melacak arus kas kronologis.
*   **Mode Laporan (Tahun Laporan)**: Berdasarkan periode pelaporan administrasi dan pajak (Accrual Basis). Digunakan untuk pencatatan "Pajak Terutang" atau project yang administrasinya baru diselesaikan di tahun berikutnya.

---

### 2. LOGIKA KONSOLIDASI AWAL (CUT-OFF)
Sistem ini memiliki aturan khusus untuk menangani data historis sebelum sistem dual-filter diimplementasikan:
*   **Laporan Tahun 2024 (Konsolidasi)**: Mencakup semua data aktual (**Settlement, Kasbon, Revenue, dan Pajak**) dari tahun **2022, 2023, dan 2024**. Hal ini dikarenakan kewajiban pajak dan administrasi tahun 2022-2023 baru diproses/dilaporkan secara resmi pada tahun 2024.
*   **Laporan Tahun 2025 ke Atas**: Mengikuti tahun berjalan secara normal (1:1) untuk semua modul (**Settlement, Kasbon, Revenue, dan Pajak**), kecuali jika ada transaksi yang secara eksplisit ditandai sebagai "Pajak Terutang" untuk tahun berikutnya.
    *   Laporan 2025 = Data Aktual 2025
    *   Laporan 2026 = Data Aktual 2026
    *   ... dan seterusnya sampai 2031+.

---

### 3. ANALISIS MASALAH (CURRENT STATE)
Berdasarkan audit data terbaru (April 2026), ditemukan distribusi data aktual sebagai berikut:

| TAHUN | SETTLE | KASBON | REVENUE | PAJAK |
| :--- | :--- | :--- | :--- | :--- |
| 2022 | 1 | 0 | 0 | 0 |
| 2023 | 3 | 0 | 0 | 1 |
| **2024** | **107** | **2** | **14** | **9** |
| 2025 | 1 | 0 | 1 | 1 |
| 2026 | 29 | 13 | 2 | 0 |
| 2030 | 19 | 12 | 0 | 0 |

**Masalah Utama:**
*   **Data Mismatch (2022-2023)**: Terdapat data Settlement dan Pajak di tahun 2022-2023 yang secara administrasi harus ditarik ke Laporan 2024.
*   **Anomali Masa Depan (2026-2030)**: Banyak data (terutama Settlement dan Kasbon) yang memiliki tanggal di tahun 2026-2030. Data ini harus diverifikasi apakah merupakan "Pajak Terutang" atau kesalahan input.
*   **Keterbatasan Tabel**: Tabel `Revenue` dan `Tax` saat ini hanya mengandalkan field tanggal, sehingga tidak bisa dipisahkan antara Tahun Aktual dan Tahun Laporan tanpa migrasi database.

---

### 3. PERUBAHAN ARSITEKTUR & DATABASE

#### 3.1 Skema Database (Backend Models)
Melakukan migrasi untuk menambahkan kolom `report_year` (Integer, Indexed) pada tabel yang belum memilikinya:
*   **Tabel `revenues`**: Tambah kolom `report_year`.
*   **Tabel `taxes`**: Tambah kolom `report_year`.
*   **Tabel `dividends`**: Tambah kolom `report_year`.

#### 3.2 Logika API (Backend Routes)
Setiap endpoint laporan (Annual Report, Summary, Dashboard) harus dimodifikasi agar menerima parameter `filter_mode`:
1.  **`mode=actual`**: Filter menggunakan field tanggal asli (`date` atau `invoice_date`).
2.  **`mode=report`**: Filter menggunakan field `report_year`.

---

### 4. RENCANA PERUBAHAN UI (FRONTEND FLUTTER)

#### 4.1 Settlement & Kasbon (Advances) List
Menambahkan tombol seleksi tahun baru di barisan filter bagian atas:
*   **Urutan Filter Baru**: `[Laporan (Tahun)]` | `[Year (Tahun)]` | `[Semua]` | `[Draft]` | `[Submitted]` ...
*   **Fungsi**: User dapat beralih dengan cepat antara melihat data berdasarkan administrasi atau kronologi kuitansi.

#### 4.2 Revenue & Pajak (Input & List)
*   **Header Navigation**: Menambahkan pilihan "Year (Tahun)" di bagian header/appbar list Revenue dan Pajak agar konsisten dengan modul lainnya.
*   **Input Dialog**: Menambahkan field dropdown "Tahun Laporan" pada saat tambah/edit data.
    *   *Skenario*: User input kuitansi tanggal 31 Des 2023, namun memilih "Tahun Laporan" 2024. Data akan otomatis muncul di filter "Year 2023" dan "Laporan 2024".

#### 4.3 Annual Report (Laporan Tahunan)
*   **Global Toggle**: Menambahkan toggle/dropdown di AppBar untuk memilih mode:
    *   "Berdasarkan Tanggal Transaksi" (Actual Financials)
    *   "Berdasarkan Tahun Laporan" (Reporting Financials / Accrual)
*   **Labeling**: Update UI agar menampilkan label yang jelas, misal: "Laporan 2024 (Mode: Accrual)".

---

### 5. RENCANA AKSI (STEP-BY-STEP)

#### Tahap 1: Migrasi Database & Perbaikan Data (Data Cleaning)
1.  Eksekusi penambahan kolom `report_year` ke tabel yang dibutuhkan.
2.  **Fix 2030**: Menjalankan script otomatis untuk mengubah data tahun 2030 kembali ke tahun 2024 atau sesuai tanggal aslinya.
3.  **Backfill**: Mengisi `report_year` yang kosong berdasarkan tahun dari tanggal transaksi sebagai data awal.

#### Tahap 2: Update Backend API
1.  Modifikasi `backend/routes/reports/annual.py` untuk mendukung dual-filter.
2.  Update fungsi `to_dict()` di setiap model agar menyertakan `report_year`.
3.  Update endpoint POST/PUT agar wajib memproses field `report_year`.

#### Tahap 3: Update Frontend Flutter
1.  Update Model data di Flutter agar mengenali field `reportYear`.
2.  Modifikasi Dialog "Tambah/Edit" untuk semua modul agar menyertakan pilihan Tahun Laporan.
3.  Implementasi UI filter baru pada halaman list dan laporan tahunan.

---

### 6. DAMPAK DAN KEUNTUNGAN
*   **Akurasi Pajak**: Pajak terutang (Accrued Tax) dapat tercatat dengan benar di tahun project yang bersangkutan meskipun dibayar di tahun berbeda.
*   **Kerapihan Administrasi**: Settlement yang telat diurus tetap bisa dimasukkan ke buku laporan tahun berjalan tanpa merusak data histori tahun sebelumnya.
*   **Fleksibilitas**: User memiliki kendali penuh untuk melihat performa perusahaan dari sudut pandang Arus Kas (Actual) maupun Kinerja Tahunan (Laporan).
*   **Data Integrity**: Menghilangkan data "sampah" tahun 2030 dan memperbaiki mismatch data 107 settlement tahun 2024.

---
*Dibuat pada: 27 April 2026*
*Status: Final Blueprint / Siap Eksekusi Tahap 1*
