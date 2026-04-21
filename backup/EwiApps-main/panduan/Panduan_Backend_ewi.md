# Panduan Backend EWI (Revisi Menyeluruh)

Dokumen ini menjelaskan backend aktif pada folder `backend/` berdasarkan kondisi sistem saat ini, termasuk perubahan notifikasi role-based, settlement/kasbon, laporan tahunan, dividen, dan setting aplikasi.

Fokus dokumen:
- Struktur sistem dan alur data antar modul.
- Peran setiap `class` dan `def` penting.
- Kapan fungsi dipakai, kenapa dipakai, dan dampaknya ke alur pengguna.

## 1. Struktur Backend Aktual

Folder inti yang aktif:
- `backend/app.py`: bootstrap Flask, registrasi blueprint, seed data, dan migrasi ringan saat startup.
- `backend/config.py`: konfigurasi environment backend.
- `backend/models.py`: model SQLAlchemy untuk seluruh entitas bisnis.
- `backend/routes/*.py`: endpoint API per domain.
- `backend/routes/reports/*.py`: endpoint laporan summary/annual + helper Excel/PDF.
- `backend/scripts/*.py`: util konversi dan maintenance data.

Blueprint API yang dipakai:
- `auth`, `dashboard`, `settlements`, `expenses`, `advances`, `categories`, `revenues`, `taxes`, `settings`, `dividends`, `notifications`, `reports`.

## 2. Model (class) dan Peran Bisnisnya

File: `backend/models.py`

### `class User`
Peran:
- Menyimpan identitas akun, role, dan autentikasi.
- Menjadi sumber kontrol hak akses manager/staff/mitra.
Dipakai ketika:
- Login (`routes/auth.py`), filter data berdasar pemilik, dan routing notifikasi.
Method penting:
- `set_password(password)`: hash password sebelum simpan; dipakai saat buat user.
- `check_password(password)`: validasi login.
- `to_dict()`: serialisasi user untuk respons API.

### `class Category`
Peran:
- Menyimpan hirarki kategori expense (parent-child) dan status approval kategori.
Dipakai ketika:
- Input item kasbon/expense settlement, laporan summary/annual.

### `class Advance` dan `class AdvanceItem`
Peran:
- `Advance`: header dokumen kasbon (status, requester, tipe single/batch, revisi).
- `AdvanceItem`: item nominal detail pada setiap kasbon/revisi.
Dipakai ketika:
- Flow buat kasbon, submit, approve/reject manager, revisi 1/2, konversi ke settlement.
Method penting di `Advance`:
- `total_amount`, `approved_amount`, `base_amount`, `revision_amount`, `max_revision_no`.
Alasan method ini ada:
- Untuk menghitung agregasi bisnis tanpa duplikasi logika di setiap route.

### `class Settlement` dan `class Expense`
Peran:
- `Settlement`: header realisasi (single/batch) dari pengeluaran.
- `Expense`: item realisasi dengan bukti, checklist reject, approved flag, kurs.
Dipakai ketika:
- Draft -> submit -> approve/reject -> complete settlement.
Method penting:
- `Expense.idr_amount`: normalisasi nilai ke IDR agar laporan konsisten.

### `class Revenue`, `class Tax`
Peran:
- Menyimpan data pemasukan dan pajak per tahun/periode.
Dipakai ketika:
- Laporan summary, annual report, dan modul input revenue/pajak.
Method:
- `idr_invoice_value`, `idr_amount_received`, `idr_transaction_value` dipakai untuk konsolidasi angka IDR lintas mata uang.

### `class Dividend`, `class DividendSetting`
Peran:
- `Dividend`: daftar penerima dividen.
- `DividendSetting`: parameter tahunan (profit retained + field neraca) yang dipakai annual report.
Dipakai ketika:
- `Input Dividen`, `Input Neraca`, dan pembentukan payload annual.

### `class Notification`
Peran:
- Menyimpan notifikasi per user: sumber aksi, target object, status baca, dan `link_path`.
Dipakai ketika:
- Push informasi submit/approve/reject dan deep-link ke detail kasbon/settlement.

## 3. Bootstrap dan Migrasi Ringan (app.py)

File: `backend/app.py`

### `def create_app()`
Peran:
- Titik masuk backend Flask.
Yang dilakukan:
- Inisialisasi Flask, DB, JWT, CORS.
- Registrasi seluruh blueprint.
- Menjalankan fungsi migrasi ringan.
- Menyiapkan seed data awal.
Kapan dipakai:
- Selalu saat backend start.

### Fungsi compatibility/migration ringan
- `_extract_sqlite_path`, `_looks_hashed`: util internal parsing URI/password hash.
- `ensure_advance_type_column`, `ensure_advance_revision_schema`: menjaga DB lama tetap kompatibel untuk fitur revisi kasbon.
- `ensure_expense_advance_link_schema`: menambah relasi yang dibutuhkan sinkronisasi kasbon-settlement.
- `ensure_settlement_status_compatibility`: normalisasi status lama agar tidak pecah di UI/filter.
- `ensure_bank_subcategory`, `ensure_rental_tool_subcategory`: memastikan kategori wajib tersedia.
- `ensure_dividends_table`: menjaga tabel dividen/setting ada saat startup.
- `bootstrap_from_database_new`: fallback bootstrap data dari DB cadangan.
- `seed_data`: akun/admin dan master data awal.

