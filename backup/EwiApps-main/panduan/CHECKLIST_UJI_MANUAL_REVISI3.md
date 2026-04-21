# CHECKLIST UJI MANUAL - REVISI 3 (TERLENGKAP)

> **Tanggal:** 12 April 2026  
> **Update:** Semua perubahan + bug fix dari hasil analisis kode  
> **Tujuan:** Daftar test yang HARUS dicek MANUAL oleh developer  
> **Cara Pakai:** Centang `[x]` kalau sudah test dan hasilnya ✅ OK

---

## 📋 Panduan

| Symbol | Arti |
|--------|------|
| `[ ]` | Belum ditest |
| `[x]` | Sudah ditest & OK |
| `[!]` | Sudah ditest & BUG (catat di bawah) |
| `[?]` | Sudah ditest & PERLU IMPROVE |

| Prioritas | Arti |
|-----------|------|
| 🔴 TINGGI | Harus fix sebelum release (data/alur utama rusak) |
| 🟡 SEDANG | Alur jalan tapi membingungkan/berisiko |
| 🟢 RENDAH | Kosmetik/non-blocking |

---

# BAGIAN 1: PERUBAHAN BARU (HARI INI)

## 🔥 1. Hapus File Sampah

### Frontend
- [ ] Buka folder `frontend/` → **TIDAK ada** `change_icon.bat`
- [ ] Buka folder `frontend/` → **TIDAK ada** `repair.py`
- [ ] Buka folder `frontend/` → **TIDAK ada** `analyze_output.txt`
- [ ] Buka folder `frontend/lib/screens/` → **TIDAK ada** `settings_screen_backup.dart`

### Backend
- [ ] Buka folder `backend/` → **TIDAK ada** `debug_titles.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `fix_existing_titles.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `fix_remark.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `fix_remark_database.sql`
- [ ] Buka folder `backend/` → **TIDAK ada** `test_api_revenue_type.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `test_revenue_type.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_add_last_login.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_add_revenue_type.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_add_revenue_type_simple.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_evidence.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_sort_order.py`
- [ ] Buka folder `backend/` → **TIDAK ada** `migrate_sort_order_simple.py`
- [ ] Buka folder `backend/` → **TIDAK ada** folder `scripts/`
- [ ] Buka folder `backend/` → **TIDAK ada** folder `_archive/`
- [ ] Buka folder `backend/` → **TIDAK ada** `app.db`
- [ ] Buka folder `backend/` → **TIDAK ada** `database_import_dividen.db`
- [ ] Buka folder `backend/` → **TIDAK ada** `ewi.db`
- [ ] Buka folder `backend/routes/reports/` → **TIDAK ada** folder `backup/`
- [ ] Buka folder `backend/routes/reports/` → **TIDAK ada** `CODE_ANALYSIS_REPORT.md`
- [ ] Jalankan `python app.py` → Backend jalan normal, tidak error

**Prioritas:** 🟢 RENDAH

---

## 📁 2. Struktur Folder Frontend Baru

### Folder Baru Ada
- [ ] `frontend/lib/screens/auth/` ada → isi: `login_screen.dart`, `register_screen.dart`
- [ ] `frontend/lib/screens/management/` ada → isi: 5 files (category, revenue, tax, dividend, category_tabular)
- [ ] `frontend/lib/screens/reports/` ada → isi: `report_screen.dart`, `annual_report_screen.dart`
- [ ] `frontend/lib/screens/settings/` ada → isi: `settings_screen.dart`, `balance_sheet_settings_screen.dart`
- [ ] `frontend/lib/screens/settlement/` ada → isi: `settlement_detail_screen.dart`
- [ ] `frontend/lib/screens/advance/` ada → isi: `advances_screen.dart`, `advance_detail_screen.dart`
- [ ] `frontend/lib/screens/manager/` ada → isi: `manager_dashboard_screen.dart`, `manager_settlement_detail_screen.dart`
- [ ] `frontend/lib/screens/widgets/` ada → isi: `common_widgets.dart`, `settlement_detail_widgets.dart`, `page_selector.dart`, `sidebar.dart`
- [ ] Di `screens/` root **CUMA ADA** `dashboard_screen.dart` (tidak ada file lain)

