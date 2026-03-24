# Catatan Proyek MiniProjectKPI_EWI

Dokumen ini dibuat dari pembacaan source code langsung (backend + frontend) agar kamu bisa takeover project dengan cepat.

## 1. Gambaran Umum

Aplikasi ini adalah sistem manajemen keuangan operasional dengan alur:
1. User login (JWT)
2. User buat `Advance` (kasbon) + item rencana biaya
3. Manager approve/reject kasbon
4. User buat `Settlement` (realisasi pengeluaran) dari kasbon approved
5. User input `Expense` (nota aktual)
6. Manager approve/reject expense/settlement
7. Data diekspor ke laporan Summary/Annual (Excel/PDF)
8. Manager mengelola Revenue, Tax, dan Dividen

**Fitur Utama:**
- Advance/Kasbon dengan support revisi (Revisi 1, Revisi 2)
- Settlement dengan link ke Advance
- Expense dengan multi-currency dan upload evidence
- Kategori parent-child dengan approval workflow
- Revenue & Tax management
- Dividen dengan settings per tahun
- Export laporan Summary, Annual, Advance, Settlement (Excel/PDF)
- Dashboard dengan summary cards dan notification badges
- Search dan filter data
- Role-based access (Manager, Staff, Mitra Eks)

Teknologi utama:
- Backend: Python, Flask, SQLAlchemy, JWT, OpenPyXL, ReportLab, SQLite
- Frontend: Flutter (Dart), Provider, HTTP, Shared Preferences

---

## 2. Struktur Folder Penting

- `backend/` : API, model DB, logika bisnis, export laporan
- `frontend/lib/` : UI Flutter, provider state management, API client
- `excel/` : template Excel laporan tahunan
- `data/` : output laporan + folder penyimpanan lampiran/evidence
- `backend/scripts/` : utilitas import/normalisasi data Excel ke DB

---

## 3. Backend Detail

### 3.1 File Konfigurasi dan Bootstrap

#### `backend/config.py`
Fungsi:
- Menetapkan konfigurasi aplikasi (`SECRET_KEY`, `JWT_SECRET_KEY`)
- Path database SQLite: `backend/database.db`
- Folder upload lampiran: default `D:\2. Organize\1. Projects\MiniProjectKPI_EWI\data`
- `REPORT_DEFAULT_YEAR` (default 2024)
- `MAX_CONTENT_LENGTH` 16MB
- Ekstensi file yang diizinkan (`png/jpg/jpeg/gif/pdf/webp`)

#### `backend/app.py`
Fungsi:
- Inisialisasi Flask + extension (CORS, JWT, SQLAlchemy, Migrate)
- Register blueprint route:
  - `/api/auth`
  - `/api/settlements`
  - `/api/expenses`
  - `/api/reports`
  - `/api/categories`
  - `/api/advances`
  - `/api/settings`
  - `/api/revenues`
  - `/api/taxes`
- Route file upload publik: `/api/uploads/<path:filename>`
- `db.create_all()` saat startup
- `bootstrap_from_database_new()` untuk impor otomatis dari `database_new.db` bila DB kosong
- `seed_data()` untuk user, kategori, revenue, tax default

Catatan penting:
- Ada duplikasi import `from config import Config` (tidak fatal, tapi bisa dirapikan)

#### `backend/requirements.txt`
Dependensi utama backend:
- Flask, Flask-CORS, Flask-SQLAlchemy, Flask-JWT-Extended
- openpyxl, reportlab, Pillow

---

### 3.2 Model Database (`backend/models.py`)

#### `User`
Kolom utama: `username`, `password_hash`, `full_name`, `role`, `created_at`
Role yang dipakai: `manager`, `staff`, `mitra_eks`
Method: `set_password()`, `check_password()`, `to_dict()`
Relasi: `settlements`, `advances`, `notifications_received`, `notifications_created`

#### `Category`
Struktur kategori bertingkat (parent-child)
Kolom: `name`, `code`, `parent_id`, `status`, `created_by`
Status: `approved`, `pending`
Method: `full_name` (property), `to_dict()`
Relasi: `children`, `expenses`

