# DOKUMENTASI UTAMA - MiniProjectKPI_EWI

**Last Updated:** 22 Maret 2026  
**Status:** Aktif - Production Ready

Dokumen ini adalah **sumber kebenaran tunggal** untuk dokumentasi proyek. Jika ada perubahan kode, update dokumen ini terlebih dahulu.

---

## 📋 DAFTAR ISI

1. [Gambaran Umum](#1-gambaran-umum)
2. [Struktur Folder](#2-struktur-folder)
3. [Backend - Models](#3-backend---models)
4. [Backend - API Routes](#4-backend---api-routes)
5. [Frontend - Struktur](#5-frontend---struktur)
6. [Alur Bisnis](#6-alur-bisnis)
7. [Deployment](#7-deployment)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Gambaran Umum

Sistem manajemen keuangan operasional untuk Exspan Wireline Indonesia.

### Fitur Utama
- ✅ **Advance/Kasbon** dengan revisi (Revisi 1, Revisi 2)
- ✅ **Settlement** realisasi pengeluaran dengan link ke Advance
- ✅ **Expense** multi-currency dengan upload evidence
- ✅ **Kategori** parent-child dengan approval workflow
- ✅ **Revenue & Tax** management
- ✅ **Dividen** dengan settings neraca per tahun
- ✅ **Laporan** Summary, Annual, Advance, Settlement (Excel/PDF)
- ✅ **Dashboard** dengan summary cards dan notification badges
- ✅ **Search & Filter** data
- ✅ **Notifikasi** in-app dengan deep-link
- ✅ **Role-based access** (Manager, Staff, Mitra Eks)

### Teknologi
| Komponen | Teknologi |
|----------|-----------|
| Backend | Python 3.x, Flask, SQLAlchemy, JWT, OpenPyXL, ReportLab, SQLite |
| Frontend | Flutter (Dart), Provider, HTTP, Shared Preferences |
| Deployment | Cloudflare Tunnel (akses HP), Local Server |

---

## 2. Struktur Folder

```
MiniProjectKPI_EWI/
├── backend/
│   ├── app.py                    # Entry point, register blueprints
│   ├── config.py                 # Konfigurasi aplikasi
│   ├── models.py                 # Database models (10 tables)
│   ├── routes/                   # API endpoints
│   │   ├── auth.py               # Login, user management
│   │   ├── dashboard.py          # Dashboard summary
│   │   ├── settlements.py        # Settlement CRUD + workflow
│   │   ├── expenses.py           # Expense CRUD + approval
│   │   ├── advances.py           # Advance CRUD + revisi
│   │   ├── categories.py         # Kategori management
│   │   ├── revenues.py           # Revenue CRUD
│   │   ├── taxes.py              # Tax CRUD
│   │   ├── dividends.py          # Dividen + neraca settings
│   │   ├── notifications.py      # Notifikasi in-app
│   │   ├── settings.py           # App settings
│   │   └── reports/              # Package laporan
│   │       ├── __init__.py       # Blueprint registration
│   │       ├── helpers.py        # Excel/PDF helpers
│   │       ├── summary.py        # Summary report endpoints
│   │       └── annual.py         # Annual report endpoints
│   ├── scripts/                  # Data migration utilities
│   │   └── excel_to_app_db.py    # Import Excel ke DB
│   ├── uploads/                  # File evidence storage
│   └── exports/                  # Export report storage
│
├── frontend/lib/
│   ├── main.dart                 # Entry point
│   ├── services/
│   │   ├── api_service.dart      # API gateway
│   │   └── notification_service.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── settlement_provider.dart
│   │   ├── advance_provider.dart
│   │   ├── revenue_provider.dart
│   │   ├── tax_provider.dart
│   │   ├── dividend_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/
│   │   ├── dashboard_screen.dart
│   │   ├── settlement_detail_screen.dart
│   │   ├── advance/
│   │   │   ├── my_advances_screen.dart
│   │   │   └── advance_detail_screen.dart
│   │   ├── manager/
│   │   │   ├── manager_dashboard_screen.dart
│   │   │   └── manager_settlement_detail_screen.dart
│   │   ├── report_screen.dart
│   │   ├── annual_report_screen.dart
│   │   ├── revenue_management_screen.dart
│   │   ├── tax_management_screen.dart
│   │   ├── dividend_management_screen.dart
│   │   ├── balance_sheet_settings_screen.dart
│   │   ├── category_management_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/                  # Reusable UI components
│   ├── theme/
│   └── utils/
│
└── panduan/                      # Dokumentasi detail
    ├── Panduan_Backend_ewi.md
    ├── Panduan_Frontend_ewi.md
    └── PANDUAN_EXCEL_EXPORT.md
```

---

## 3. Backend - Models

File: `backend/models.py` (594 baris)

### 3.1 User
```python
class User:
    # Kolom: id, username, password_hash, full_name, role, created_at
    # Role: manager, staff, mitra_eks
    # Relasi: settlements, advances, notifications_received, notifications_created
```

### 3.2 Category
```python
class Category:
    # Kolom: id, name, code, parent_id, status, created_by
    # Status: approved, pending
    # Property: full_name (parent > child)
    # Relasi: children, expenses
```

### 3.3 Advance (Kasbon)
```python
class Advance:
    # Kolom: id, title, description, advance_type, user_id, status, notes,
    #        approved_revision_no, active_revision_no, created_at, updated_at, approved_at
    # Status: draft, submitted, approved, rejected, revision_draft, 
    #        revision_submitted, revision_rejected, in_settlement, completed
    # Property: total_amount, approved_amount, base_amount, revision_amount, max_revision_no
    # Relasi: settlement (one-to-one), items (one-to-many), requester
```

### 3.4 AdvanceItem
```python
class AdvanceItem:
    # Kolom: id, advance_id, category_id, description, estimated_amount, revision_no,
    #        evidence_path, evidence_filename, date, source, currency, currency_exchange,
    #        status, notes, created_at
    # Relasi: category, advance
```

### 3.5 Settlement
```python
class Settlement:
    # Kolom: id, title, description, user_id, settlement_type, status,
    #        advance_id, created_at, updated_at, completed_at
    # Type: single, batch
    # Status: draft, submitted, approved, rejected, completed
    # Property: total_amount, approved_amount
    # Relasi: advance, expenses, creator
```

### 3.6 Expense
```python
class Expense:
    # Kolom: id, settlement_id, category_id, description, amount, date, source,
    #        advance_item_id, revision_no, currency, currency_exchange,
    #        evidence_path, evidence_filename, status, notes, created_at
    # Status: pending, approved, rejected
    # Property: idr_amount (auto calculate if multi-currency)
    # Relasi: settlement, category, advance_item
```

### 3.7 Revenue
```python
class Revenue:
    # Kolom: id, invoice_date, description, invoice_value, currency, currency_exchange,
    #        invoice_number, client, receive_date, amount_received,
    #        ppn, pph_23, transfer_fee, remark, created_at
    # Property: idr_invoice_value, idr_amount_received
```

### 3.8 Tax
```python
class Tax:
    # Kolom: id, date, description, transaction_value, currency, currency_exchange,
    #        ppn, pph_21, pph_23, pph_26, created_at
    # Property: idr_transaction_value
```

### 3.9 Dividend
```python
class Dividend:
    # Kolom: id, date, name, amount, recipient_count, tax_percentage, created_at
```

### 3.10 DividendSetting
```python
class DividendSetting:
    # Kolom: id, year, profit_retained, opening_cash_balance,
    #        accounts_receivable, prepaid_tax_pph23, prepaid_expenses,
    #        other_receivables, office_inventory, other_assets,
    #        accounts_payable, salary_payable, shareholder_payable,
    #        accrued_expenses, share_capital, retained_earnings_balance, created_at
```

### 3.11 Notification
```python
class Notification:
    # Kolom: id, user_id, actor_id, action_type, target_type, target_id,
    #        message, read_status, created_at, link_path
    # action_type: submit, approve, reject, create
    # target_type: settlement, advance, category
```

### 3.12 ManualCombineGroup
```python
class ManualCombineGroup:
    # Kolom: id, table_name, report_year, group_date, row_ids_json, created_at
```

---

## 4. Backend - API Routes

### 4.1 Auth (`/api/auth`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/login` | Login, return JWT token |
| GET | `/me` | Profile user aktif |
| GET | `/users` | List user (manager only) |
| POST | `/users` | Create user (manager only) |

### 4.2 Dashboard (`/api/dashboard`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/summary` | Dashboard summary (pending counts, expenses bulan ini) |

### 4.3 Notifications (`/api/notifications`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List notifikasi user |
| POST | `/<id>/read` | Mark as read |
| DELETE | `/<id>` | Delete notification |

### 4.4 Advances (`/api/advances`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List advances (filter: status, date, search) |
| POST | `/` | Create advance |
| GET | `/<id>` | Detail advance + items |
| PUT | `/<id>` | Update advance (draft/rejected only) |
| DELETE | `/<id>` | Delete advance draft |
| POST | `/<id>/items` | Add item + upload evidence |
| PUT | `/items/<id>` | Update item |
| DELETE | `/items/<id>` | Delete item |
| POST | `/<id>/submit` | Submit advance |
| POST | `/<id>/approve_all` | Approve advance (manager) |
| POST | `/<id>/reject_all` | Reject advance (manager) |
| POST | `/<id>/start_revision` | Start revision (manager) |
| POST | `/<id>/create_settlement` | Create settlement from advance |

### 4.5 Settlements (`/api/settlements`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List settlements (filter: status, date, search) |
| POST | `/` | Create settlement |
| GET | `/<id>` | Detail settlement + expenses |
| PUT | `/<id>` | Update settlement |
| DELETE | `/<id>` | Delete settlement draft |
| POST | `/<id>/submit` | Submit settlement |
| POST | `/<id>/approve` | Approve settlement (manager) |
| POST | `/<id>/approve_all` | Approve all expenses (manager) |
| POST | `/<id>/reject_all` | Reject all expenses (manager) |
| POST | `/<id>/complete` | Complete settlement |

### 4.6 Expenses (`/api/expenses`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/` | Create expense + upload evidence |
| PUT | `/<id>` | Update expense |
| DELETE | `/<id>` | Delete expense |
| POST | `/<id>/approve` | Approve expense (manager) |
| POST | `/<id>/reject` | Reject expense (manager) |
| GET | `/evidence/<path>` | Serve evidence file |
| GET | `/categories` | List approved categories |

### 4.7 Categories (`/api/categories`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List categories |
| GET | `/pending` | List pending categories (manager) |
| POST | `/` | Create category |
| PUT | `/<id>` | Update category (manager) |
| DELETE | `/<id>` | Delete category |
| POST | `/<id>/approve` | Approve/reject category (manager) |

### 4.8 Revenues (`/api/revenues`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List revenues (filter: date) |
| POST | `/` | Create revenue (manager) |
| PUT | `/<id>` | Update revenue (manager) |
| DELETE | `/<id>` | Delete revenue (manager) |

### 4.9 Taxes (`/api/taxes`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List taxes (filter: date) |
| POST | `/` | Create tax (manager) |
| PUT | `/<id>` | Update tax (manager) |
| DELETE | `/<id>` | Delete tax (manager) |

### 4.10 Dividends (`/api/dividends`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/` | List dividends |
| POST | `/` | Create dividend (manager) |
| PUT | `/<id>` | Update dividend (manager) |
| DELETE | `/<id>` | Delete dividend (manager) |
| GET | `/dividend-settings` | Get dividend settings by year |
| POST | `/dividend-settings` | Update dividend settings |

### 4.11 Settings (`/api/settings`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET/POST | `/storage` | Get/set storage folder |
| GET/POST | `/report-year` | Get/set default report year |

### 4.12 Reports (`/api/reports`)
| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| GET | `/summary` | Summary report JSON |
| GET | `/summary/pdf` | Export summary PDF |
| GET | `/excel` | Export summary Excel |
| GET | `/excel_advance` | Export advance Excel |
| GET | `/advance/<id>/pdf` | Export advance PDF |
| GET | `/settlement/<id>/receipt` | Export settlement receipt PDF |
| GET | `/settlements/pdf` | Bulk settlements PDF |
| GET | `/advances/pdf` | Bulk advances PDF |
| GET | `/annual` | Annual report JSON (cached) |
| GET | `/annual/pdf` | Annual PDF (cached) |
| GET | `/annual/excel` | Annual Excel (template-based) |

---

## 5. Frontend - Struktur

### 5.1 Providers

| Provider | Fungsi Utama |
|----------|--------------|
| `AuthProvider` | Login/logout, token management, role check |
| `DashboardProvider` | Fetch dashboard summary |
| `NotificationProvider` | Fetch notifications, mark read, delete |
| `SettlementProvider` | CRUD settlement + expense, category management |
| `AdvanceProvider` | CRUD advance + items, revision flow, create settlement |
| `RevenueProvider` | CRUD revenue |
| `TaxProvider` | CRUD tax |
| `DividendProvider` | CRUD dividend, dividend settings |
| `ThemeProvider` | Theme management (light/dark/system) |

### 5.2 Screens

| Screen | Fungsi |
|--------|--------|
| `DashboardScreen` | Home page, summary cards, settlement list, navigation |
| `SettlementDetailScreen` | Detail settlement, expense management, approval |
| `MyAdvancesScreen` | List advances, filter by status |
| `AdvanceDetailScreen` | Detail advance, item management, revision, create settlement |
| `ReportScreen` | Summary report, export PDF/Excel |
| `AnnualReportScreen` | Annual report, export PDF/Excel |
| `RevenueManagementScreen` | CRUD revenue |
| `TaxManagementScreen` | CRUD tax |
| `DividendManagementScreen` | CRUD dividend |
| `BalanceSheetSettingsScreen` | Neraca settings untuk dividen |
| `CategoryManagementScreen` | CRUD kategori (manager) |
| `SettingsScreen` | App settings (theme, storage, report year) |
| `ManagerDashboardScreen` | Manager approval dashboard |
| `ManagerSettlementDetailScreen` | Manager approval detail |

### 5.3 API Service

File: `frontend/lib/services/api_service.dart`

**Base URL Configuration:**
- Desktop/Web: `http://localhost:5000/api`
- Android Emulator: `http://10.0.2.2:5000/api`
- Physical Device (Cloudflare): `https://xxx.trycloudflare.com/api`

**Runtime Config:**
```bash
flutter run -d android --dart-define=API_BASE_URL=https://xxx.trycloudflare.com/api
```

---

## 6. Alur Bisnis

### 6.1 Advance (Kasbon) Flow
```
1. User buat Advance (draft)
2. User tambah Advance Items + upload evidence
3. User submit Advance → status: submitted
4. Manager approve/reject
   - Approve → status: approved
   - Reject → status: rejected
5. (Optional) Manager start revision → status: revision_draft
6. User buat Settlement dari Advance approved
   → status advance: in_settlement
```

### 6.2 Settlement Flow
```
1. User buat Settlement (dari Advance atau manual)
2. User tambah Expenses + upload evidence
3. User submit Settlement → status: submitted
4. Manager approve expenses (per item atau bulk)
5. Manager approve settlement
6. Manager complete settlement → status: completed
   → Update advance status: completed
```

### 6.3 Revision Flow
```
1. Advance approved → Manager start revision
2. Status: revision_draft
3. User tambah revision items
4. Submit revision → status: revision_submitted
5. Manager approve/reject revision
   - Approve → approved_revision_no incremented
   - Reject → status: revision_rejected
6. Max 2 revisi (Revisi 1, Revisi 2)
```

### 6.4 Report Flow
```
1. Summary Report: Expense approved per kategori per bulan
2. Annual Report: Revenue + Tax + Expense + Dividend
   - Template-based Excel export
   - Cache system untuk performance
   - Secondary sheets: Laba Rugi, Business Summary
```

---

## 7. Deployment

### 7.1 Development Setup

**Backend:**
```bash
cd backend
venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

**Frontend Desktop:**
```bash
cd frontend
flutter pub get
flutter run -d windows
```

**Frontend Mobile (via Cloudflare):**
```bash
# Terminal 1: Start Cloudflare Tunnel
cloudflared tunnel --url http://localhost:5000

# Terminal 2: Run Flutter dengan URL
flutter run -d android --dart-define=API_BASE_URL=https://xxx.trycloudflare.com/api
```

### 7.2 Production Checklist

- [ ] Backup database (`database.db`)
- [ ] Set production `SECRET_KEY` di `config.py`
- [ ] Configure upload folder path
- [ ] Test Cloudflare tunnel stability
- [ ] Verify all export functions (PDF/Excel)
- [ ] Test notification system
- [ ] Verify role-based access control

### 7.3 Database Migration

```bash
cd backend
flask db migrate -m "pesan migrasi"
flask db upgrade
```

### 7.4 Import Data dari Excel

```bash
cd backend/scripts
python excel_to_app_db.py --excel path/to/file.xlsx
```

---

## 8. Troubleshooting

### 8.1 Common Issues

**Backend tidak bisa start:**
```
- Cek virtual environment aktif
- Verify requirements.txt installed
- Cek port 5000 tidak dipakai aplikasi lain
```

**Frontend tidak bisa connect:**
```
- Verify base URL sesuai (localhost vs Cloudflare)
- Cek backend running
- Test endpoint via browser/Postman
```

**Export Excel/PDF gagal:**
```
- Cek folder exports/ writable
- Verify template Excel ada di folder excel/
- Clear cache: exports/annual_cache/
```

**Cache Annual Report stale:**
```
- Hapus file di exports/annual_cache/
- Atau akses endpoint dengan ?refresh=true
```

**Database schema error:**
```
- Jalankan migration: flask db upgrade
- Auto-patch functions akan run di app startup
```

### 8.2 Known Limitations

| Fitur | Status | Catatan |
|-------|--------|---------|
| Multi-level approval | ❌ | Hanya 1 level (Manager) |
| Policy limitation | ❌ | Tidak ada batas claim |
| Email notification | ❌ | Hanya in-app notification |
| Backup approver | ❌ | Tidak ada |
| Division access | ❌ | Tidak ada pembatasan divisi |
| Custom fields | ❌ | Tidak ada field custom |
| Business trip | ❌ | Disengaja tidak dibuat |

### 8.3 Technical Debt

1. **manager_dashboard_screen.dart** - Status/field tidak sinkron dengan model terbaru
2. **reports/ package** - Hardcoded row/col, sensitif terhadap perubahan template
3. **report_entry_tags table** - Tidak ada di models.py tapi dipakai
4. **Category mapping** - Keyword-based, risiko salah mapping

---

## 📝 Change Log

| Tanggal | Perubahan | File Tersentuh |
|---------|-----------|----------------|
| 22 Mar 2026 | Update dokumentasi utama | DOKUMENTASI_UTAMA.md |
| | - Tambah Dividend models | |
| | - Tambah Notification models | |
| | - Tambah dashboard routes | |
| | - Tambah revision flow docs | |

---

## 📚 Referensi

- [CATATAN_PROYEK_KPI_EWI.md](../CATATAN_PROYEK_KPI_EWI.md) - Catatan lengkap proyek
- [panduan/Panduan_Backend_ewi.md](Panduan_Backend_ewi.md) - Detail backend
- [panduan/Panduan_Frontend_ewi.md](Panduan_Frontend_ewi.md) - Detail frontend
- [PANDUAN_EXCEL_EXPORT.md](../PANDUAN_EXCEL_EXPORT.md) - Panduan export Excel