### Navigasi Masih Jalan
- [v] Buka app → login screen muncul normal
- [v] Login → dashboard muncul normal
- [v] Klik tab "Settlement" → list settlement muncul
- [v] Klik 1 settlement → detail settlement muncul
- [v] Klik tab "Kasbon" → list kasbon muncul
- [v] Klik 1 kasbon → detail kasbon muncul
- [v] Klik tab "Laporan" → report screen muncul
- [v] Klik "Laporan Tahunan" → annual report muncul
- [v] Klik "Kategori" → category management muncul
- [v] Klik "Pengaturan" → settings screen muncul
- [v] Klik "Input Revenue" (dari annual) → revenue management muncul
- [v] Klik "Input Pajak" (dari annual) → tax management muncul
- [v] Klik "Input Dividen" (dari annual) → dividend management muncul
- [v] Klik "Input Neraca" (dari annual) → balance sheet settings muncul

### Import Paths
- [v] Buka VS Code → **TIDAK ADA** garis merah di file manapun
- [v] Terminal: `flutter analyze` → "No issues found!"
- [v] `flutter run` → app jalan tanpa error
- [v] Hot reload di screen manapun → tidak error

**Prioritas:** 🔴 TINGGI

---

## 🐛 3. Bug Fix: Revenue Combine Logic

### Combine Berhasil (Kasus Benar)
- [ ] Login sebagai manager
- [ ] Buka Revenue Management
- [ ] Buat minimal 3 revenue dengan **Receive Date SAMA PERSIS** (misal: 01-Feb-24)
- [ ] Di annual report, pilih baris 1 dan 2 (berurutan)
- [ ] Klik "Combine Manual (2)" → **BERHASIL**, muncul group "C1"

### Combine Gagal (Kasus Salah)
- [ ] Pilih baris dengan **Receive Date BERBEDA** → muncul error: "Receive Date harus sama persis"
- [ ] Pilih baris **TIDAK BERURUTAN** (skip 1 baris di tengah) → muncul error: "Baris harus berurutan"
- [ ] Pilih baris yang **SUDAH ADA DI GROUP** lain → muncul error: "Lepas combine lama dulu"
- [ ] Pilih **HANYA 1 BARIS** → tombol combine tidak muncul/error

### Consistency UI vs Backend
- [ ] Urutan revenue di UI (Receive Date) **SAMA** dengan urutan di Excel setelah export
- [ ] Group C1 di Excel → cell K dan L ter-merge dengan benar (tidak berantakan)
- [ ] Nilai di kolom L (Amount Received) = total dari row-row yang di-merge

**Prioritas:** 🔴 TINGGI

---

## 🐛 4. Bug Fix: Tax Input Angka Format Indonesia

### Parsing Input
- [ ] Buka Tax Management
- [ ] Klik "Tambah"
- [ ] Di field "Transaction Value" ketik: `1.500.000,50` → simpan → di list tampil `1.500.000,50`
- [ ] Edit tax → field terisi `1.500.000,50` (bukan `1500000.50`)
- [ ] Ketik `1500000` → simpan → di list tampil `1.500.000,00`
- [ ] Ketik `1,50` → simpan → di list tampil `1,50`
- [ ] Ketik `abc` → muncul error: "Angka tidak valid"
- [ ] Field kosong → simpan → jadi `null` atau `0`

### Format di Dialog Edit
- [ ] Edit tax yang sudah ada → Transaction Value tampil `1.500.000,00` (bukan `1500000.0`)
- [ ] Edit tax → PPN tampil `165.000.000,00` (bukan `165000000.0`)
- [ ] Edit tax → PPh21 tampil `3.000.000,00` (bukan `3000000.0`)
- [ ] Edit tax → Currency Exchange tampil `1,00` (bukan `1.0`)

### Simpan & Tampil
- [ ] Simpan tax dengan format Indonesia → data tersimpan benar
- [ ] Cek di database (atau list) → angka benar, tidak corrupt
- [ ] Export Excel annual → kolom nilai tax tampil benar

**Prioritas:** 🔴 TINGGI

---

## 🐛 5. Bug Fix: Cascade Delete Combine Group

### Delete Row dari Group (2 rows)
- [ ] Combine 2 revenue → jadi group C1
- [ ] Hapus 1 row dari group
- [ ] Group C1 **OTOMATIS HILANG** (tidak ada dangling group)
- [ ] Row yang lain **TETAP ADA**

### Delete Row dari Group (3+ rows)
- [ ] Combine 3 revenue → jadi group C1
- [ ] Hapus 1 row dari group
- [ ] Group C1 **MASIH ADA** (dengan 2 rows tersisa)
- [ ] 2 rows lain masih bisa di-combine/di-edit

### Delete Row Bukan dari Group
- [ ] Delete revenue yang **TIDAK** di-combine → berhasil normal
- [ ] Group lain tidak terpengaruh
- [ ] Data lain tetap utuh

