# FIX: Filter Settlement Tidak Konsisten

**Tanggal:** 22 Maret 2026  
**Issue:** 
1. Data 2024 muncul di filter tahun 2026 saat klik "Completed"
2. Filter tidak reset dengan benar setelah ganti status
3. Expense tidak semua muncul di settlement view

---

## 🐛 Root Cause yang Ditemukan

### Issue #1: Filter State Tidak Reset dengan Benar

**File:** `frontend/lib/providers/settlement_provider.dart`

**Masalah:**
```dart
// LOGIC LAMA - BUG!
if (status != null || (startDate == null && endDate == null && reportYear == null && search == null)) _statusFilter = status;
```

Logic ini menyebabkan:
- Saat klik "Semua" (status=null), `_statusFilter` tidak update karena kondisi kedua tidak terpenuhi
- Filter tahun yang lama tetap terpakai
- Data tidak reset dengan benar

**Solusi:**
```dart
// LOGIC BARU - FIX!
if (status != null) _statusFilter = status;
if (startDate != null) _startDate = startDate;
if (endDate != null) _endDate = endDate;
if (reportYear != null) _reportYear = reportYear;
if (search != null) _searchQuery = search;
```

Sekarang setiap filter **ALWAYS update** saat nilai eksplisit diberikan.

---

### Issue #2: Debug Logging untuk Track Backend Filter

**File:** `backend/routes/settlements.py`

**Masalah:** Tidak ada visibility filter mana yang benar-benar di-apply di backend.

**Solusi:** Tambah detail logging:
```python
print(f'[SETTLEMENT_API] ===== REQUEST =====')
print(f'[SETTLEMENT_API] status_filter={status_filter}')
print(f'[SETTLEMENT_API] report_year={report_year}')
print(f'[SETTLEMENT_API] Filtering status: approved OR completed')
print(f'[SETTLEMENT_API] Filtering year={report_year}')
print(f'[SETTLEMENT_API] ===== RESULT =====')
print(f'[SETTLEMENT_API] Total: {len(ordered)} settlements')
for s in ordered[:10]:
    print(f'[SETTLEMENT_API]   - ID={s.id}, title={s.title}, status={s.status}, year={s.created_at.year}')
```

---

## ✅ Perubahan yang Dibuat

### 1. Frontend - settlement_provider.dart

**File:** `frontend/lib/providers/settlement_provider.dart`

**Perubahan:**
```dart
// BEFORE (BUG):
if (status != null || (startDate == null && endDate == null && reportYear == null && search == null)) _statusFilter = status;

// AFTER (FIX):
if (status != null) _statusFilter = status;
if (startDate != null) _startDate = startDate;
if (endDate != null) _endDate = endDate;
if (reportYear != null) _reportYear = reportYear;
if (search != null) _searchQuery = search;
```

**Added logging:**
```dart
debugPrint('LOAD_SETTLEMENTS: status=$status, reportYear=$reportYear, search=$search, startDate=$startDate, endDate=$endDate');
debugPrint('SETTLEMENTS_LOADED: ${_settlements.length} items (status=$_statusFilter, year=$_reportYear)');
```

---

### 2. Backend - settlements.py

**File:** `backend/routes/settlements.py`

**Perubahan:** Added comprehensive logging:
```python
# Log request params
print(f'[SETTLEMENT_API] ===== REQUEST =====')
print(f'[SETTLEMENT_API] status_filter={status_filter}')
print(f'[SETTLEMENT_API] report_year={report_year}')

# Log each filter applied
if status_filter in ('approved', 'completed'):
    print(f'[SETTLEMENT_API] Filtering status: approved OR completed')
elif status_filter:
    print(f'[SETTLEMENT_API] Filtering status: {status_filter}')

if report_year is not None and report_year != 0:
    print(f'[SETTLEMENT_API] Filtering year={report_year}')
else:
    print(f'[SETTLEMENT_API] NO year filter (report_year={report_year})')

# Log results with year info
print(f'[SETTLEMENT_API] ===== RESULT =====')
print(f'[SETTLEMENT_API] Total: {len(ordered)} settlements')
for s in ordered[:10]:
    print(f'[SETTLEMENT_API]   - ID={s.id}, year={s.created_at.year if s.created_at else "?"}')
```

---

## 🧪 CARA TESTING

### Step 1: Restart Aplikasi

**Backend:**
```bash
cd backend
# Stop current server (Ctrl+C)
venv\Scripts\activate
python app.py
```

**Frontend:**
```bash
cd frontend
# Stop current app (quit)
flutter run
```

---

### Step 2: Test Filter Reset

1. **Buka halaman Settlement**
   - ✅ Data harus langsung muncul (auto-load)
   - ✅ Cek console Flutter: `LOAD_SETTLEMENTS: status=null, reportYear=2026`

2. **Klik filter "Completed"**
   - ✅ Cek backend log: `Filtering status: approved OR completed`
   - ✅ Data yang muncul = semua approved + completed

3. **Klik filter "Semua"**
   - ✅ Cek console Flutter: `LOAD_SETTLEMENTS: status=null, reportYear=2026`
   - ✅ Data harus reset ke semua settlement (tidak stuck di "Completed")

---

### Step 3: Test Filter Tahun

1. **Pilih "Laporan 2024"**
   - ✅ Cek backend log: `Filtering year=2024`
   - ✅ Cek backend log result: `year=2024` untuk semua data
   - ✅ **TIDAK BOLEH** ada data tahun 2026!

