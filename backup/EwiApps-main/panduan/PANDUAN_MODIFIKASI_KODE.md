# PANDUAN MODIFIKASI KODE - MiniProjectKPI_EWI

**Dibuat:** 22 Maret 2026  
**Update Terakhir:** 22 Maret 2026

Dokumen ini menjelaskan **file-file mana yang harus diubah** untuk setiap jenis perubahan fitur. Simpan dokumen ini sebagai referensi cepat saat mau ubah kode.

---

## 📋 DAFTAR CEPAT

| Fitur yang Mau Diubah | Backend (Python) | Frontend (Dart) |
|-----------------------|------------------|-----------------|
| [Settlement](#1-settlement) | 3 file | 4 file |
| [Kasbon/Advance](#2-kasbonadvance) | 3 file | 3 file |
| [Expense](#3-expense) | 2 file | 2 file |
| [Kategori](#4-kategori) | 2 file | 2 file |
| [Revenue](#5-revenue) | 2 file | 2 file |
| [Tax](#6-tax) | 2 file | 2 file |
| [Dividen](#7-dividen) | 2 file | 2 file |
| [Laporan/Report](#8-laporanreport) | 4 file | 3 file |
| [Dashboard](#9-dashboard) | 2 file | 2 file |
| [Notifikasi](#10-notifikasi) | 2 file | 2 file |
| [User/Auth](#11-userauth) | 2 file | 2 file |
| [Settings](#12-settings) | 2 file | 2 file |

---

## 1. SETTLEMENT

### 1.1 Ubah Struktur Data Settlement (Tambah Kolom)

**Backend:**
```
backend/models.py              → Tambah kolom di class Settlement
backend/routes/settlements.py  → Update create/update logic jika perlu
backend/migrations/            → Buat migration file untuk DB
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update response model
frontend/lib/providers/settlement_provider.dart → Update state model
frontend/lib/screens/settlement_detail_screen.dart → Update UI jika tampil kolom baru
frontend/lib/screens/dashboard_screen.dart → Update jika ada display data settlement
```

### 1.2 Ubah Workflow Settlement (Approve/Submit/Complete)

**Backend:**
```
backend/routes/settlements.py  → Ubah fungsi:
  - submit_settlement()
  - approve_settlement()
  - complete_settlement()
  - reject_all_expenses()
backend/models.py              → Ubah status options jika perlu
backend/routes/notifications.py → Update notifikasi yang dikirim
```

**Frontend:**
```
frontend/lib/providers/settlement_provider.dart → Ubah method:
  - submitSettlement()
  - approveSettlement()
  - completeSettlement()
frontend/lib/screens/settlement_detail_screen.dart → Update tombol/action UI
frontend/lib/screens/manager/manager_settlement_detail_screen.dart → Update approval UI
```

### 1.3 Ubah Tampilan Detail Settlement

**Frontend:**
```
frontend/lib/screens/settlement_detail_screen.dart → Main UI
frontend/lib/screens/widgets/settlement_detail_widgets.dart → Widget summary card
frontend/lib/providers/settlement_provider.dart → Data fetching
```

### 1.4 Tambah Validasi Settlement

**Backend:**
```
backend/routes/settlements.py  → Tambah validasi di:
  - create_settlement()
  - update_settlement()
  - submit_settlement()
  - approve_settlement()
```

---

## 2. KASBON/ADVANCE

### 2.1 Ubah Struktur Data Kasbon (Tambah Kolom)

**Backend:**
```
backend/models.py              → Tambah kolom di class Advance & AdvanceItem
backend/routes/advances.py     → Update create/update logic jika perlu
backend/migrations/            → Buat migration file untuk DB
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update request/response model
frontend/lib/providers/advance_provider.dart → Update state model
frontend/lib/screens/advance/advance_detail_screen.dart → Update UI jika tampil kolom baru
```

### 2.2 Ubah Workflow Kasbon (Submit/Approve/Revisi)

**Backend:**
```
backend/routes/advances.py     → Ubah fungsi:
  - submit_advance()
  - approve_advance()
  - reject_advance()
  - start_revision()
backend/models.py              → Ubah status options jika perlu
backend/routes/notifications.py → Update notifikasi yang dikirim
```

**Frontend:**
```
frontend/lib/providers/advance_provider.dart → Ubah method:
  - submitAdvance()
  - approveAdvance()
  - rejectAdvance()
  - startRevision()
frontend/lib/screens/advance/advance_detail_screen.dart → Update tombol/action UI
frontend/lib/screens/manager/manager_dashboard_screen.dart → Update approval UI
```

### 2.3 Ubah Tampilan Detail Kasbon

**Frontend:**
```
frontend/lib/screens/advance/advance_detail_screen.dart → Main UI
frontend/lib/screens/advance/my_advances_screen.dart → List view
frontend/lib/providers/advance_provider.dart → Data fetching
```

### 2.4 Ubah Link Kasbon → Settlement

**Backend:**
```
backend/routes/advances.py     → Ubah create_settlement_from_advance()
backend/routes/settlements.py  → Ubah sync logic di _sync_advance_after_settlement()
backend/models.py              → Ubah relasi Advance ↔ Settlement
```

**Frontend:**
```
frontend/lib/providers/advance_provider.dart → Ubah createSettlementFromAdvance()
frontend/lib/screens/advance/advance_detail_screen.dart → Update tombol "Buat Settlement"
```

---

## 3. EXPENSE

### 3.1 Ubah Struktur Data Expense (Tambah Kolom)

**Backend:**
```
backend/models.py              → Tambah kolom di class Expense
backend/routes/expenses.py     → Update create/update logic jika perlu
backend/migrations/            → Buat migration file untuk DB
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update request/response model
frontend/lib/providers/settlement_provider.dart → Update state model
frontend/lib/screens/settlement_detail_screen.dart → Update form/input UI
```

### 3.2 Ubah Workflow Approval Expense

**Backend:**
```
backend/routes/expenses.py     → Ubah fungsi:
  - approve_expense()
  - reject_expense()
backend/routes/notifications.py → Update notifikasi
```

**Frontend:**
```
frontend/lib/providers/settlement_provider.dart → Ubah method:
  - approveExpense()
  - rejectExpense()
frontend/lib/screens/settlement_detail_screen.dart → Update approval UI
```

### 3.3 Ubah Upload Evidence

**Backend:**
```
backend/routes/expenses.py     → Ubah create_expense() di bagian file handling
backend/config.py              → Ubah ALLOWED_EXTENSIONS atau MAX_CONTENT_LENGTH jika perlu
```

**Frontend:**
```
frontend/lib/providers/settlement_provider.dart → Ubah addExpense() di bagian multipart
frontend/lib/screens/settlement_detail_screen.dart → Update file picker UI
```

---

## 4. KATEGORI

### 4.1 Ubah Struktur Kategori

**Backend:**
```
backend/models.py              → Tambah kolom di class Category
backend/routes/categories.py   → Update create/update logic
backend/migrations/            → Buat migration file
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update response model
frontend/lib/providers/settlement_provider.dart → Update category state
frontend/lib/screens/category_management_screen.dart → Update UI form
```

### 4.2 Ubah Workflow Approval Kategori

**Backend:**
```
backend/routes/categories.py   → Ubah approve_category()
backend/routes/notifications.py → Update notifikasi
```

**Frontend:**
```
frontend/lib/providers/settlement_provider.dart → Ubah approveCategory()
frontend/lib/screens/category_management_screen.dart → Update approval UI
```

---

## 5. REVENUE

### 5.1 Ubah Struktur Revenue

**Backend:**
```
backend/models.py              → Tambah kolom di class Revenue
backend/routes/revenues.py     → Update create/update logic
backend/migrations/            → Buat migration file
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update request/response model
frontend/lib/providers/revenue_provider.dart → Update state model
frontend/lib/screens/revenue_management_screen.dart → Update form UI
```

### 5.2 Ubah Perhitungan Revenue

**Backend:**
```
backend/models.py              → Ubah property idr_invoice_value, idr_amount_received
backend/routes/reports/annual.py → Ubah logic perhitungan di _build_annual_payload_from_db()
```

---

## 6. TAX

### 6.1 Ubah Struktur Tax

**Backend:**
```
backend/models.py              → Tambah kolom di class Tax
backend/routes/taxes.py        → Update create/update logic
backend/migrations/            → Buat migration file
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update request/response model
frontend/lib/providers/tax_provider.dart → Update state model
frontend/lib/screens/tax_management_screen.dart → Update form UI
```

### 6.2 Ubah Perhitungan Tax

**Backend:**
```
backend/models.py              → Ubah property idr_transaction_value
backend/routes/reports/annual.py → Ubah logic perhitungan tax
```

---

## 7. DIVIDEN

### 7.1 Ubah Struktur Dividen

**Backend:**
```
backend/models.py              → Tambah kolom di class Dividend atau DividendSetting
backend/routes/dividends.py    → Update create/update logic
backend/migrations/            → Buat migration file
```

**Frontend:**
```
frontend/lib/services/api_service.dart    → Update request/response model
frontend/lib/providers/dividend_provider.dart → Update state model
frontend/lib/screens/dividend_management_screen.dart → Update form UI
```

### 7.2 Ubah Perhitungan Dividen

**Backend:**
```
backend/routes/dividends.py    → Ubah _compute_dividend_distribution()
backend/routes/reports/annual.py → Ubah logic di _build_annual_payload_from_db()
```

**Frontend:**
```
frontend/lib/providers/dividend_provider.dart → Ubah perhitungan di provider
frontend/lib/screens/dividend_management_screen.dart → Update display perhitungan
```

---

## 8. LAPORAN/REPORT

### 8.1 Ubah Format Export Excel Summary

**Backend:**
```
backend/routes/reports/summary.py → Ubah generate_excel_report()
backend/routes/reports/helpers.py → Update helper functions jika perlu
```

### 8.2 Ubah Format Export Excel Annual

**Backend:**
```
backend/routes/reports/annual.py  → Ubah fungsi:
  - get_annual_report_excel()
  - _build_annual_payload_from_db()
  - _write_secondary_summary_sheets()
backend/routes/reports/helpers.py → Update mapping functions
excel/                            → Update template Excel jika perlu
```

### 8.3 Ubah Format Export PDF

**Backend:**
```
backend/routes/reports/summary.py → Ubah:
  - export_summary_pdf()
  - generate_settlement_receipt()
  - generate_pdf_advance_report()
backend/routes/reports/annual.py  → Ubah _build_annual_pdf_bytes()
```

### 8.4 Ubah Tampilan Screen Laporan

**Frontend:**
```
frontend/lib/screens/report_screen.dart → Summary report UI
frontend/lib/screens/annual_report_screen.dart → Annual report UI
frontend/lib/providers/settlement_provider.dart → Export functions
```

---

## 9. DASHBOARD

### 9.1 Ubah Summary Cards (Angka di Dashboard)

**Backend:**
```
backend/routes/dashboard.py    → Ubah get_summary()
backend/models.py              → Tambah property jika perlu
```

**Frontend:**
```
frontend/lib/providers/dashboard_provider.dart → Ubah fetch logic
frontend/lib/screens/dashboard_screen.dart → Ubah _buildSummaryCards()
```

### 9.2 Ubah Notification Badges

**Backend:**
```
backend/routes/dashboard.py    → Ubah pending counts di get_summary()
backend/routes/notifications.py → Update create_notification() jika perlu
```

**Frontend:**
```
frontend/lib/providers/notification_provider.dart → Ubah unread count
frontend/lib/screens/widgets/sidebar.dart → Ubah badge display
frontend/lib/screens/dashboard_screen.dart → Ubah _fetchBadgeCounts()
```

---

## 10. NOTIFIKASI

### 10.1 Tambah Jenis Notifikasi Baru

**Backend:**
```
backend/routes/notifications.py → Tambah logic di create_notification() atau notify_managers()
backend/models.py               → Tambah action_type options jika perlu
```

**Frontend:**
```
frontend/lib/providers/notification_provider.dart → Tambah handler jika perlu
frontend/lib/screens/dashboard_screen.dart → Update notification display
```

### 10.2 Ubah Deep Link Notifikasi

**Backend:**
```
backend/routes/notifications.py → Ubah link_path di create_notification()
```

**Frontend:**
```
frontend/lib/providers/notification_provider.dart → Ubah navigasi di markAsRead()
```

---

## 11. USER/AUTH

### 11.1 Tambah Role Baru

**Backend:**
```
backend/models.py              → Tambah role options di class User
backend/routes/auth.py         → Update login() jika perlu
backend/routes/*.py            → Update permission checks di semua route
```

**Frontend:**
```
frontend/lib/providers/auth_provider.dart → Tambah role checker (isRoleX)
frontend/lib/screens/widgets/sidebar.dart → Update menu visibility
```

### 11.2 Ubah Login Flow

**Backend:**
```
backend/routes/auth.py         → Ubah login()
backend/models.py              → Ubah User class jika perlu
```

**Frontend:**
```
frontend/lib/providers/auth_provider.dart → Ubah login()
frontend/lib/screens/login_screen.dart → Update UI form
```

---

## 12. SETTINGS

### 12.1 Tambah Settings Baru

**Backend:**
```
backend/config.py              → Tambah config variable
backend/routes/settings.py     → Tambah endpoint baru
backend/models.py              → Tambah model jika settings perlu DB
```

**Frontend:**
```
frontend/lib/services/api_service.dart → Tambah API method
frontend/lib/providers/settings_provider.dart → Buat provider baru (atau pakai existing)
frontend/lib/screens/settings_screen.dart → Tambah UI control
```

---

## 📚 FILE KONFIGURASI PENTING

### Backend Config
```
backend/config.py              → SECRET_KEY, UPLOAD_FOLDER, DB URI, dll
backend/.env                   → Environment variables (jika pakai)
backend/requirements.txt       → Dependencies Python
```

### Frontend Config
```
frontend/pubspec.yaml          → Dependencies Flutter
frontend/lib/services/api_service.dart → Base URL configuration
```

---

## 🔧 FILE UTILITAS YANG SERING DIPAKAI

### Backend
```
backend/models.py              → Property/helper methods
backend/routes/reports/helpers.py → Excel/PDF helpers
backend/scripts/excel_to_app_db.py → Import utilities
```

### Frontend
```
frontend/lib/utils/currency_formatter.dart → Format angka
frontend/lib/utils/file_helper.dart → Save/export files
frontend/lib/theme/app_theme.dart → Theme colors
frontend/lib/widgets/          → Reusable components
```

---

## 📝 CHECKLIST SETELAH UBAH KODE

Setelah mengubah kode, pastikan untuk:

### Backend
- [ ] Run `python app.py` - cek tidak ada error startup
- [ ] Test endpoint yang diubah via Postman/browser
- [ ] Test role-based access (manager vs staff)
- [ ] Test export PDF/Excel jika terkait report
- [ ] Jalankan migration jika ada perubahan DB
- [ ] Backup database sebelum deploy

### Frontend
- [ ] Run `flutter analyze` - cek tidak ada error
- [ ] Run `flutter pub get` - update dependencies
- [ ] Hot reload/restart aplikasi
- [ ] Test UI yang diubah di berbagai screen size
- [ ] Test theme light/dark mode
- [ ] Test di desktop dan mobile jika memungkinkan

### Integrasi
- [ ] Test flow end-to-end (misal: create → submit → approve)
- [ ] Test notifikasi muncul dengan benar
- [ ] Test export functions
- [ ] Test search/filter jika ada
- [ ] Test dengan data real (bukan dummy)

---

## 🎯 CONTOH SKENARIO

### Skenario 1: Tambah Kolom "Vendor" di Expense

**Backend:**
1. `backend/models.py` - Tambah `vendor = db.Column(db.String(150))` di class Expense
2. `backend/routes/expenses.py` - Update `create_expense()` dan `update_expense()` untuk terima vendor
3. `backend/migrations/` - Buat migration: `flask db migrate -m "Add vendor to expenses"`

**Frontend:**
1. `frontend/lib/services/api_service.dart` - Update createExpense() untuk kirim vendor
2. `frontend/lib/providers/settlement_provider.dart` - Update addExpense() untuk include vendor
3. `frontend/lib/screens/settlement_detail_screen.dart` - Tambah input field vendor di dialog

### Skenario 2: Tambah Status Baru "Pending Finance" di Settlement

**Backend:**
1. `backend/models.py` - Tambah 'pending_finance' di docstring status Settlement
2. `backend/routes/settlements.py` - Update logic transisi status
3. `backend/routes/notifications.py` - Tambah notifikasi untuk status baru

**Frontend:**
1. `frontend/lib/providers/settlement_provider.dart` - Tambah status di filter
2. `frontend/lib/screens/dashboard_screen.dart` - Update status filter chips
3. `frontend/lib/screens/widgets/settlement_widgets.dart` - Tambah StatusBadge untuk status baru

### Skenario 3: Ubah Perhitungan Dashboard Summary

**Backend:**
1. `backend/routes/dashboard.py` - Ubah get_summary() dengan perhitungan baru
2. Test endpoint via browser: `http://localhost:5000/api/dashboard/summary`

**Frontend:**
1. `frontend/lib/providers/dashboard_provider.dart` - Update parsing response jika ada field baru
2. `frontend/lib/screens/dashboard_screen.dart` - Update _buildSummaryCards() jika ada display baru

---

## 📞 QUICK REFERENCE

### Backend Blueprint Registration
File: `backend/app.py`
```python
app.register_blueprint(auth_bp)
app.register_blueprint(dashboard_bp)
app.register_blueprint(settlements_bp)
# ... dst
```

### Frontend Provider Registration
File: `frontend/lib/main.dart`
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => DashboardProvider()),
    // ... dst
  ],
)
```

### API Endpoint Pattern
```
GET    /api/resource          → List
GET    /api/resource/<id>     → Detail
POST   /api/resource          → Create
PUT    /api/resource/<id>     → Update
DELETE /api/resource/<id>     → Delete
POST   /api/resource/<id>/action → Custom action
```

---

## 📚 DOKUMENTASI TERKAIT

- [DOKUMENTASI_UTAMA.md](../DOKUMENTASI_UTAMA.md) - Master documentation
- [CATATAN_PROYEK_KPI_EWI.md](../CATATAN_PROYEK_KPI_EWI.md) - Project notes
- [Panduan_Backend_ewi.md](Panduan_Backend_ewi.md) - Backend detail
- [Panduan_Frontend_ewi.md](Panduan_Frontend_ewi.md) - Frontend detail
