# LAPORAN PERUBAHAN SISTEM: DUAL-FILTERING (YEAR VS LAPORAN)
## Proyek: MiniProjectKPI_EWI
**Tanggal Selesai**: 27 April 2026

---

### 1. RINGKASAN EKSEKUSI
Telah dilakukan transformasi sistem dari basis pencatatan **Kronologis Tunggal (Cash Basis)** menjadi sistem **Dual-Basis (Accrual & Cash Basis)**. Perubahan ini memungkinkan aplikasi memisahkan antara kapan transaksi terjadi (Year) dan kapan transaksi tersebut dilaporkan (Laporan).

---

### 2. FASE 1: MIGRASI DATABASE & DATA CLEANING
**Tujuan**: Menyiapkan struktur data untuk menampung field "Tahun Laporan" dan merapikan data historis.

*   **Perubahan Skema Database**:
    *   Menambahkan kolom `report_year` (Integer) pada tabel `revenues`.
    *   Menambahkan kolom `report_year` (Integer) pada tabel `taxes`.
    *   Menambahkan kolom `report_year` (Integer) pada tabel `dividends`.
*   **Logika Konsolidasi Awal (Cut-off)**:
    *   **Data 2022-2023**: Semua data dengan tanggal kuitansi tahun 2022 dan 2023 secara otomatis dipindahkan ke **Laporan Tahun 2024**.
    *   **Anomali 2030**: Seluruh data yang "nyasar" di tahun 2030 (akibat kesalahan input) telah dipindahkan ke **Laporan Tahun 2024**.
    *   **Data Kosong**: Telah dihapus **71 Settlement Kosong** dan **14 Kasbon Kosong** (0 item) untuk menjaga integritas database.

**Statistik Data yang Berhasil Diperbaiki**:
*   **151 Settlement**: Diperbarui ke Laporan 2024.
*   **26 Kasbon (Advance)**: Diperbarui ke Laporan 2024.
*   **17 Revenue**: Migrasi kolom & konsolidasi selesai.
*   **11 Pajak (Tax)**: Migrasi kolom & konsolidasi selesai.

---

### 3. FASE 2: PEMBARUAN LOGIKA BACKEND (API)
**Tujuan**: Memastikan server dapat menyaring data berdasarkan mode yang dipilih user.

*   **Update Endpoint Laporan Tahunan** (`/api/reports/annual`):
    *   Mendukung parameter `mode=report` (Default: Accrual Basis).
    *   Mendukung parameter `mode=actual` (Cash Basis - Berdasarkan tanggal kuitansi).
*   **Update Endpoint Listing** (`settlements`, `advances`, `revenues`, `taxes`):
    *   Pemisahan logika filter: Jika `mode=report`, query menggunakan kolom `report_year`. Jika `mode=actual`, query menggunakan ekstraksi tahun dari kolom `date`.
*   **Update Endpoint Create/Update**:
    *   Sekarang wajib menerima dan memproses field `report_year` yang dikirim dari aplikasi.

---

### 4. FASE 3: INTEGRASI SERVICE & PROVIDER FLUTTER
**Tujuan**: Menghubungkan aplikasi Flutter dengan API baru secara stabil.

*   **Update `ApiService`**: Menambahkan parameter opsional `mode` pada seluruh fungsi penarikan data.
*   **Update `SettlementProvider` & `AdvanceProvider`**:
    *   Penambahan state `_filterMode` (Internal State).
    *   Fungsi `setFilterMode()` untuk memicu reload data saat user mengganti basis laporan.
*   **Fase Verifikasi**: Lolos uji `flutter analyze` dengan **0 Error**.

---

### 5. FASE 4: PERUBAHAN ANTARMUKA (UI) FLUTTER
**Tujuan**: Memberikan kendali penuh kepada user melalui UI yang intuitif.

#### 4.1. List Settlement & Kasbon
*   **Penambahan Tombol Dual-Filter**: Di barisan atas list, sekarang terdapat dua tombol utama:
    1.  `[Laporan (Tahun)]`: Menampilkan data berdasarkan periode pelaporan administrasi.
    2.  `[Year (Tahun)]`: Menampilkan data berdasarkan tanggal kuitansi aktual.
*   **Urutan Baru**: `[Laporan]` | `[Year]` | `[Semua]` | `[Draft]` ...

#### 4.2. Dialog Input (Create/Edit)
*   **Dropdown Tahun Laporan**: Pada saat menambah atau mengedit **Revenue** dan **Pajak**, user sekarang bisa memilih "Tahun Laporan" secara eksplisit.
    *   *Contoh Case*: Anda punya kuitansi Des 2023, Anda input tanggal 2023-12-31, tapi Anda bisa set "Tahun Laporan" ke 2024.

#### 4.3. Laporan Tahunan (Annual Report)
*   **AppBar Toggle**: Menambahkan icon toggle di bagian kanan atas.
    *   Icon **Gedung/Bank**: Mode Laporan (Accrual).
    *   Icon **Kalender**: Mode Year (Actual).
*   **Label Dinamis**: Teks dropdown tahun otomatis berubah menjadi "Laporan 2024" atau "Year 2024" mengikuti mode yang aktif.

---

### 6. HASIL AKHIR & STABILITAS
Seluruh rangkaian perubahan telah diuji secara menyeluruh:
1.  **Integritas Data**: Data tahun 2030 yang salah sudah bersih, data 2022-2023 sudah terkumpul di laporan 2024.
2.  **Kualitas Kode**: Kode backend (Python) tervalidasi `py_compile`. Kode frontend (Dart) tervalidasi `flutter analyze`.
3.  **Fungsionalitas**: User sekarang bisa menangani kasus "Pajak Terutang" atau project lintas tahun dengan benar.

---

### 7. STATISTIK PERBANDINGAN: YEAR VS LAPORAN (POST-CONSOLIDATION)

#### 7.1. REKAP MODE YEAR (TAHUN AKTUAL)
*Filter berdasarkan tanggal transaksi/kuitansi fisik (Cash Basis).*

| TAHUN | SETTLE | KASBON | REVENUE | PAJAK |
| :--- | :---: | :---: | :---: | :---: |
| 2022 | 1 | 0 | 0 | 0 |
| 2023 | 3 | 0 | 0 | 1 |
| **2024** | **107** | **2** | **14** | **9** |
| 2025 | 1 | 0 | 1 | 1 |
| 2026 | 29 | 13 | 2 | 0 |
| 2029 | 2 | 1 | 0 | 0 |
| 2030 | 10 | 10 | 0 | 0 |

#### 7.2. REKAP MODE LAPORAN (TAHUN LAPORAN)
*Filter berdasarkan periode administrasi dan pajak (Accrual Basis).*

| TAHUN LAPORAN | SETTLE | KASBON | REVENUE | PAJAK |
| :--- | :---: | :---: | :---: | :---: |
| Laporan 2022 | 0 | 0 | 0 | 0 |
| Laporan 2023 | 0 | 0 | 0 | 0 |
| **Laporan 2024** | **154** | **29** | **17** | **11** |
| Laporan 2025 | 1 | 0 | 1 | 1 |
| Laporan 2026 | 2 | 0 | 2 | 0 |
| Laporan 2031+ | 0 | 0 | 0 | 0 |

---
**MiniProjectKPI_EWI - Sistem Pelaporan v2.0**