2. **Pilih "Laporan 2026"**
   - ✅ Cek backend log: `Filtering year=2026`
   - ✅ Cek backend log result: `year=2026` untuk semua data
   - ✅ **TIDAK BOLEH** ada data tahun 2024!

3. **Klik "Completed" saat filter 2026 aktif**
   - ✅ Cek backend log: `Filtering status: approved OR completed` + `Filtering year=2026`
   - ✅ Data yang muncul HANYA dari tahun 2026
   - ✅ **TIDAK BOLEH** ada data 2024 yang muncul!

---

### Step 4: Test Expense Muncul Semua

1. **Buka detail settlement** (klik salah satu settlement)
   - ✅ Semua expense di settlement tersebut harus muncul
   - ✅ Cek `expense_count` di response sesuai dengan jumlah expense yang tampil

2. **Bandingkan dengan Laporan Tahunan**
   - ✅ Buka Laporan → Laporan Tahunan → pilih tahun yang sama
   - ✅ Jumlah expense di settlement harus sama dengan di Laporan

---

## 📊 CONTOH LOG YANG BENAR

### Saat Pilih "Laporan 2026" + "Completed":

**Backend log:**
```
[SETTLEMENT_API] ===== REQUEST =====
[SETTLEMENT_API] user_id=1, role=manager
[SETTLEMENT_API] status_filter=completed
[SETTLEMENT_API] report_year=2026
[SETTLEMENT_API] search_query=
[SETTLEMENT_API] Filtering status: approved OR completed
[SETTLEMENT_API] Filtering year=2026 (Expense.date OR Settlement.created_at)
[SETTLEMENT_API] ===== RESULT =====
[SETTLEMENT_API] Total: 5 settlements
[SETTLEMENT_API]   - ID=10, title=Test A, status=approved, created_at=2026-03-15, year=2026
[SETTLEMENT_API]   - ID=11, title=Test B, status=completed, created_at=2026-03-16, year=2026
[SETTLEMENT_API]   - ID=12, title=Test C, status=approved, created_at=2026-03-17, year=2026
...
```

**Flutter log:**
```
LOAD_SETTLEMENTS: status=completed, reportYear=2026, search=null
SETTLEMENTS_LOADED: 5 items (status=completed, year=2026)
```

### Saat Pilih "Laporan 2024" (HARUS BERBEDA!):

**Backend log:**
```
[SETTLEMENT_API] ===== REQUEST =====
[SETTLEMENT_API] status_filter=null
[SETTLEMENT_API] report_year=2024
[SETTLEMENT_API] Filtering year=2024 (Expense.date OR Settlement.created_at)
[SETTLEMENT_API] ===== RESULT =====
[SETTLEMENT_API] Total: 3 settlements
[SETTLEMENT_API]   - ID=5, title=Test X, status=approved, created_at=2024-05-10, year=2024
[SETTLEMENT_API]   - ID=6, title=Test Y, status=completed, created_at=2024-06-15, year=2024
...
```

**TIDAK BOLEH ADA:**
```
[SETTLEMENT_API]   - ID=10, title=Test A, status=approved, created_at=2026-03-15, year=2026  ❌
```

---

## 🎯 EXPECTED BEHAVIOR SETELAH FIX

1. **Filter "Semua"** → Reset semua filter, tampilkan semua settlement
2. **Filter "Completed"** → Tampilkan approved + completed, **TAPI** tetap respect year filter
3. **Filter "Draft/Submitted/etc"** → Tampilkan hanya status tersebut, respect year filter
4. **Filter "Laporan 2024"** → HANYA data tahun 2024, tidak peduli status apa
5. **Filter "Laporan 2026"** → HANYA data tahun 2026, tidak peduli status apa
6. **Expense di detail settlement** → Harus muncul semua, sama dengan di Laporan

---

##  CHECKLIST HASIL TESTING

Tolong screenshot atau copy-paste log saat testing:

### Backend Log (Terminal):
```
[SETTLEMENT_API] ===== REQUEST =====
[SETTLEMENT_API] status_filter=???
[SETTLEMENT_API] report_year=???
...
```

### Flutter Log (Console):
```
LOAD_SETTLEMENTS: status=???, reportYear=???
SETTLEMENTS_LOADED: X items
```

### Hasil yang Diharapkan:
- [ ] Filter "Semua" reset data dengan benar
- [ ] Filter "Completed" tidak bawa data tahun lain
- [ ] Filter "Laporan 2024" hanya tampilkan data 2024
- [ ] Filter "Laporan 2026" hanya tampilkan data 2026
- [ ] Expense muncul semua di detail settlement

---

## 🔧 TROUBLESHOOTING

### Jika data masih campur:
1. Cek backend log - apakah `report_year` benar?
2. Cek apakah ada log `Filtering year=2024` atau `Filtering year=2026`?
3. Cek result log - apakah `year=2024` atau `year=2026` untuk semua data?

### Jika expense tidak muncul semua:
1. Cek `expense_count` di response settlement
2. Cek di database: `SELECT * FROM expenses WHERE settlement_id = X`
3. Bandingkan dengan yang muncul di UI

### Jika filter "Semua" tidak reset:
1. Cek Flutter log - apakah `status=null`?
2. Cek apakah `_statusFilter` benar-benar di-set ke null?

---

**Status:** 🔧 Fixed - Pending User Testing  
**Files Changed:**
- `frontend/lib/providers/settlement_provider.dart`
- `backend/routes/settlements.py`
