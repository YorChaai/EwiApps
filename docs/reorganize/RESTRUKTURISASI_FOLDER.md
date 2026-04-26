# Rekomendasi Restrukturisasi Folder - MiniProjectKPI_EWI

> **Tanggal:** 12 April 2026  
> **Tujuan:** Merapikan struktur folder frontend & backend agar lebih profesional, maintainable, dan mudah dipahami.

---

## 📋 Daftar Isi
1. [Masalah Saat Ini](#-masalah-saat-ini)
2. [File yang Dihapus](#-file-yang-dihapus)
3. [File yang Dipindahkan](#-file-yang-dipindahkan)
4. [Struktur BEFORE vs AFTER - Frontend](#-struktur-before-vs-after---frontend)
5. [Struktur BEFORE vs AFTER - Backend](#-struktur-before-vs-after---backend)
6. [Analisis: Apakah Ada File yang Harus Dibagi?](#-analisis-apakah-ada-file-yang-harus-dibagi)
7. [Langkah Eksekusi](#-langkah-eksekusi)

---

## 🔴 Masalah Saat Ini

### Frontend
| No | Masalah | Detail |
|----|---------|--------|
| 1 | File Python di folder Flutter | `repair.py` tidak seharusnya ada |
| 2 | File test di root | `test_fetch.dart` seharusnya di `test/` |
| 3 | Backup file di folder produksi | `settings_screen_backup.dart` |
| 4 | Script batch tidak jelas | `change_icon.bat` |
| 5 | File debug output | `analyze_output.txt` |

### Backend
| No | Masalah | Detail |
|----|---------|--------|
| 1 | **15 file migration/debug** di root folder | Semua one-time script bercampur dengan production code |
| 2 | **18 script debug Excel** di `scripts/` | Semua sudah tidak diperlukan |
| 3 | **7 file archive** di `_archive/` | Kode lama yang tidak dipakai |
| 4 | **3 database files** tidak terpakai | `app.db`, `database_import_dividen.db`, `ewi.db` |
| 5 | **Backup folder** di routes | `routes/reports/backup/` |
| 6 | **Dokumentasi** di folder kode | `CODE_ANALYSIS_REPORT.md` |
| 7 | **Database di root** | `database.db` seharusnya di folder `data/` |
| 8 | **Migrations tools** di root | `migrate.py` seharusnya di `tools/` |

---

## 🗑️ File yang Dihapus

### Frontend - Dihapus (5 files)

| No | File Path | Alasan |
|----|-----------|--------|
| 1 | `frontend/change_icon.bat` | Script sementara, tidak diperlukan |
| 2 | `frontend/repair.py` | Python script di folder Flutter - salah tempat |
| 3 | `frontend/test_fetch.dart` | Akan **dipindahkan** ke `test/` (bukan dihapus) |
| 4 | `frontend/lib/screens/settings_screen_backup.dart` | Backup file, tidak perlu di repo |
| 5 | `frontend/analyze_output.txt` | Debug output, tidak diperlukan |

### Backend - Dihapus (40+ files)

| No | File/Folder | Alasan |
|----|-------------|--------|
| 1 | `backend/debug_titles.py` | Debug script - sudah selesai |
| 2 | `backend/fix_existing_titles.py` | One-time migration |
| 3 | `backend/fix_remark.py` | One-time migration |
| 4 | `backend/fix_remark_database.sql` | SQL sudah dijalankan |
| 5 | `backend/test_api_revenue_type.py` | Test temporary |
| 6 | `backend/test_revenue_type.py` | Test temporary |
| 7 | `backend/migrate_add_last_login.py` | Migration sudah dijalankan |
| 8 | `backend/migrate_add_revenue_type.py` | Migration sudah dijalankan |
| 9 | `backend/migrate_add_revenue_type_simple.py` | Migration sudah dijalankan |
| 10 | `backend/migrate_evidence.py` | Migration sudah dijalankan |
| 11 | `backend/migrate_sort_order.py` | Migration sudah dijalankan |
| 12 | `backend/migrate_sort_order_simple.py` | Migration sudah dijalankan |
| 13 | `backend/scripts/` **(seluruh folder - 18 files)** | Debug Excel scripts - tidak diperlukan |
| 14 | `backend/_archive/` **(seluruh folder - 7 files)** | Archive kode lama |
| 15 | `backend/routes/reports/backup/` **(3 files)** | Backup files |
| 16 | `backend/routes/reports/CODE_ANALYSIS_REPORT.md` | Dokumentasi bukan di folder kode |
| 17 | `backend/app.db` | Database tidak terpakai |
| 18 | `backend/database_import_dividen.db` | Database tidak terpakai |
| 19 | `backend/ewi.db` | Database tidak terpakai |

> **Catatan:** Yang dipakai cuma `database.db`

---

## 📦 File yang Dipindahkan

### Frontend - Dipindahkan (1 file)

| No | File | Dari | Ke | Alasan |
|----|------|------|---|--------|
| 1 | `test_fetch.dart` | `frontend/` | `frontend/test/` | File test harusnya di folder test |

### Backend - Dipindahkan (4 items)

| No | File/Folder | Dari | Ke | Alasan |
|----|-------------|------|---|--------|
| 1 | `database.db` | `backend/` | `backend/data/` | Database file不应该 di root |
| 2 | `migrate.py` | `backend/` | `backend/tools/` | Migration tool不应该 di root |
| 3 | `migrations/` | `backend/` | `backend/tools/migrations/` | Migration files不应该 di root |
| 4 | `exports/` | `backend/` | `backend/data/exports/` | Export files data |

---

## 📁 Struktur BEFORE vs AFTER - FRONTEND

### BEFORE (Tidak Rapi)

```
frontend/
├── .dart_tool/                          ← Auto-generated
├── .idea/                               ← IDE config
├── android/                             ← Platform
├── ios/                                 ← Platform
├── linux/                               ← Platform
├── macos/                               ← Platform
├── web/                                 ← Platform
├── windows/                             ← Platform
├── build/                               ← Build output
├── assets/
│   └── images/
│       ├── logo_exspan.png
│       └── logo_exspan_launcher.png
├── lib/
│   ├── main.dart
│   ├── models/                          (1 file)
│   ├── providers/                       (8 files)
│   ├── screens/                         (17 files)
│   │   ├── advance/                     (2 files)
│   │   ├── manager/                     (2 files)
│   │   ├── widgets/                     (4 files)
│   │   └── *.dart                       (11 files di root - TIDAK RAPI!)
│   ├── services/                        (2 files)
│   ├── theme/                           (1 file)
│   ├── utils/                           (7 files)
│   └── widgets/                         (4 files)
├── test/
│   └── widget_test.dart
│
│   ❌ change_icon.bat                   ← SALAH POSISI
│   ❌ repair.py                         ← PYTHON DI FLUTTER!
│   ❌ test_fetch.dart                   ← HARUSNYA DI test/
│   ❌ analyze_output.txt                ← DEBUG OUTPUT
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── .gitignore
├── .metadata
└── devtools_options.yaml
```

### AFTER (Rapi)

```
frontend/
│
├── 📱 KODE SUMBER
│   └── lib/
│       ├── main.dart
│       ├── models/
│       │   └── notification_model.dart
│       ├── providers/
│       │   ├── advance_provider.dart
│       │   ├── auth_provider.dart
│       │   ├── dividend_provider.dart
│       │   ├── notification_provider.dart
│       │   ├── revenue_provider.dart
│       │   ├── settlement_provider.dart
│       │   ├── tax_provider.dart
│       │   └── theme_provider.dart
│       ├── screens/
│       │   ├── advance/
│       │   │   ├── advance_detail_screen.dart
│       │   │   └── my_advances_screen.dart
│       │   ├── manager/
│       │   │   ├── manager_dashboard_screen.dart
│       │   │   └── manager_settlement_detail_screen.dart
│       │   ├── settings/                ← BARU: Pisahkan settings
│       │   │   ├── settings_screen.dart
│       │   │   └── balance_sheet_settings_screen.dart
│       │   ├── report/                  ← BARU: Pisahkan reports
│       │   │   ├── report_screen.dart
│       │   │   └── annual_report_screen.dart
│       │   ├── management/              ← BARU: Management screens
│       │   │   ├── category_management_screen.dart
│       │   │   ├── category_tabular_screen.dart
│       │   │   ├── revenue_management_screen.dart
│       │   │   ├── tax_management_screen.dart
│       │   │   └── dividend_management_screen.dart
│       │   ├── auth/                    ← BARU: Auth screens
│       │   │   ├── login_screen.dart
│       │   │   └── register_screen.dart
│       │   ├── widgets/
│       │   │   ├── page_selector.dart
│       │   │   ├── settlement_detail_widgets.dart
│       │   │   ├── settlement_widgets.dart
│       │   │   └── sidebar.dart
│       │   ├── dashboard_screen.dart
│       │   └── settlement_detail_screen.dart
│       ├── services/
│       │   ├── api_service.dart
│       │   └── notification_service.dart
│       ├── theme/
│       │   └── app_theme.dart
│       ├── utils/
│       │   ├── app_formatters.dart
│       │   ├── app_snackbar.dart
│       │   ├── context_extensions.dart
│       │   ├── currency_formatter.dart
│       │   ├── file_helper.dart
│       │   ├── responsive_layout.dart
│       │   └── status_colors.dart
│       └── widgets/
│           ├── account_list_dialog.dart
│           ├── app_brand_logo.dart
│           ├── notification_bell_icon.dart
│           └── user_info_dialog.dart
│
├── 🧪 TESTING
│   └── test/
│       ├── widget_test.dart
│       └── test_fetch.dart              ← DIPINDAHKAN
│
├── 🎨 ASSETS
│   └── assets/
│       └── images/
│           ├── logo_exspan.png
│           └── logo_exspan_launcher.png
│
├── ⚙️ KONFIGURASI
│   ├── pubspec.yaml
│   ├── analysis_options.yaml
│   ├── devtools_options.yaml
│   ├── .gitignore
│   ├── .metadata
│   └── README.md
│
└── 🗑️ DIHAPUS
    ├── change_icon.dart                 ← DIHAPUS
    ├── repair.py                        ← DIHAPUS
    └── analyze_output.txt               ← DIHAPUS
```

**Perubahan Frontend:**
| Aksi | Jumlah |
|------|--------|
| Dihapus | 4 files |
| Dipindahkan | 1 file |
| Folder baru dibuat | 4 folders (`settings/`, `report/`, `management/`, `auth/`) |
| File dipindah ke subfolder | 8 files |

---

## 📁 Struktur BEFORE vs AFTER - BACKEND

### BEFORE (Tidak Rapi)

```
backend/
│
│   ✅ app.py                            ← PRODUCTION
│   ✅ config.py                         ← PRODUCTION
│   ✅ models.py                         ← PRODUCTION
│   ✅ requirements.txt                  ← PRODUCTION
│   ✅ .env                              ← PRODUCTION
│
│   ❌ debug_titles.py                   ← DEBUG
│   ❌ fix_existing_titles.py            ← ONE-TIME
│   ❌ fix_remark.py                     ← ONE-TIME
│   ❌ fix_remark_database.sql           ← SUDAH DIJALANKAN
│   ❌ test_api_revenue_type.py          ← TEST
│   ❌ test_revenue_type.py              ← TEST
│   ❌ migrate_add_last_login.py         ← MIGRATION
│   ❌ migrate_add_revenue_type.py       ← MIGRATION
│   ❌ migrate_add_revenue_type_simple.py ← MIGRATION
│   ❌ migrate_evidence.py               ← MIGRATION
│   ❌ migrate_sort_order.py             ← MIGRATION
│   ❌ migrate_sort_order_simple.py      ← MIGRATION
│   ❌ migrate.py                        ← TOOL (salah posisi)
│   ❌ app.db                            ← DB TIDAK DIPAKAI
│   ❌ database.db                       ← DB (salah posisi)
│   ❌ database_import_dividen.db        ← DB TIDAK DIPAKAI
│   ❌ ewi.db                            ← DB TIDAK DIPAKAI
│
├── routes/                              ✅ PRODUCTION (rapi)
│   ├── __init__.py
│   ├── auth.py
│   ├── settlements.py
│   ├── expenses.py
│   ├── advances.py
│   ├── categories.py
│   ├── revenues.py
│   ├── taxes.py
│   ├── dividends.py
│   ├── dashboard.py
│   ├── notifications.py
│   ├── settings.py
│   └── reports/
│       ├── __init__.py
│       ├── annual.py
│       ├── summary.py
│       ├── helpers.py
│       ├── ❌ CODE_ANALYSIS_REPORT.md   ← DOKUMENTASI
│       └── ❌ backup/                   ← BACKUP
│           ├── annual_backup.py
│           ├── helpers_backup.py
│           └── summary_backup.py
│
├── ❌ scripts/                          ← 18 DEBUG SCRIPTS
│   ├── analyze_correct_file.py
│   ├── analyze_merge_structure.py
│   ├── analyze_template.py
│   ├── check_correct_gap.py
│   ├── check_gap_structure.py
│   ├── clean_excel_template.py
│   ├── clean_subcategory.py
│   ├── compare_templates.py
│   ├── debug_annual.py
│   ├── debug_annual_mapping.py
│   ├── debug_excel.py
│   ├── debug_expense_items.py
│   ├── excel_to_app_db.py
│   ├── gen_restore.py
│   ├── test_excel_output.py
│   ├── test_export_fix.py
│   ├── verify_subcategories.py
│   └── analysis_output.txt
│
├── ❌ _archive/                         ← 7 OLD FILES
│   ├── read_excel.py
│   ├── read_excel2.py
│   ├── read_excel_output.txt
│   ├── temp_check.py
│   ├── temp_inspect.py
│   ├── update_categories.py
│   └── update_excel_db.py
│
├── uploads/                             ✅ PRODUCTION
├── exports/                             ✅ PRODUCTION (salah posisi)
└── migrations/                          ✅ PRODUCTION (salah posisi)
    ├── alembic.ini
    ├── env.py
    └── versions/
        └── add_revenue_type_to_revenues.sql
```

### AFTER (Rapi)

```
backend/
│
├── 🚀 PRODUCTION CODE
│   ├── app.py                           ← Main Flask App
│   ├── config.py                        ← Configuration
│   ├── models.py                        ← Database Models
│   ├── requirements.txt                 ← Dependencies
│   └── .env                             ← Environment Variables
│
├── 🔧 ROUTES (API Endpoints)
│   └── routes/
│       ├── __init__.py
│       ├── auth.py
│       ├── settlements.py
│       ├── expenses.py
│       ├── advances.py
│       ├── categories.py
│       ├── revenues.py
│       ├── taxes.py
│       ├── dividends.py
│       ├── dashboard.py
│       ├── notifications.py
│       ├── settings.py
│       └── reports/
│           ├── __init__.py
│           ├── annual.py
│           ├── summary.py
│           └── helpers.py
│
├── 📊 DATA
│   ├── database.db                      ← DIPINDAHKAN
│   └── exports/                         ← DIPINDAHKAN
│
├── 📤 UPLOADS (User Files)
│   └── uploads/
│       └── *.pdf (bukti expense)
│
├── 🛠️ TOOLS
│   ├── migrate.py                       ← DIPINDAHKAN
│   └── migrations/                      ← DIPINDAHKAN
│       ├── alembic.ini
│       ├── env.py
│       └── versions/
│           └── add_revenue_type_to_revenues.sql
│
└── 🗑️ DIHAPUS
    ├── debug_titles.py
    ├── fix_existing_titles.py
    ├── fix_remark.py
    ├── fix_remark_database.sql
    ├── test_api_revenue_type.py
    ├── test_revenue_type.py
    ├── migrate_add_*.py (6 files)
    ├── migrate_sort_order*.py (2 files)
    ├── migrate_evidence.py
    ├── scripts/ (18 files)
    ├── _archive/ (7 files)
    ├── routes/reports/backup/ (3 files)
    ├── routes/reports/CODE_ANALYSIS_REPORT.md
    ├── app.db
    ├── database_import_dividen.db
    └── ewi.db
```

**Perubahan Backend:**
| Aksi | Jumlah |
|------|--------|
| Dihapus | ~40 files |
| Dipindahkan | 4 items |
| Folder baru dibuat | 3 folders (`data/`, `tools/`, `tools/migrations/`) |

---

## 🔍 Analisis: Apakah Ada File yang Harus Dibagi?

### ✅ YA - File yang Terlalu Besar dan Harus Dibagi

#### 1. `backend/routes/reports/annual.py` - 2,461 baris 🔴🔴🔴

**Masalah:** File TERLALU BESAR, menangani 3 fungsi sekaligus.

**Rekomendasi: Bagi jadi 3 file**

```
backend/routes/reports/
├── annual/                              ← BARU: Folder
│   ├── __init__.py
│   ├── routes.py                        ← API endpoints saja (~300 baris)
│   ├── excel_generator.py               ← Excel export logic (~1,200 baris)
│   └── pdf_generator.py                 ← PDF export logic (~900 baris)
├── summary.py                           ← Tetap (580 baris - masih OK)
└── helpers.py                           ← Tetap (580 baris - masih OK)
```

**Alasan:**
- ✅ **Separation of Concerns**: Routes ≠ Business Logic
- ✅ **Lebih mudah ditest**: Excel logic bisa ditest terpisah dari PDF
- ✅ **Lebih mudah di-maintain**: Kalau ada bug di Excel, langsung buka `excel_generator.py`

---

#### 2. `frontend/lib/screens/dashboard_screen.dart` - 1,758 baris 🔴

**Masalah:** File screen TERLALU BESAR, menangani semua UI dashboard.

**Rekomendasi: Bagi berdasarkan section**

```
frontend/lib/screens/
├── dashboard/                           ← BARU: Folder
│   ├── dashboard_screen.dart            ← Main screen (~300 baris)
│   ├── dashboard_summary_card.dart      ← Summary cards widget
│   ├── dashboard_settlement_list.dart   ← Settlement list widget
│   ├── dashboard_advance_list.dart      ← Advance list widget
│   └── dashboard_stats_chart.dart       ← Chart widget
```

**Alasan:**
- ✅ **Widget reuse**: Setiap bagian bisa dipakai ulang
- ✅ **Lebih mudah dibaca**: Setiap file fokus 1 komponen
- ✅ **Lebih mudah test**: Widget kecil lebih mudah ditest

---

#### 3. `frontend/lib/services/api_service.dart` - 1,262 baris 🟡

**Masalah:** Terlalu banyak endpoint (50+) dalam 1 file.

**Rekomendasi: Opsional - Bagi berdasarkan resource**

```
frontend/lib/services/
├── api/                                 ← BARU: Folder
│   ├── api_client.dart                  ← HTTP client base (~200 baris)
│   ├── auth_service.dart                ← Auth endpoints
│   ├── settlement_service.dart          ← Settlement endpoints
│   ├── expense_service.dart             ← Expense endpoints
│   ├── advance_service.dart             ← Advance endpoints
│   ├── category_service.dart            ← Category endpoints
│   ├── report_service.dart              ← Report endpoints
│   └── api_service.dart                 ← Re-export semua (backward compatible)
```

**Alasan:**
- ⚠️ **Opsional**: Kalau tidak ada masalah, biarkan saja
- ✅ **Lebih maintainable**: Kalau ada perubahan endpoint, langsung ke file yang relevan

---

#### 4. `backend/routes/advances.py` - 847 baris 🟡

**Masalah:** Terlalu banyak logic (CRUD + revision system + checklist + settlement creation).

**Rekomendasi: Opsional - Pisahkan helpers**

```
backend/routes/
├── advances/                            ← BARU: Folder
│   ├── __init__.py
│   ├── routes.py                        ← API endpoints saja (~300 baris)
│   ├── revision_manager.py              ← Revision logic (~300 baris)
│   └── settlement_converter.py          ← Convert to settlement (~250 baris)
```

**Alasan:**
- ⚠️ **Opsional**: Kalau masih readable, tidak perlu dibagi
- ✅ **Lebih jelas**: Revision system logic terpisah dari routes

---

### ❌ TIDAK - File yang Cukup Besar Tapi Tidak Perlu Dibagi

| File | Baris | Alasan Tidak Perlu Dibagi |
|------|-------|---------------------------|
| `backend/models.py` | 627 | Semua models saling terkait, susah dipisah |
| `backend/app.py` | 880 | Sudah rapi dengan factory pattern |
| `backend/routes/reports/summary.py` | 580 | Masih di bawah 1000 baris |
| `backend/routes/reports/helpers.py` | 580 | Helper functions - memang 1 file |

---

## 📋 Ringkasan: File yang Harus Dibagi

| File | Baris | Prioritas | Bagi Jadi |
|------|-------|-----------|-----------|
| `backend/routes/reports/annual.py` | 2,461 | 🔴 TINGGI | 3 files (routes, excel, pdf) |
| `frontend/lib/screens/dashboard_screen.dart` | 1,758 | 🔴 TINGGI | 4-5 widgets |
| `frontend/lib/services/api_service.dart` | 1,262 | 🟡 SEDANG | 6-8 service files (opsional) |
| `backend/routes/advances.py` | 847 | 🟡 SEDANG | 3 files (opsional) |

---

## 🚀 Langkah Eksekusi

### Fase 1: Bersihkan File Sampah (15 menit)
```bash
# Frontend
cd frontend
rm change_icon.bat
rm repair.py
rm analyze_output.txt
rm lib/screens/settings_screen_backup.dart
mv test_fetch.dart test/

# Backend
cd backend
rm debug_titles.py
rm fix_existing_titles.py
rm fix_remark.py
rm fix_remark_database.sql
rm test_api_revenue_type.py
rm test_revenue_type.py
rm migrate_add_last_login.py
rm migrate_add_revenue_type.py
rm migrate_add_revenue_type_simple.py
rm migrate_evidence.py
rm migrate_sort_order.py
rm migrate_sort_order_simple.py
rm -r scripts/
rm -r _archive/
rm app.db
rm database_import_dividen.db
rm ewi.db
rm routes/reports/CODE_ANALYSIS_REPORT.md
rm -r routes/reports/backup/
```

### Fase 2: Buat Folder Baru & Pindahkan (10 menit)
```bash
# Backend
mkdir -p backend/data/exports
mkdir -p backend/tools/migrations
mv backend/database.db backend/data/
mv backend/exports/* backend/data/exports/
mv backend/migrate.py backend/tools/
mv backend/migrations/* backend/tools/migrations/

# Frontend
mkdir -p frontend/lib/screens/settings
mkdir -p frontend/lib/screens/report
mkdir -p frontend/lib/screens/management
mkdir -p frontend/lib/screens/auth
```

### Fase 3: Bagi File Besar (Opsional - 2-3 jam)
1. `annual.py` → 3 files
2. `dashboard_screen.dart` → 4-5 widgets
3. `api_service.dart` → service files (opsional)
4. `advances.py` → 3 files (opsional)

---

## ✅ Checklist Setelah Restrukturisasi

- [ ] Semua file sampah dihapus
- [ ] Database di folder `data/`
- [ ] Migration tools di folder `tools/`
- [ ] Screens sudah dikelompokkan
- [ ] File besar sudah dibagi (opsional)
- [ ] `.gitignore` sudah update (exclude `venv/`, `.dart_tool/`, `build/`)
- [ ] Semua import paths sudah diupdate
- [ ] Aplikasi masih bisa run (frontend & backend)
- [ ] Tests masih passing

---

## 📝 Catatan Penting

1. **Jangan ubah kode saat restrukturisasi** - hanya pindah file
2. **Commit setiap fase** - jangan gabungkan semua perubahan jadi 1 commit
3. **Test setelah setiap fase** - pastikan aplikasi masih jalan
4. **Backup sebelum mulai** - buat branch baru di git
5. **Update import paths** - setiap file dipindah, update semua import-nya

---

**Dibuat oleh:** Qwen Code AI Assistant  
**Status:** Menunggu approval untuk eksekusi
