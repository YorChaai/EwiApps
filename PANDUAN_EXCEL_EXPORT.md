# Panduan Lengkap: Sistem Export Excel & PDF

Semua logika ekspor ada di satu file: `backend/routes/reports.py` (1977 baris).
File template Excel ada di folder `excel/`.

---

## Ringkasan: Ada 9 Jenis Export

| Endpoint | Format | Siapa bisa | Tombol di mana |
|---|---|---|---|
| `GET /api/reports/excel` | Excel (.xlsx) | Manager | ReportScreen |
| `GET /api/reports/excel_advance` | Excel (.xlsx) | Semua | MyAdvancesScreen |
| `GET /api/reports/annual/excel` | Excel (.xlsx) | Manager | AnnualReportScreen |
| `GET /api/reports/summary/pdf` | PDF | Manager | ReportScreen |
| `GET /api/reports/advance/<id>/pdf` | PDF | Pemilik/Manager | AdvanceDetailScreen |
| `GET /api/reports/settlement/<id>/receipt` | PDF | Pemilik/Manager | SettlementDetailScreen |
| `GET /api/reports/settlements/pdf` | PDF (bulk) | Manager | Dashboard |
| `GET /api/reports/advances/pdf` | PDF (bulk) | Manager | Dashboard |
| `GET /api/reports/annual/pdf` | PDF | Semua | AnnualReportScreen |

---

## 1. Export Summary Excel (`/api/reports/excel`)

**Dibuat dari nol** (tidak pakai template). Semua data di-generate oleh Python.

### Cara kerjanya:
1. Ambil semua **kategori leaf** (kategori paling bawah, tidak punya anak) dari DB, urutkan by `code`.
2. Ambil semua Expense yang **status = `approved`**, filter by tanggal.
3. Buat workbook Excel baru, dengan header kolom:

```
Tanggal | # | Deskripsi | Karyawan | Judul Settlement | Sumber | Jumlah | Mata Uang | Kurs | [Kategori1] | [Kategori2] | ...
```

4. Setiap Expense jadi **1 baris**. Angka diisi di kolom kategori yang sesuai.

### Poin penting:
- Kolom kategori **dinamis** — jumlahnya tergantung berapa kategori leaf yang ada di DB.
- Jika kategori baru ditambah di DB, kolom baru otomatis muncul di Excel.
- Hanya expense `approved` yang masuk.

---

## 2. Export Kasbon Excel (`/api/reports/excel_advance`)

**Dibuat dari nol**, mirip dengan Export Summary tapi untuk data `Advance`.

### Cara kerjanya:
1. Ambil semua **Advance** yang `status = approved`, filter by tanggal disetujui.
2. Setiap Advance jadi **1 baris**, header:

```
Tanggal Disetujui | Deskripsi Kasbon | Karyawan | Judul Kasbon | [Kategori1] | [Kategori2] | ...
```

3. AdvanceItem di dalam satu Advance di-aggregate per kategori (dijumlahkan), bukan per-item.

### Poin penting:
- Kalau satu Advance punya 3 item dengan kategori yang sama, nilainya dijumlah ke satu kolom.

---

## 3. Export Annual Excel (`/api/reports/annual/excel`) — Paling Kompleks ⚠️

Ini adalah fitur **paling rumit** di seluruh proyek. Cara kerjanya sangat berbeda dari yang lain.

### Konsep Kunci: Template-Based Writing

Tidak dibuat dari nol. Backend **membuka file template Excel** yang sudah ada, lalu **menimpa data** di sel-sel tertentu, lalu mengirimkan file itu ke user.

### File Template
Berada di folder `excel/`. Backend mencarinya dalam urutan prioritas ini:

```
1. [Nama file yang diimpor dari Excel asli]   (dari tabel report_entry_tags)
2. Revenue-Cost_2024_cleaned_asli_cleaned.xlsx
3. Revenue-Cost_2024_cleaned.xlsx
```

> ⚠️ **PENTING**: Kalau file template dihapus atau diubah strukturnya, export Annual Excel akan gagal atau hasilnya kacau!

### Struktur Template Excel

Template punya beberapa sheet:
- **`Revenue-Cost_2024`**: Sheet utama, berisi 3 tabel besar yang sudah diformat
- **`Laba rugi -2024`**: Sheet ringkasan laba/rugi per bulan
- **`Business Summary`**: Sheet ringkasan bisnis keseluruhan

### Bagaimana Data Ditulis ke Template?