#### `Advance`
Header kasbon
Kolom: `title`, `description`, `advance_type`, `user_id`, `status`, `notes`, `approved_revision_no`, `active_revision_no`, `created_at`, `updated_at`, `approved_at`
Status: `draft`, `submitted`, `approved`, `rejected`, `revision_draft`, `revision_submitted`, `revision_rejected`, `in_settlement`, `completed`
Property: `total_amount`, `approved_amount`, `base_amount`, `revision_amount`, `max_revision_no`
Relasi: `settlement` (one-to-one), `items` (one-to-many), `requester`

#### `AdvanceItem`
Item perencanaan kasbon
Kolom: `advance_id`, `category_id`, `description`, `estimated_amount`, `revision_no`, `evidence_path`, `evidence_filename`, `date`, `source`, `currency`, `currency_exchange`, `status`, `notes`, `created_at`
Method: `to_dict()`
Relasi: `category`, `advance`

#### `Settlement`
Header realisasi pengeluaran
Kolom: `title`, `description`, `user_id`, `settlement_type`, `status`, `advance_id`, `created_at`, `updated_at`, `completed_at`
`settlement_type`: `single` atau `batch`
Status: `draft`, `submitted`, `approved`, `rejected`, `completed`
Property: `total_amount`, `approved_amount`
Relasi: `advance`, `expenses`, `creator`

#### `Expense`
Detail nota pengeluaran
Kolom: `settlement_id`, `category_id`, `description`, `amount`, `date`, `source`, `advance_item_id`, `revision_no`, `currency`, `currency_exchange`, `evidence_path`, `evidence_filename`, `status`, `notes`, `created_at`
Status: `pending`, `approved`, `rejected`
Property: `idr_amount` (hitung otomatis jika multi-currency)
Relasi: `settlement`, `category`, `advance_item`

#### `Revenue`
Pencatatan pemasukan
Kolom: `invoice_date`, `description`, `invoice_value`, `currency`, `currency_exchange`, `invoice_number`, `client`, `receive_date`, `amount_received`, `ppn`, `pph_23`, `transfer_fee`, `remark`, `created_at`
Property: `idr_invoice_value`, `idr_amount_received`
Method: `to_dict()`

#### `Tax`
Pencatatan pajak
Kolom: `date`, `description`, `transaction_value`, `currency`, `currency_exchange`, `ppn`, `pph_21`, `pph_23`, `pph_26`, `created_at`
Property: `idr_transaction_value`
Method: `to_dict()`

#### `Dividend`
Pencatatan dividen
Kolom: `date`, `name`, `amount`, `recipient_count`, `tax_percentage`, `created_at`
Method: `to_dict()`

#### `DividendSetting`
Setting dividen per tahun
Kolom: `year`, `profit_retained`, `opening_cash_balance`, `accounts_receivable`, `prepaid_tax_pph23`, `prepaid_expenses`, `other_receivables`, `office_inventory`, `other_assets`, `accounts_payable`, `salary_payable`, `shareholder_payable`, `accrued_expenses`, `share_capital`, `retained_earnings_balance`, `created_at`
Method: `to_dict()`

#### `Notification`
Notifikasi in-app
Kolom: `user_id`, `actor_id`, `action_type`, `target_type`, `target_id`, `message`, `read_status`, `created_at`, `link_path`
Relasi: `user`, `actor`
Method: `to_dict()`

#### `ManualCombineGroup`
Grouping manual untuk laporan
Kolom: `table_name`, `report_year`, `group_date`, `row_ids_json`, `created_at`
Method: `row_ids()`, `to_dict()`

---

### 3.3 API Route per File

#### `backend/routes/auth.py`
- `POST /api/auth/login` : login, return token + user
- `GET /api/auth/me` : profile user dari token
- `GET /api/auth/users` : list user (manager only)
- `POST /api/auth/users` : create user (manager only)

#### `backend/routes/dashboard.py` (BARU)
- `GET /api/dashboard/summary` : dashboard summary (pending counts, total expenses bulan ini)

#### `backend/routes/notifications.py` (BARU)
- `GET /api/notifications` : list notifikasi user
- `POST /api/notifications/<id>/read` : mark notifikasi sebagai read
- `DELETE /api/notifications/<id>` : hapus notifikasi