Kenapa pendekatan ini dipakai:
- Agar deployment lokal/offline tetap jalan walau tanpa pipeline migrasi formal.
- Mengurangi error saat update aplikasi di mesin user non-teknis.

## 4. Endpoint Domain dan Detail `def`

### 4.1 Auth (`routes/auth.py`)
- `login`: verifikasi kredensial, generate JWT, kirim data user.
- `me`: ambil profil user login aktif.
- `list_users`: daftar user (umumnya manager).
- `create_user`: tambah user baru.

### 4.2 Dashboard (`routes/dashboard.py`)
- `get_summary`: ringkasan angka untuk dashboard/sidebar badge (pending, expense bulan ini, dll).

### 4.3 Settlement (`routes/settlements.py`)
Helper internal:
- `_sync_advance_after_settlement`: sinkron status kasbon terkait setelah settlement berubah.
- `_parse_checklist_notes`: parsing checklist reject dari field catatan.
- `_has_unchecked_checklist`: validasi checklist reject manager sudah lengkap.

Endpoint:
- `list_settlements`: daftar settlement dengan filter role/status/tahun/search.
- `create_settlement`: buat settlement baru (single/batch).
- `get_settlement`: detail settlement + item.
- `update_settlement`: update header settlement draft.
- `update_expense`: update item expense pada settlement.
- `delete_settlement`: hapus settlement sesuai aturan status/hak akses.
- `submit_settlement`: draft -> submitted.
- `approve_settlement`: approve settlement (validasi item dan checklist).
- `complete_settlement`: finalisasi settlement.
- `_merge_rejection_notes_settlement`: gabung catatan reject agar histori tidak hilang.
- `reject_all_expenses`: reject settlement + catatan alasan.
- `move_to_draft`: rollback status ke draft saat diizinkan.

### 4.4 Expense (`routes/expenses.py`)
Helper:
- `allowed_file`: validasi ekstensi file bukti.
- `_parse_checklist_notes`: parse checklist JSON/text.
- `_merge_rejection_notes`: merge histori reject item.

Endpoint:
- `create_expense`: tambah item expense + upload evidence.
- `update_expense`: edit item.
- `bulk_delete_expenses`: hapus banyak item sekaligus.
- `delete_expense`: hapus satu item.
- `approve_expense`: approve per-item.
- `reject_expense`: reject per-item.
- `serve_evidence`: serve file bukti.
- `list_categories`: helper endpoint kategori untuk form expense.

### 4.5 Kasbon / Advance (`routes/advances.py`)
Helper penting:
- `_advance_view_status_filter`: konversi status filter UI ke query.
- `_editable_revision_no`: tentukan revisi yang masih boleh diedit.
- `_items_for_revision`: ambil item per revision number.
- `_settlement_blocks_revision`: cegah revisi saat sudah terkunci settlement.
- `_sync_revision_items_to_settlement`: sinkron item revisi ke settlement terkait.
- `_next_revision_no`, `_status_after_approval`: kalkulasi status transisi bisnis.
- `_parse_checklist_notes`, `_has_unchecked_checklist`: validasi checklist manager.
- `_merge_rejection_notes_advance`: simpan histori penolakan.

Endpoint:
- `list_advances`, `create_advance`, `get_advance`, `update_advance`, `delete_advance`.
- `start_revision`: mulai revisi kasbon.
- `add_advance_item`, `update_advance_item`, `delete_advance_item`, `bulk_delete_advance_items`.
- `submit_advance`, `approve_advance`, `reject_advance`.
- `create_settlement_from_advance`: buat settlement dari kasbon approved.
- `approve_advance_item`, `reject_advance_item`: approval item-level.
- `move_advance_to_draft`: rollback status ke draft sesuai aturan.

### 4.6 Kategori (`routes/categories.py`)
- `list_categories`: ambil kategori approved untuk pemakaian umum.
- `list_pending`: daftar kategori pending untuk manager.
- `create_category`: buat kategori parent/child.
- `update_category`, `delete_category`.
- `approve_category`: approve/reject kategori pending.

### 4.7 Revenue (`routes/revenues.py`)
- `_parse_date`: normalisasi input tanggal.
- `get_revenues`, `get_revenue`, `create_revenue`, `update_revenue`, `delete_revenue`.

### 4.8 Tax (`routes/taxes.py`)
- `_parse_date`.
- `get_taxes`, `get_tax`, `create_tax`, `update_tax`, `delete_tax`.

### 4.9 Dividen dan Neraca (`routes/dividends.py`)
Helper:
- `_parse_date`.
- `_compute_profit_after_tax(year)`: hitung laba bersih dari revenue-tax-expense.
- `_build_dividend_payload(year)`: gabungkan penerima, retained profit, distribusi, setting neraca.