**Prioritas:** 🟡 SEDANG

---

## 🐛 6. Bug Fix: Tax Dialog Numeric Formatting

### Tampilan Dialog
- [ ] Buka dialog "Tambah Pajak" → semua field kosong
- [ ] Edit pajak existing → Transaction Value tampil `1.500.000,00`
- [ ] Edit pajak existing → PPN tampil `165.000,00`
- [ ] Edit pajak existing → PPh21 tampil `33.000.000,00`
- [ ] Edit pajak existing → PPh23 tampil `2.000.000,00`
- [ ] Edit pajak existing → PPh26 tampil `0` (jika kosong)

**Prioritas:** 🟢 RENDAH

---

## 📂 7. Rename File

### `my_advances_screen.dart` → `advances_screen.dart`
- [ ] File `my_advances_screen.dart` **TIDAK ADA** lagi
- [ ] File `advances_screen.dart` **ADA** di `screens/advance/`
- [ ] Class di dalam file bernama `AdvancesScreen` (bukan `MyAdvancesScreen`)
- [ ] Buka tab Kasbon → halaman muncul normal, tidak error

### `settlement_widgets.dart` → `common_widgets.dart`
- [ ] File `settlement_widgets.dart` **TIDAK ADA** lagi
- [ ] File `common_widgets.dart` **ADA** di `screens/widgets/`
- [ ] Dashboard masih menampilkan card/badge/widget dengan normal

**Prioritas:** 🟡 SEDANG

---

## 📊 8. Excel Report - Consistency Check

### Revenue Ordering
- [ ] Buka Annual Report
- [ ] Klik "Export Excel"
- [ ] Buka file Excel → sheet "Revenue-Cost_YYYY"
- [ ] Kolom Receive Date (K) → **URUT** dari yang paling lama ke baru
- [ ] Urutan di Excel **SAMA** dengan urutan di UI Revenue Management

### Merge Cells
- [ ] Di Excel → ada revenue yang di-combine (group C1)
- [ ] Kolom K (Receive Date) → **MERGE** cell-nya benar
- [ ] Kolom L (Amount Received) → **MERGE** cell-nya benar
- [ ] Nilai di merged cell = **TOTAL** dari row-row yang di-merge

### Tax Merge
- [ ] Di Excel → ada tax yang di-combine
- [ ] Kolom B (Date) → **MERGE** cell-nya benar
- [ ] Kolom F-Q (nilai pajak) → **MERGE** cell-nya benar

### Summary
- [ ] Di sheet "Summary" → total revenue benar
- [ ] Di sheet "Summary" → total tax benar
- [ ] Di sheet "Summary" → total expense benar
- [ ] Di sheet "Summary" → profit after tax benar

**Prioritas:** 🔴 TINGGI

---

# BAGIAN 2: REGRESSION TEST (FITUR LAMA)

## 🔐 9. Login & Autentikasi

### Login
- [ ] Login manager: username `manager1`, password `manager12345` → berhasil
- [ ] Login staff: username `staff1`, password `staff12345` → berhasil
- [ ] Login password salah → muncul error: "Username atau password salah"
- [ ] Logout → kembali ke login screen
- [ ] Tutup app → buka lagi → masih login (sesi tersimpan)
- [ ] Logout → buka lagi → harus login ulang

### Otorisasi Role
- [ ] Manager → melihat menu: Laporan, Kategori, Pengaturan, Semua Users
- [ ] Staff → **TIDAK** melihat menu: Kategori, Pengaturan
- [ ] Staff → hanya melihat settlement/kasbon miliknya sendiri
- [ ] Staff coba akses detail settlement staff lain → ditolak

### Sidebar & Identitas
- [ ] Nama di sidebar = nama user yang login
- [ ] Role di sidebar benar (Manager/Staff)
- [ ] Badge notifikasi muncul kalau ada notifikasi baru

**Prioritas:** 🔴 TINGGI

---

## 🔔 10. Notifikasi

### Distribusi
- [ ] Staff submit settlement → manager dapat notifikasi
- [ ] Staff submit kasbon → manager dapat notifikasi
- [ ] Manager approve settlement → staff dapat notifikasi
- [ ] Staff A submit settlement → Staff B **TIDAK** dapat notifikasi

### Panel Notifikasi
- [ ] Klik icon bell → panel notifikasi muncul
- [ ] Ada tombol "Tandai Semua Dibaca" (centang)
- [ ] Ada tombol "X" untuk tutup panel
- [ ] Teks notifikasi terbaca jelas di dark theme
- [ ] Teks notifikasi terbaca jelas di light theme
- [ ] Badge unread count turun setelah mark all read