#### `backend/routes/dividends.py` (BARU)
- `GET /api/dividends` : list dividen
- `POST /api/dividends` : create dividen (manager only)
- `PUT /api/dividends/<id>` : update dividen (manager only)
- `DELETE /api/dividends/<id>` : delete dividen (manager only)
- `GET /api/dividend-settings` : list settings dividen per tahun
- `POST /api/dividend-settings` : create/update settings dividen

#### `backend/routes/advances.py`
- `GET /api/advances` : list advance + filter `status/start_date/end_date/search`
- `POST /api/advances` : create advance
- `GET /api/advances/<id>` : detail advance + items
- `PUT /api/advances/<id>` : edit advance (owner, draft/rejected)
- `DELETE /api/advances/<id>` : hapus advance draft
- `POST /api/advances/<id>/items` : tambah item kasbon + upload evidence
- `PUT /api/advances/items/<id>` : edit item + replace evidence
- `DELETE /api/advances/items/<id>` : hapus item + file evidence
- `POST /api/advances/<id>/submit` : submit kasbon
- `POST /api/advances/<id>/approve_all` : approve kasbon (manager)
- `POST /api/advances/<id>/reject_all` : reject kasbon (manager)
- `POST /api/advances/<id>/start_revision` : mulai revisi kasbon (manager)
- `POST /api/advances/<id>/create_settlement` : buat settlement dari kasbon approved

#### `backend/routes/settlements.py`
- `GET /api/settlements` : list settlement + filter `status/type/report_year/date/search`
- `POST /api/settlements` : create settlement (single/batch)
- `GET /api/settlements/<id>` : detail settlement + expenses
- `PUT /api/settlements/<id>` : edit settlement
- `DELETE /api/settlements/<id>` : hapus settlement draft
- `POST /api/settlements/<id>/submit` : submit settlement
- `POST /api/settlements/<id>/approve` : approve settlement (manager)
- `POST /api/settlements/<id>/approve_all` : approve seluruh expense (manager)
- `POST /api/settlements/<id>/reject_all` : reject seluruh expense (manager)
- `POST /api/settlements/<id>/complete` : complete settlement (close workflow)

#### `backend/routes/expenses.py`
- `POST /api/expenses` : tambah expense (multipart + evidence)
- `PUT /api/expenses/<id>` : edit expense (status reset ke pending)
- `DELETE /api/expenses/<id>` : hapus expense
- `POST /api/expenses/<id>/approve` : approve expense (manager)
- `POST /api/expenses/<id>/reject` : reject expense + notes (manager)
- `GET /api/expenses/evidence/<path>` : ambil file evidence
- `GET /api/expenses/categories` : list kategori approved

#### `backend/routes/categories.py`
- `GET /api/categories` : list kategori (manager semua, staff hanya approved)
- `GET /api/categories/pending` : list pending (manager)
- `POST /api/categories` : buat kategori (staff->pending, manager->approved)
- `PUT /api/categories/<id>` : update kategori (manager)
- `DELETE /api/categories/<id>` : delete kategori (jika tidak dipakai)
- `POST /api/categories/<id>/approve` : approve/reject kategori pending

#### `backend/routes/revenues.py`
- CRUD revenue (`GET/POST/PUT/DELETE /api/revenues`)
- create/update/delete dibatasi manager
- filter tanggal invoice (`start_date/end_date`)

#### `backend/routes/taxes.py`
- CRUD tax (`GET/POST/PUT/DELETE /api/taxes`)
- create/update/delete dibatasi manager
- filter tanggal (`start_date/end_date`)

#### `backend/routes/settings.py`
- `GET/POST /api/settings/storage`
  - lihat folder storage aktif
  - pindah folder storage + copy file + update `.env`
- `GET/POST /api/settings/report-year`
  - baca/update default tahun laporan