#### Tabel 1: Revenue (Baris 8–21 di template)

```python
# Setiap revenue jadi 1 baris, maks 14 revenue
for idx, r in enumerate(revenues[:14], 1):
    row_num = 7 + idx   # Revenue ke-1 → baris 8, ke-2 → baris 9, dst.
    ws.cell(row_num, col=2).value = tanggal_invoice
    ws.cell(row_num, col=4).value = deskripsi
    ws.cell(row_num, col=6).value = invoice_value
    # ... dan seterusnya sampai kolom 16
```

- Baris 22 = TOTAL (formula SUM)
- Kalau data < 14, baris yang tidak terpakai di-hidden

#### Tabel 2: Pajak (Baris 27–36 di template)

```python
# Maks 10 data pajak
for idx, t in enumerate(taxes[:10], 1):
    row_num = 26 + idx   # Pajak ke-1 → baris 27, dst.
```

- Baris 37 = TOTAL pajak

#### Tabel 3: Pengeluaran Summary (Baris 41–96 di template)

Ini yang paling kompleks. Ada dua jenis pengeluaran:

**a) Single Settlement** → masuk ke Tabel 3 (summary, 1 baris per expense)
- Backend melihat baris mana di template yang punya nomor urut (kolom 3)
- Expense dikembalikan ke baris aslinya (berdasarkan catatan `Imported from row X` di kolom notes)

**b) Batch Settlement** → masuk ke blok "Expense#N" di bawah Tabel 3
- Template punya blok-blok bernama `Expense#1`, `Expense#2`, dll.
- Setiap batch settlement mengisi blok yang sesuai
- Backend membaca blok mana yang ada, lalu mengisi datanya

### Mapping Kategori → Kolom

Ini adalah bagian **paling kritis yang hardcoded**. Fungsi `_map_expense_category_index_from_name()` menentukan expense masuk ke kolom berapa di template:

```
Index 0 → kolom 9  → Biaya Operasi
Index 1 → kolom 10 → Biaya Research
Index 2 → kolom 11 → Biaya Sewa Peralatan
Index 3 → kolom 12 → Biaya Interpretasi Log Data
Index 4 → kolom 13 → Administrasi
Index 5 → kolom 14 → Pembelian Barang
Index 6 → kolom 15 → Sewa Kantor
Index 7 → kolom 16 → Kesehatan
Index 8 → kolom 17 → Bisnis Dev
```

Mapping berdasarkan **keyword di nama kategori**:
```python
# Contoh:
if 'operasi' in nama_kategori or 'transport' in nama_kategori:
    → index 0 (Biaya Operasi)
if 'interpretasi' in nama_kategori or 'log data' in nama_kategori:
    → index 3 (Biaya Interpretasi)
```

> ⚠️ **RISIKO**: Kalau nama kategori di DB tidak mengandung keyword ini, expense akan salah masuk ke "Biaya Operasi" (default / fallback).

### Sistem Cache Annual Report

Backend **menyimpan cache** di folder `exports/annual_cache/`:
- `annual_2024.json` — data payload dari DB
- `annual_2024.pdf` — file PDF yang sudah di-render

Skenario:
- Tanpa `?refresh=true` → pakai cache (cepat tapi bisa stale)
- Dengan `?refresh=true` → rebuild dari DB, update cache

> ⚠️ **Kalau data sudah diubah di DB tapi laporan tahunan tidak berubah**, kemungkinan cache belum direfresh. Solusi: tekan tombol "Refresh" di UI, atau hapus manual file di `exports/annual_cache/`.

### Sheet Sekunder (Laba Rugi & Business Summary)

Backend mencoba mengambil sheet ini dari file **donor template** kalau sudah ada di folder `excel/`. Kalau tidak ada template donor, sheet dibuat dari scratch oleh fungsi `_write_secondary_summary_sheets()`.

---

## 4. Export PDF

Semua PDF dibuat menggunakan library **ReportLab** (dibuat dari nol, tanpa template).

| PDF | Isi | Baris kode di reports.py |
|---|---|---|
| Summary PDF | Tabel ringkasan kategori per bulan | ~305–371 |
| Advance PDF | Header kasbon + tabel AdvanceItem | ~567–629 |
| Settlement Receipt PDF | Header settlement + tabel semua Expense | ~632–699 |
| Bulk Settlement PDF | Daftar semua settlement | ~702–755 |
| Bulk Advance PDF | Daftar semua advance | ~758–809 |
| Annual PDF | 3 tabel besar (Revenue, Pajak, Pengeluaran) | ~1136–1325 |