### Deep Link
- [ ] Klik notifikasi settlement → langsung ke detail settlement yang benar
- [ ] Klik notifikasi kasbon → langsung ke detail kasbon yang benar
- [ ] Klik item notifikasi → panel tertutup, navigasi berjalan

### Hapus Notifikasi
- [ ] Swipe/hapus notifikasi → item hilang dari list
- [ ] Badge count update setelah hapus

**Prioritas:** 🟡 SEDANG

---

## 💰 11. Kasbon (Advance)

### Draft
- [ ] Buat kasbon draft → form valid, tersimpan
- [ ] Di draft → bisa edit header (tanggal, judul, dll)
- [ ] Di draft → bisa tambah item kasbon
- [ ] Di draft → bisa edit item kasbon
- [ ] Di draft → bisa hapus item kasbon
- [ ] Validasi form: nominal wajib diisi, kategori wajib dipilih

### Submit/Approve/Reject
- [ ] Submit draft → status berubah ke `submitted`
- [ ] Setelah submit → staff **TIDAK** bisa edit lagi
- [ ] Manager → bisa approve kasbon
- [ ] Manager → bisa reject kasbon dengan catatan
- [ ] Staff dapat notifikasi setelah approve/reject

### Revisi
- [ ] Start revisi → status jadi `revision_draft`
- [ ] Item revisi bisa ditambah/edit/hapus
- [ ] Submit revisi → manager approve/reject
- [ ] Total approved/base/revision konsisten

### Filter & List
- [ ] Filter by status → data muncul benar
- [ ] Filter by tahun → data muncul benar
- [ ] Filter by date range → data muncul benar
- [ ] Pindah menu lalu balik → data list tetap sinkron

**Prioritas:** 🔴 TINGGI

---

## 🧾 12. Settlement

### Draft
- [ ] Buat settlement draft → form valid, tersimpan
- [ ] Di draft → bisa edit header
- [ ] Di draft → bisa tambah expense
- [ ] Di draft → bisa edit expense
- [ ] Di draft → bisa hapus expense
- [ ] Upload bukti expense → berhasil, preview muncul

### Submit/Approve/Reject/Complete
- [ ] Submit settlement → status → `submitted`
- [ ] Manager approve → status → `approved`
- [ ] Manager reject all → status → `rejected`, catatan tersimpan
- [ ] Complete settlement → hanya aktif kalau syarat terpenuhi
- [ ] Setelah complete → data tidak bisa diubah

### Rule Visibility
- [ ] Status `submitted` → staff hanya bisa lihat detail (tidak ada tombol edit)
- [ ] Status `approved` → staff hanya bisa lihat detail
- [ ] Status `completed` → staff hanya bisa lihat detail

**Prioritas:** 🔴 TINGGI

---

## 📂 13. Kategori

### CRUD
- [ ] Manager tambah kategori utama → berhasil
- [ ] Manager tambah subkategori → berhasil
- [ ] Manager edit kategori → berhasil
- [ ] Manager hapus kategori (tidak punya expense) → berhasil
- [ ] Manager hapus kategori (punya expense) → error: "Tidak bisa hapus"

### Approval
- [ ] Staff tambah kategori → status `pending`
- [ ] Manager lihat pending categories → ada di antrian
- [ ] Manager approve → status `approved`, kategori bisa dipakai
- [ ] Manager reject → kategori tidak bisa dipakai

**Prioritas:** 🟡 SEDANG

---

## 📈 14. Laporan Summary

### Data & Filter
- [ ] Ganti tahun laporan → data update
- [ ] Filter date range → data ter-filter benar
- [ ] Tabel summary menampilkan angka sesuai data approved

### Export
- [ ] Export PDF summary → file terdownload
- [ ] Buka PDF → isi konsisten dengan data
- [ ] Export Excel summary → file terdownload
- [ ] Buka Excel → isi konsisten dengan data

**Prioritas:** 🟡 SEDANG

---

## 📅 15. Laporan Tahunan, Dividen, Neraca

### Annual Report
- [ ] Halaman memuat data tahunan terbaru saat dibuka
- [ ] Tabel Revenue tampil tanpa crash
- [ ] Tabel Tax tampil tanpa crash
- [ ] Tabel Operation Cost tampil tanpa crash
- [ ] Grouping single/batch expense masuk section benar

### Export Annual
- [ ] Export PDF → file terdownload
- [ ] Buka PDF → layout benar, tidak berantakan
- [ ] Export Excel → file terdownload
- [ ] Buka Excel → sheet terisi benar
- [ ] Sheet "Summary" ada dan terisi