#### `backend/routes/reports/` (package - sebelumnya file tunggal `reports.py`)
Endpoint utama:
- `GET /api/reports/summary` : summary report JSON
- `GET /api/reports/summary/pdf` : export summary PDF
- `GET /api/reports/excel` : export summary Excel (generated from scratch)
- `GET /api/reports/excel_advance` : export kasbon Excel (generated from scratch)
- `GET /api/reports/advance/<id>/pdf` : export 1 kasbon PDF
- `GET /api/reports/settlement/<id>/receipt` : export receipt settlement PDF
- `GET /api/reports/settlements/pdf` : export bulk settlements PDF
- `GET /api/reports/advances/pdf` : export bulk advances PDF
- `GET /api/reports/annual` : annual report JSON (dengan cache)
- `GET /api/reports/annual/pdf` : export annual PDF (dengan cache)
- `GET /api/reports/annual/excel` : export annual Excel (template-based)

Struktur package `reports/`:
- `__init__.py` : blueprint registration
- `helpers.py` : utility functions (format tanggal, mata uang, Excel helpers)
- `summary.py` : summary report endpoints
- `annual.py` : annual report endpoints dengan caching

Inti logika:
- Normalisasi formula excel dari referensi eksternal
- Isi template Excel pada range/baris tertentu
- Mapping kategori expense ke kolom template
- Kelola cache annual (`exports/annual_cache/*.json` + `*.pdf`)
- Kompilasi payload annual: revenue, tax, operation_cost
- Support tag data per tahun via tabel `report_entry_tags` (jika ada)

---

### 3.4 Script Utilitas Backend (bukan API runtime utama)

#### `backend/migrate.py`
CLI sederhana untuk `flask db init/migrate/upgrade`

#### `backend/migrate_evidence.py`
SQLite migration manual menambah kolom `evidence_path`/`evidence_filename` pada `advance_items`

#### `backend/scripts/excel_to_app_db.py`
Script besar untuk impor template Excel ke SQLite app-ready
- parse revenue/tax/operation cost
- normalisasi subkategori menggunakan mapping `FULL_MAPPING` ke 13 Standard Subcategories (Transportation, Accommodation, dsb).
- menentukan `settlement_type`:
  - **`single`**: Jika expense berada di baris mandiri (standalone rows) antara bagian Tax dan header `Expense#1` pertama. Tiap baris akan dibuatkan 1 tabel `settlements` bertipe `single`.
  - **`batch`**: Jika expense berada di dalam blok di bawah header `Expense#N`. Seluruh baris di dalam blok tersebut disatukan ke dalam 1 tabel `settlements` bertipe `batch`.
- generate user/kategori/data transaksi
- opsi simpan metadata Excel mentah

#### `backend/scripts/clean_subcategory.py`
Normalisasi label subkategori legacy di blok Expense# pada file Excel

#### `backend/scripts/verify_subcategories.py`
Audit daftar subkategori unik dari template Excel

#### File eksperimen / maintenance lain
- `read_excel.py`, `read_excel2.py`, `temp_inspect.py`, `temp_check.py`, `update_excel_db.py`, `update_categories.py`
- Ini lebih ke helper ad-hoc, bukan alur produksi utama

---

## 4. Frontend Detail (Flutter)

### 4.1 Entry Point dan Arsitektur State

#### `frontend/lib/main.dart`
- Bootstrapping app + `MultiProvider`
- Provider utama:
  - `AuthProvider`
  - `ThemeProvider`
  - `SettlementProvider` (proxy dari token Auth)
  - `AdvanceProvider` (proxy dari token Auth)
  - `RevenueProvider`
  - `TaxProvider`
  - `DividendProvider` (BARU)
  - `NotificationProvider` (BARU)
- Home screen: jika login -> `DashboardScreen`, jika belum -> `LoginScreen`

#### `frontend/lib/services/api_service.dart`
Ini "gerbang" semua API backend:
- Auth: login, me
- Dashboard summary
- Notifications
- Settlements + expenses + category management
- Advances + advance items
- Dividends + dividend settings
- Report export (summary/full/annual, pdf/excel)
- Revenues, Taxes
- Settings (storage, report year)

Catatan penting:
- `baseUrl` mendukung runtime config via `--dart-define=API_BASE_URL=...`
- Default: `http://localhost:5000/api` (web/desktop), `http://10.0.2.2:5000/api` (Android emulator)
- Semua request pakai bearer token jika `_token` terisi
- Support search parameter di settlements dan advances

---