---

## 5. Helper Functions Penting (Wajib Tahu)

| Fungsi | Tujuan |
|---|---|
| `_safe_set_cell(ws, row, col, val)` | Tulis ke sel Excel, tapi SKIP kalau sel adalah merged cell |
| `_safe_set_number(ws, row, col, val)` | Sama tapi paksa format angka (bukan tanggal) |
| `_normalize_external_formula_refs(wb)` | Perbaiki formula Excel yang merujuk ke file eksternal |
| `_clear_range(ws, r1, r2, c1, c2)` | Kosongkan rentang sel (termasuk formula) |
| `_clear_data_keep_formulas(ws, ...)` | Kosongkan sel tapi pertahankan formula `=...` |
| `_set_rows_hidden(ws, r1, r2, hidden)` | Sembunyikan/tampilkan baris |
| `_map_expense_category_index_from_name(name)` | Mapping nama kategori → index kolom template |
| `_group_annual_expenses(expenses, year)` | Kelompokkan expense by settlement, sort by tanggal |
| `_extract_imported_row(notes)` | Baca "Imported from row X" dari field notes expense |
| `_is_batch_settlement(type, title)` | Cek apakah settlement bertipe batch |
| `_get_expense_blocks(ws)` | Temukan blok "Expense#N" di template |

---

## 6. Batas Kapasitas Template

> ⚠️ Template Excel punya batas baris **hardcoded**. Kalau data melebihi batas, kelebihan data TIDAK akan muncul di Annual Excel!

| Tabel | Batas Maks |
|---|---|
| Revenue (Tabel 1) | 14 baris (baris 8–21) |
| Pajak (Tabel 2) | 10 baris (baris 27–36) |
| Summary Pengeluaran (Tabel 3) | ~56 baris (baris 41–96) |
| Batch Expense Blocks | Tergantung jumlah blok `Expense#N` di template |

---

## 7. Hal Penting Lain yang Perlu Diketahui

### a) Sistem Kategori Bertingkat (Parent-Child)
- Kategori punya kolom `parent_id` — bisa ada parent dan child
- Fungsi `_root_category_name()` naik dari child sampai menemukan root
- Di laporan Annual, yang dipakai adalah nama **root category** (bukan leaf)
- Di laporan Summary Excel, yang dipakai adalah **leaf category**
- **Inkonsistensi ini perlu diketahui!**

### b) Sistem `report_entry_tags` (Tabel Tersembunyi di DB)
- Ada tabel `report_entry_tags` di DB yang **tidak ada di `models.py`**
- Dibuat otomatis saat import dari Excel via script `excel_to_app_db.py`
- Fungsinya: "tag" row mana saja yang termasuk laporan tahun tertentu
- Kalau tabel ini ada data, sistem akan **pakai tag** bukan filter by tahun biasa
- Kalau tabel ini kosong, sistem akan filter by `extract(year, date) == year`

### c) Multi-Currency Support
- Expense bisa dalam mata uang asing (USD, dll)
- Ada kolom `currency` dan `currency_exchange` (kurs)
- Konversi ke IDR pakai fungsi `_idr_from_currency(amount, currency, exchange)`
- Properti `expense.idr_amount` di model sudah menghitung ini otomatis

### d) Settlement Type: `single` vs `batch`
- **Single**: Settlement dengan 1 expense. Terjadi jika pada saat impor dari Excel, item berada di baris mandiri (standalone) sebelum header "Expense#1". Masuk ke Tabel 3 summary di Annual Excel.
- **Batch**: Settlement dengan banyak expense. Terjadi jika item berada di bawah blok "Expense#N". Semua item di bawah 1 header dikelompokkan ke dalam 1 settlement. Masuk ke blok `Expense#N` di Annual Excel.
- Dibedakan oleh kolom `settlement_type` di tabel `settlements`.

### e) Normalisasi Subkategori
- Saat impor file Excel (lewat `excel_to_app_db.py`), deskripsi expense (jika ada) akan di-scan.
- Jika ada teks subkategori (misal "Transportation", "Logictic", dsb.) script akan menormalisasi teks tersebut menggunakan `FULL_MAPPING` ke 13 Standard Subcategories.
- Kategori yang didapatkan akan dipetakan ke root parent-nya (misal "Transportation" ke "Biaya Operasi").