### Tombol Navigasi
- [ ] Klik "Input Revenue" → buka revenue management
- [ ] Klik "Input Pajak" → buka tax management
- [ ] Klik "Input Dividen" → buka dividend management
- [ ] Klik "Input Neraca" → buka balance sheet settings
- [ ] Kembali dari input screen → annual report refresh data

**Prioritas:** 🔴 TINGGI

---

## 🎨 16. Tema & UI

### Light Theme
- [ ] Sidebar background terang, font gelap (terbaca)
- [ ] Card background terang, border terlihat
- [ ] Tabel font gelap di background terang
- [ ] Dialog/form font gelap di background terang
- [ ] Tombol primary terlihat jelas
- [ ] Status badge (success/warning/error) terbaca

### Dark Theme
- [ ] Sidebar background gelap, font terang
- [ ] Card background gelap, border terlihat
- [ ] Tabel font terang di background gelap
- [ ] Status badge (success/warning/error) terbaca

### Toggle
- [ ] Toggle Light → Dark → update instant
- [ ] Toggle Dark → Light → update instant
- [ ] Restart app → tema tersimpan
- [ ] Pilihan "System" mengikuti OS

**Prioritas:** 🟡 SEDANG

---

## ⚙️ 17. Pengaturan Sistem

### Tema
- [ ] Pilih Light → tersimpan setelah restart
- [ ] Pilih Dark → tersimpan setelah restart
- [ ] Pilih System → mengikuti OS

### Tahun Laporan
- [ ] Ubah default tahun → tersimpan
- [ ] Report/Annual membaca default tahun dengan benar

### Folder Lampiran
- [ ] Ubah direktori upload → berhasil
- [ ] Upload bukti → masuk ke folder baru

**Prioritas:** 🟢 RENDAH

---

## ⚡ 18. Error Handling

### Network Error
- [ ] Matikan backend → UI muncul pesan: "Tidak bisa terhubung ke server"
- [ ] Nyalakan backend lagi → app otomatis connect ulang
- [ ] Request timeout → tidak freeze, muncul pesan error

### Error Input
- [ ] Form kosong wajib → muncul pesan "Wajib diisi"
- [ ] Format tanggal salah → muncul pesan "Tanggal tidak valid"
- [ ] Format angka salah → muncul pesan "Angka tidak valid"

### Polling Notifikasi
- [ ] Logout → polling berhenti (tidak ada request berulang)
- [ ] Dispose screen → tidak ada rebuild setelah dispose

**Prioritas:** 🟡 SEDANG

---

## 🚀 19. SMOKE TEST CEPAT (10 MENIT)

Jalankan ini **TERAKHIR** untuk pastikan semua jalan:

- [ ] 1. Login manager → berhasil
- [ ] 2. Buat kasbon draft → submit → approve → berhasil
- [ ] 3. Buat settlement dari kasbon → submit → approve → berhasil
- [ ] 4. Cek notifikasi → deep link tombol bekerja
- [ ] 5. Combine 2 revenue (Receive Date sama, berurutan) → berhasil
- [ ] 6. Combine revenue (Receive Date beda) → ERROR (benar!)
- [ ] 7. Input tax `1.500.000,50` → tampil `1.500.000,50` (bukan `150000050`)
- [ ] 8. Edit tax → angka terformat `1.500.000,00` (bukan `1500000.0`)
- [ ] 9. Delete row dalam combine group (2 rows) → group terhapus
- [ ] 10. Delete row dalam combine group (3 rows) → group update (jadi 2 rows)
- [ ] 11. Export Excel annual → urutan revenue benar (Receive Date)
- [ ] 12. Toggle dark/light → update instant
- [ ] 13. `flutter analyze` → "No issues found!"

**SEMUA HARUS ✅ OK SEBELUM RELEASE!**

---

# BAGIAN 3: BUG LOG

Kalau ada test yang gagal, catat di sini:

| No | Test | Bug Ditemukan | Status | Fix? |
|----|------|--------------|--------|------|
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |

---

# BAGIAN 4: HASIL AKHIR

| Item | Status |
|------|--------|
| **Total Test** | ~120 |
| **Pass** | |
| **Fail** | |
| **Skip** | |
| **Tanggal Test** | |
| **Tester** | |
| **Status Akhir** | ☐ PASS / ☐ FAIL / ☐ NEED REVIEW |
| **Catatan** | |

---

**TANDA TANGAN:**

Tester: ___________________  
Reviewer: ___________________  
Tanggal: ___________________