### 4.2 Provider Layer

#### `frontend/lib/providers/auth_provider.dart`
- Simpan token/user ke SharedPreferences
- Handle login/logout dan reload user dari `/auth/me`
- Expose helper role: `isManager`, `isStaff`, `isMitraEks`

#### `frontend/lib/providers/settlement_provider.dart`
- State settlement, kategori, pending kategori
- CRUD settlement + expense
- Approve/reject expense/settlement
- Category management (create/update/delete/approve)
- Export report summary/full + receipt

Catatan:
- Di `flatCategories`, ada karakter branch tree yang terlihat mojibake (`â””`)

#### `frontend/lib/providers/advance_provider.dart`
- State list/detail advance
- CRUD advance + items
- Workflow submit/approve/reject
- Start revision kasbon
- Create settlement dari kasbon approved
- Export PDF/Excel kasbon

#### `frontend/lib/providers/revenue_provider.dart`
- Fetch/create/update/delete revenue

#### `frontend/lib/providers/tax_provider.dart`
- Fetch/create/update/delete tax

#### `frontend/lib/providers/dividend_provider.dart` (BARU)
- Fetch/create/update/delete dividend
- Fetch/update dividend settings

#### `frontend/lib/providers/theme_provider.dart`
- Simpan mode tema (`light/dark/system`) ke SharedPreferences

---

### 4.3 Screen Layer (UI)

#### `frontend/lib/screens/login_screen.dart`
- Form login + animasi
- Menampilkan credential default

#### `frontend/lib/screens/dashboard_screen.dart`
Halaman utama aplikasi:
- Sidebar + navigation dengan notification badges
- Dashboard summary cards (pending settlements, pending advances, total expenses bulan ini)
- Search bar untuk cari settlement
- Halaman internal:
  - Settlement list (dengan filter status, tahun, search)
  - My Advances (dengan filter status revisi)
  - Report (manager)
  - Category management (manager)
  - Settings (manager)
- Export settlement PDF/Excel, create/edit settlement

#### `frontend/lib/screens/settlement_detail_screen.dart`
Detail satu settlement:
- Tabel expenses dengan ringkasan dana kasbon vs realisasi
- Tambah/edit/hapus expense
- Upload evidence
- Submit settlement
- Manager approve/complete
- Cetak receipt PDF + export excel settlement
- Warning policy jika realisasi melebihi dana kasbon

#### `frontend/lib/screens/advance/my_advances_screen.dart`
List kasbon:
- Filter status + date range + status revisi
- Create advance
- Export kasbon (PDF/Excel) untuk status tertentu

#### `frontend/lib/screens/advance/advance_detail_screen.dart`
Detail kasbon:
- CRUD item kasbon + upload evidence (dikelompokkan per revisi)
- Submit/approve/reject kasbon
- Start revision kasbon (manager)
- Create settlement dari kasbon approved
- Export PDF/Excel kasbon
- Ringkasan dana: Pengajuan Awal, Revisi, Dana Tersedia, Realisasi, Selisih
- Warning policy jika realisasi melebihi dana approved

#### `frontend/lib/screens/report_screen.dart`
Summary report per kategori per bulan:
- Pilih tahun / date range
- Tabel summary + grand total
- Export Summary PDF
- Export full Excel
- Tombol ke laporan tahunan

#### `frontend/lib/screens/annual_report_screen.dart`
Laporan tahunan komprehensif:
- Fetch data annual dari backend
- Tabel revenue/tax/operation cost
- Hitung ringkasan di UI
- Export annual PDF + annual Excel
- Akses screen manajemen revenue/tax

#### `frontend/lib/screens/revenue_management_screen.dart`
- CRUD revenue dengan dialog form
- Filter otomatis per tahun yang dipilih

#### `frontend/lib/screens/tax_management_screen.dart`
- CRUD tax dengan dialog form
- Filter otomatis per tahun yang dipilih

#### `frontend/lib/screens/settings_screen.dart`
- Ubah tema
- Ubah folder storage evidence
- Ubah default report year

#### `frontend/lib/screens/dividend_management_screen.dart` (BARU)
- CRUD dividend dengan dialog form
- Filter otomatis per tahun yang dipilih
- Akses ke dividend settings

