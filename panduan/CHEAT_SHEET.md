# CHEAT SHEET - File yang Perlu Diubah

**Referensi cepat** - Print atau bookmark halaman ini!

---

## 🎯 MODIFIKASI CEPAT

| Mau Ubah Apa? | Backend (Python) | Frontend (Dart) |
|---------------|------------------|-----------------|
| **Database Schema** | `models.py` + migrations | `api_service.dart` + providers |
| **API Endpoint** | `routes/*.py` | `api_service.dart` |
| **UI Screen** | - | `screens/*.dart` |
| **State Management** | - | `providers/*.dart` |
| **Workflow Logic** | `routes/*.py` | `providers/*.dart` |
| **Report Export** | `routes/reports/*.py` | `report_screen.dart` |
| **Config** | `config.py`, `.env` | `api_service.dart` |

---

## 📁 FILE INTI PER MODUL

### Settlement
```
Backend:  models.py, routes/settlements.py
Frontend: settlement_provider.dart, settlement_detail_screen.dart
```

### Kasbon/Advance
```
Backend:  models.py, routes/advances.py
Frontend: advance_provider.dart, advance_detail_screen.dart
```

### Expense
```
Backend:  models.py, routes/expenses.py
Frontend: settlement_provider.dart, settlement_detail_screen.dart
```

### Category
```
Backend:  models.py, routes/categories.py
Frontend: settlement_provider.dart, category_management_screen.dart
```

### Revenue
```
Backend:  models.py, routes/revenues.py
Frontend: revenue_provider.dart, revenue_management_screen.dart
```

### Tax
```
Backend:  models.py, routes/taxes.py
Frontend: tax_provider.dart, tax_management_screen.dart
```

### Dividend
```
Backend:  models.py, routes/dividends.py
Frontend: dividend_provider.dart, dividend_management_screen.dart
```

### Dashboard
```
Backend:  routes/dashboard.py
Frontend: dashboard_provider.dart, dashboard_screen.dart
```

### Notification
```
Backend:  models.py, routes/notifications.py
Frontend: notification_provider.dart, dashboard_screen.dart
```

### Report
```
Backend:  routes/reports/*.py
Frontend: report_screen.dart, annual_report_screen.dart
```

---

## 🔄 WORKFLOW FILES

### Create → Submit → Approve → Complete

**Settlement:**
```
Backend:  routes/settlements.py
  - create_settlement()
  - submit_settlement()
  - approve_settlement()
  - complete_settlement()

Frontend: settlement_provider.dart
  - createSettlement()
  - submitSettlement()
  - approveSettlement()
  - completeSettlement()
```

**Advance:**
```
Backend:  routes/advances.py
  - create_advance()
  - submit_advance()
  - approve_advance()
  - start_revision()

Frontend: advance_provider.dart
  - createAdvance()
  - submitAdvance()
  - approveAdvance()
  - startRevision()
```

---

## 🗄️ DATABASE CHANGES

### Tambah Kolom Baru
```
1. backend/models.py          → Tambah kolom di class
2. flask db migrate -m "pesan" → Buat migration
3. flask db upgrade           → Apply migration
4. api_service.dart           → Update model
5. providers/*.dart           → Update state
6. screens/*.dart             → Update UI
```

### Tambah Tabel Baru
```
1. backend/models.py          → Buat class baru
2. flask db migrate -m "pesan" → Buat migration
3. flask db upgrade           → Apply migration
4. backend/routes/newtable.py → Buat endpoint
5. backend/app.py             → Register blueprint
6. frontend: ulangi langkah 4-6 untuk Dart
```

---

## 🎨 UI CHANGES

### Ubah Tampilan Screen
```
1. screens/[screen_name].dart → Main UI
2. providers/[name]_provider.dart → Data fetching
3. widgets/[name]_widgets.dart → Reusable components
```

### Tambah Menu Sidebar
```
1. screens/widgets/sidebar.dart → Tambah menu item
2. providers/auth_provider.dart → Update role check (jika perlu)
3. screens/[new_screen].dart → Buat screen baru
```