Endpoint:
- `get_dividends`: payload tahunan untuk layar dividen/neraca.
- `get_dividend`, `create_dividend`, `update_dividend`, `delete_dividend`.
- `update_dividend_setting(year)`: simpan field neraca tahunan + retained profit.

### 4.10 Notifikasi (`routes/notifications.py`)
- `get_notifications`: daftar notifikasi milik user login.
- `_can_access_notification`: guard akses notifikasi per role/owner.
- `mark_notification_as_read`, `mark_all_notifications_as_read`.
- `delete_notification`.
- `get_unread_count`.
- `create_notification`: util membuat notifikasi terstruktur.
- `notify_managers`: kirim notifikasi ke semua manager (untuk event penting lintas user).
- `notify_staff`: kirim notifikasi spesifik user.

Catatan behavior terbaru:
- Manager menerima notifikasi global yang relevan untuk pengawasan.
- Staff/mitra hanya menerima notifikasi dari aktivitas miliknya.
- `link_path` dipakai frontend untuk tombol "Buka Settlement/Kasbon".

### 4.11 Settings (`routes/settings.py`)
- `manage_storage`: baca/ubah direktori penyimpanan lampiran.
- `manage_report_year`: baca/ubah default tahun laporan.

### 4.12 Reports Summary (`routes/reports/summary.py`)
Helper:
- `_display_settlement_status`, `_get_summary_approved_expenses`, `_build_summary_payload`.
Endpoint:
- `get_summary_report`: tabel summary kategori per bulan.
- `export_summary_pdf`: PDF summary.
- `generate_excel_report`: Excel settlement.
- `generate_excel_advance_report`: Excel kasbon.
- `generate_pdf_advance_report`: PDF kasbon tertentu.
- `generate_settlement_receipt`: receipt settlement.
- `generate_bulk_settlements_pdf`, `generate_bulk_advances_pdf`: export massal.

### 4.13 Reports Annual (`routes/reports/annual.py`)
Helper inti:
- Mapping dan normalisasi subkategori: `_extract_expense_subcategory`, `_normalize_subtitle`, `_mapped_expense_subcategory_from_text`, `_single_summary_subcategory`, `_expense_column_mapping_name`.
- Cache payload/file: `_annual_cache_paths`, `_load_annual_payload_cache`, `_save_annual_payload_cache`, `_save_annual_pdf_cache`.
- Tagging dan dataset: `_tagged_ids_for_year`, `_has_any_report_tags`.
- Perhitungan dividen: `_compute_dividend_distribution`.
- Builder laporan: `_build_annual_payload_from_db`, `_build_annual_pdf_bytes`.
- Sinkron template Excel: `_write_secondary_summary_sheets`, `_sync_formatted_secondary_sheets`, `_clone_sheet_from_template`, `_ensure_formatted_secondary_sheets`.

Endpoint:
- `get_annual_report`: payload annual JSON untuk layar frontend.
- `get_annual_report_pdf`: export PDF annual.
- `get_annual_report_excel`: export workbook annual (sheet utama + secondary summary).

Kenapa modul annual banyak helper:
- Karena proses annual menggabungkan transformasi data bisnis, formatting Excel template, dan sinkron formula lintas sheet.

## 5. Script Konversi dan Util Data

### `scripts/excel_to_app_db.py`
Peran:
- Import data workbook lama ke DB aplikasi.
Fungsi penting:
- `ensure_schema`, `ensure_reference_data`, `purge_year_data`.
- `import_revenues`, `import_taxes`, `import_expenses`.
- `detect_category_id`, `detect_expense_value_column`.
Kapan dipakai:
- Migrasi awal data historis atau reimport data tahunan.

### `scripts/clean_subcategory.py`
Peran:
- Menormalkan label subkategori agar konsisten untuk grouping annual.
Fungsi:
- `parse_args`, `clean_subcategories`, `main`.

### `scripts/gen_restore.py`
Peran:
- Generator restore/import alternatif untuk skenario data recovery.

## 6. Alur End-to-End (Ringkas)

1. Staff membuat kasbon (`advances`), menambah item, lalu submit.
2. Manager approve/reject kasbon; notifikasi otomatis dibuat.
3. Kasbon approved bisa dibuatkan settlement.
4. Staff input expense realisasi; manager approve/reject sampai valid.
5. Settlement complete mengunci realisasi.
6. Laporan summary/annual menarik data approved/completed + revenue + tax + setting dividen/neraca.
7. Frontend notifikasi memakai `link_path` untuk deep-link ke data terkait.

## 7. Checklist Sinkronisasi Saat Ada Perubahan Backend

Setiap ada perubahan endpoint/model, pastikan:
- Kontrak API di `frontend/lib/services/api_service.dart` masih sama.
- Provider frontend yang konsumsi endpoint ikut diperbarui.
- Filter role (manager vs staff/mitra) diuji ulang.
- Export PDF/Excel diuji dengan data real.
- Notifikasi diuji termasuk mark read, delete, dan tombol deep-link.