#### `frontend/lib/screens/balance_sheet_settings_screen.dart` (BARU)
- Setting balance sheet untuk dividend calculation
- Input opening cash balance, accounts receivable, prepaid expenses, dll

#### `frontend/lib/screens/manager/manager_dashboard_screen.dart`
- Dashboard manager versi tab (settlement approval + advance approval)
- Notification badges untuk pending items

Catatan penting:
- Logika status advance di screen ini tampak pakai `'pending'`, sementara backend pakai `'submitted'` untuk menunggu approval. Berpotensi mismatch.
- Field yang dipakai seperti `purpose`, `amount_requested` tidak sesuai model `Advance` saat ini (`title`, `total_amount`). Ini indikasi screen lama/legacy.

#### `frontend/lib/screens/manager/manager_settlement_detail_screen.dart`
- Approval detail per expense untuk manager
- Aksi approve/reject item + approve/reject all

---

### 4.4 Widget Layer (UI Components)

#### `frontend/lib/screens/widgets/sidebar.dart` (BARU)
- DashboardSidebar dengan notification badges
- SidebarNavItem dengan badge parameter

#### `frontend/lib/screens/widgets/page_selector.dart` (BARU)
- Dropdown navigasi untuk mobile

#### `frontend/lib/screens/widgets/settlement_widgets.dart` (BARU)
- SettlementCard, StatusFilterChip, StatusBadge
- Format number helper

#### `frontend/lib/screens/widgets/settlement_detail_widgets.dart` (BARU)
- SummaryCard untuk ringkasan expense
- SettlementActionButton untuk tombol aksi

---

### 4.5 Utility Frontend

#### `frontend/lib/theme/app_theme.dart`
- Definisi dark/light theme detail
- Color palette dan komponen UI style

#### `frontend/lib/utils/file_helper.dart`
- Simpan file export ke folder lokal
- Open file/folder hasil export
- Timestamp filename otomatis

#### `frontend/lib/utils/currency_formatter.dart`
- Formatter input angka mata uang (tanpa desimal)

#### `frontend/lib/utils/responsive_layout.dart`
- Breakpoint layout mobile/tablet/desktop

#### `frontend/pubspec.yaml`
Dependensi inti:
- `http`, `provider`, `shared_preferences`, `file_picker`, `path_provider`, `url_launcher`, `intl`, `google_fonts`

---

## 5. Alur Data End-to-End (wajib dipahami)

Contoh alur "tambah expense":
1. User buka `SettlementDetailScreen`
2. UI panggil `SettlementProvider.addExpense()`
3. Provider panggil `ApiService.createExpense()` (multipart)
4. Request masuk ke backend `POST /api/expenses`
5. Backend validasi ownership/status settlement
6. Simpan file evidence ke `UPLOAD_FOLDER/receipts/YYYY/MM/...`
7. Insert ke tabel `expenses`
8. Frontend reload detail settlement

Contoh alur "export annual excel":
1. UI `AnnualReportScreen` panggil `api.getAnnualReportExcel()`
2. Backend `GET /api/reports/annual/excel`
3. Backend build payload dari DB + template Excel
4. Backend tulis section Revenue/Tax/Operation cost ke workbook
5. Backend kirim bytes file `.xlsx`
6. Frontend simpan via `FileHelper`

---

## 6. Daftar Hal yang Paling Harus Kamu Kuasai Dulu

Prioritas belajar takeover:
1. `backend/models.py` (struktur data termasuk revisi dan link advance-settlement)
2. `backend/routes/settlements.py`, `expenses.py`, `advances.py` (workflow inti)
3. `backend/routes/dashboard.py` (summary counts untuk dashboard)
4. `frontend/lib/services/api_service.dart` (kontrak API frontend-backend)
5. `frontend/lib/providers/settlement_provider.dart` + `advance_provider.dart` (termasuk revision flow)
6. `frontend/lib/screens/dashboard_screen.dart`, `settlement_detail_screen.dart`, `advance_detail_screen.dart`
7. `backend/routes/reports/` (package - kompleks, dikerjakan setelah paham flow dasar)

---

## 7. Risiko Teknis yang Perlu Dicatat