### Tambah Theme Color
```
1. theme/app_theme.dart → Tambah color di darkTheme & lightTheme
2. screens/*.dart → Pakai color baru
```

---

## 📊 REPORT CHANGES

### Ubah Excel Export
```
1. routes/reports/summary.py  → Summary Excel
2. routes/reports/annual.py   → Annual Excel
3. routes/reports/helpers.py  → Helper functions
4. excel/                     → Template files
```

### Ubah PDF Export
```
1. routes/reports/summary.py  → Summary PDF
2. routes/reports/annual.py   → Annual PDF
3. ReportLab code di functions
```

---

## ⚙️ CONFIG CHANGES

### Backend Config
```
backend/config.py:
  - SECRET_KEY
  - SQLALCHEMY_DATABASE_URI
  - JWT_SECRET_KEY
  - UPLOAD_FOLDER
  - EXPORT_FOLDER
  - ALLOWED_EXTENSIONS
  - MAX_CONTENT_LENGTH
```

### Frontend Config
```
frontend/lib/services/api_service.dart:
  - baseUrl (localhost/Cloudflare)
  - timeout duration
  - token handling
```

---

## 🔍 QUICK FIXES

### Error: "Table doesn't exist"
```bash
cd backend
flask db upgrade
```

### Error: "Settlement data tidak muncul otomatis"
```
✅ SUDAH DI-FIX (22 Mar 2026)
- Auto-load settlements ditambahkan di initState()
- Filter tahun sekarang cek Expense.date OR Settlement.created_at
- Lihat: panduan/FIX_SETTLEMENT_AUTO_LOAD.md untuk detail
```

### Error: "Filter tahun tidak menampilkan data"
```
✅ SUDAH DI-FIX (22 Mar 2026)
- Backend filter sekarang lebih permissive
- Settlement muncul jika expense.date ATAU created_at match tahun
```

### Error: "Module not found" (Python)
```bash
cd backend
venv\Scripts\activate
pip install -r requirements.txt
```

### Error: "Package not found" (Flutter)
```bash
cd frontend
flutter pub get
```

### Error: "Port 5000 already in use"
```bash
# Windows
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Change port in config.py
```

### Cache Annual Report Stale
```bash
# Delete cache files
rm -rf backend/exports/annual_cache/*

# Or access with refresh param
GET /api/reports/annual?refresh=true
```

---

## 🧪 TESTING CHECKLIST

### After Backend Changes
```
[ ] python app.py runs without error
[ ] Endpoint accessible via browser/Postman
[ ] Role-based access works
[ ] Export functions work
[ ] Migrations applied
```

### After Frontend Changes
```
[ ] flutter analyze - no errors
[ ] flutter pub get - success
[ ] App runs without crash
[ ] UI displays correctly
[ ] Theme light/dark works
```

### After Integration Changes
```
[ ] End-to-end flow works
[ ] Notifications appear
[ ] Search/filter works
[ ] Export generates correctly
[ ] Data persists after restart
```

---

## 📞 EMERGENCY CONTACTS

### Backup Database
```bash
cp backend/database.db backend/database_backup_$(date +%Y%m%d).db
```

### Restore from Backup
```bash
cp backend/database_backup_YYYYMMDD.db backend/database.db
```

### Reset Migrations
```bash
cd backend
rm -rf migrations/versions/*
flask db init
flask db migrate
flask db upgrade
```

### Reinstall Dependencies
```bash
# Backend
cd backend
pip install -r requirements.txt --force-reinstall

# Frontend
cd frontend
flutter clean
flutter pub get
```

---

## 📚 FULL DOCUMENTATION

- [PANDUAN_MODIFIKASI_KODE.md](panduan/PANDUAN_MODIFIKASI_KODE.md) - Panduan lengkap
- [DOKUMENTASI_UTAMA.md](../DOKUMENTASI_UTAMA.md) - Master documentation
- [CATATAN_PROYEK_KPI_EWI.md](../CATATAN_PROYEK_KPI_EWI.md) - Project notes

---

**Last Updated:** 22 Maret 2026