1. `manager_dashboard_screen.dart` terlihat tidak sinkron dengan model/flow terbaru (status/field advance lama) - perlu direview.
2. File `advance_request_screen.dart` sudah dihapus (tidak dipakai).
3. Beberapa file utilitas backend adalah script ad-hoc dan tidak dipakai runtime; jangan diasumsikan bagian alur produksi.
4. `reports/` package sangat sensitif terhadap struktur template Excel (row/col hardcoded).
5. Cache annual report di `exports/annual_cache/` bisa stale - perlu refresh manual jika data berubah.
6. Template Excel annual punya batas kapasitas hardcoded (14 revenue, 10 tax, ~56 expense rows).
7. Mapping kategori expense ke kolom template Excel pakai keyword matching - risiko salah mapping jika nama kategori tidak sesuai keyword.
8. Tabel `report_entry_tags` tidak ada di `models.py` tapi dipakai untuk tracking tahun laporan - bisa membingungkan.
9. Status workflow advance sekarang lebih kompleks (ada revision states) - pastikan UI konsisten.

---

## 8. Cara Menjalankan (ringkas)

### Backend (Flask):
1. `cd backend`
2. Aktifkan virtual env: `venv\Scripts\activate` (Windows) atau `source venv/bin/activate` (Linux/Mac)
3. `pip install -r requirements.txt`
4. `python app.py`
5. Server akan berjalan di `http://localhost:5000`

### Frontend (Flutter):

**Desktop (Windows/Mac/Linux):**
1. `cd frontend`
2. `flutter pub get`
3. `flutter run -d windows` (atau `macos`/`linux`)

**Mobile (Android/iOS) - Akses dari HP:**
1. Jalankan Cloudflare Tunnel di laptop:
   ```
   cloudflared tunnel --url http://localhost:5000
   ```
2. Copy URL yang diberikan (misal: `https://abc-def-ghi.trycloudflare.com`)
3. Jalankan Flutter dengan URL Cloudflare:
   ```
   flutter run -d android --dart-define=API_BASE_URL=https://abc-def-ghi.trycloudflare.com/api
   ```

**Catatan penting:**
- Kalau URL Cloudflare berubah, app harus dijalankan ulang dengan URL baru
- Backend tetap harus hidup di laptop
- Cloudflare Tunnel tidak menggantikan backend, cuma membuka akses dari HP ke backend

### Database Migration (jika ada perubahan model):
1. `cd backend`
2. `flask db migrate -m "pesan migrasi"`
3. `flask db upgrade`

### Import Data dari Excel:
1. Siapkan file Excel template di folder `excel/`
2. Jalankan script import:
   ```
   cd backend/scripts
   python excel_to_app_db.py --excel path/to/file.xlsx
   ```

---

## 9. Ringkas Cepat

- Proyek ini sudah cukup lengkap untuk operasi dasar keuangan operasional.
- Domain utama: **Advance (Kasbon) → Settlement (Realisasi) → Expense (Nota) → Report**.
- **Fitur baru**: Revisi kasbon (Revisi 1, Revisi 2), Dashboard summary, Notification badges, Search bar, Dividend management.
- Titik paling kritikal maintenance: `reports/` package + konsistensi status workflow antar screen.
- Untuk takeover aman, pahami kontrak API di `api_service.dart` sebelum ubah UI.
- Dokumentasi lengkap ada di `panduan/` folder (Backend, Frontend, Excel Export).

---

## 10. Fitur yang Belum Ada (Untuk Referensi)

Jika ada request fitur baru, cek dulu apakah sudah ada. Berikut fitur yang **belum** diimplementasi:

- ❌ Multi-level approval (saat ini hanya 1 level: Manager)
- ❌ Policy limitation (batas claim per karyawan per bulan)
- ❌ Notifikasi email (saat ini hanya notifikasi in-app)
- ❌ Backup approver
- ❌ Pembatasan akses per divisi
- ❌ Custom field / additional details di settlement
- ❌ Business trip / itinerary management (disengaja tidak dibuat sesuai kebutuhan Pak Nevi)
- ❌ Auto-disbursement (tidak relevan untuk skala perusahaan ini)
