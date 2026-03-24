# FIX: Settlement Data Tidak Muncul Otomatis

**Tanggal:** 22 Maret 2026  
**Issue:** Data settlement tidak muncul saat pertama kali masuk halaman, harus klik filter dulu baru muncul

---

## 🐛 Masalah yang Ditemukan

### 1. Data Tidak Auto-Load saat Masuk Halaman Settlement
**Symptom:** Saat pertama kali masuk ke halaman Settlement, data kosong. Harus klik filter (Semua/Draft/etc) atau ganti tahun baru data muncul.

**Root Cause:** 
- `SettlementProvider.loadSettlements()` tidak dipanggil saat pertama kali masuk halaman
- Hanya `loadCategories()` yang dipanggil di `initState()`

### 2. Filter Tahun Tidak Menampilkan Data 2024
**Symptom:** Saat pilih tahun 2024, data tidak muncul meskipun ada settlement di tahun 2024

**Root Cause:**
- Backend filter hanya cek `Expense.date` untuk menentukan tahun
- Settlement yang dibuat di tahun 2024 tapi expense-nya di tahun 2025 tidak muncul
- Settlement tanpa expense juga tidak muncul

---

## ✅ Solusi yang Diterapkan

### 1. Auto-Load Settlements di Dashboard

**File:** `frontend/lib/screens/dashboard_screen.dart`

**Perubahan:**
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    if (mounted) {
      context.read<SettlementProvider>().loadCategories();
      context.read<SettlementProvider>().loadSettlements(); // ← ADDED: Auto-load settlements
      context.read<NotificationProvider>().startPolling();
      _fetchBadgeCounts();
      _setupNotificationListener();
    }
  });
}
```

**Hasil:** Settlements langsung di-load saat pertama kali masuk halaman

---

### 2. Fix Filter Tahun di Backend

**File:** `backend/routes/settlements.py`

**Perubahan:**
```python
# BEFORE (hanya cek Expense.date):
if report_year is not None:
    query = query.join(
        Expense,
        Expense.settlement_id == Settlement.id,
    ).filter(
        db.extract('year', Expense.date) == report_year,
    ).distinct()

# AFTER (cek Expense.date ATAU Settlement.created_at):
if report_year is not None and report_year != 0:
    expense_match = db.exists().where(
        db.and_(
            Expense.settlement_id == Settlement.id,
            db.extract('year', Expense.date) == report_year,
        )
    )
    settlement_year_match = db.extract('year', Settlement.created_at) == report_year
    
    query = query.filter(
        db.or_(expense_match, settlement_year_match)
    ).distinct()
```

**Hasil:** 
- Settlement muncul jika Expense.date match tahun
- Settlement muncul jika Settlement.created_at match tahun
- Settlement tanpa expense tetap muncul selama created_at match tahun

---

### 3. Added Debug Logging

**Frontend:** `frontend/lib/providers/settlement_provider.dart`
```python
debugPrint('LOAD_SETTLEMENTS: status=$status, reportYear=$reportYear, search=$search');
debugPrint('SETTLEMENTS_LOADED: ${_settlements.length} items');
```

**Backend:** `backend/routes/settlements.py`
```python
print(f'[SETTLEMENT_API] user_id={user_id}, role={user.role}, status={status_filter}, report_year={report_year}, search={search_query}')
print(f'[SETTLEMENT_API] Filtering by year={report_year}')
print(f'[SETTLEMENT_API] Result: {len(ordered)} settlements loaded')
```

**Hasil:** Lebih mudah debug masalah filter/data di masa depan

---

## 🧪 Testing Checklist

### Test 1: Auto-Load Settlements
- [ ] Login ke aplikasi
- [ ] Masuk ke halaman Settlement
- [ ] **Expected:** Data langsung muncul tanpa perlu klik filter
- [ ] **Expected:** Summary cards (Pengeluaran Bulan Ini) muncul

### Test 2: Filter Tahun 2024
- [ ] Pilih filter tahun "Laporan 2024"
- [ ] **Expected:** Settlement di tahun 2024 muncul
- [ ] **Expected:** Settlement tanpa expense tapi dibuat di 2024 muncul
- [ ] **Expected:** Settlement dengan expense di tahun berbeda tetap muncul jika created_at di 2024

### Test 3: Filter Status
- [ ] Klik filter "Draft"
- [ ] **Expected:** Hanya settlement draft yang muncul
- [ ] Klik filter "Semua"
- [ ] **Expected:** Semua settlement muncul lagi

### Test 4: Search
- [ ] Ketik keyword di search bar
- [ ] **Expected:** Settlement filter by title/description
- [ ] Clear search
- [ ] **Expected:** Semua settlement muncul lagi

### Test 5: Console Logs
- [ ] Buka terminal backend
- [ ] Refresh halaman settlement
- [ ] **Expected:** Muncul log `[SETTLEMENT_API] user_id=..., role=..., status=..., report_year=...`
- [ ] **Expected:** Muncul log `[SETTLEMENT_API] Result: X settlements loaded`
- [ ] Buka console Flutter (flutter run)
- [ ] **Expected:** Muncul log `LOAD_SETTLEMENTS: status=..., reportYear=...`
- [ ] **Expected:** Muncul log `SETTLEMENTS_LOADED: X items`

---

## 📁 File yang Diubah

| File | Perubahan |
|------|-----------|
| `frontend/lib/screens/dashboard_screen.dart` | Added `loadSettlements()` di `initState()` |
| `frontend/lib/providers/settlement_provider.dart` | Added debug logging |
| `backend/routes/settlements.py` | Fixed year filter logic, added debug logging |

---

## 🔧 Cara Verifikasi Manual

### Via Backend Logs:
```bash
# Jalankan backend
cd backend
venv\Scripts\activate
python app.py

# Lihat console output saat buka halaman Settlement
# Harus muncul:
# [SETTLEMENT_API] user_id=1, role=manager, status=None, report_year=2026, search=
# [SETTLEMENT_API] Result: X settlements loaded
```

### Via Flutter Logs:
```bash
# Jalankan Flutter
cd frontend
flutter run

# Lihat console output saat buka halaman Settlement
# Harus muncul:
# LOAD_SETTLEMENTS: status=null, reportYear=2026, search=null
# SETTLEMENTS_LOADED: X items
```

---

## 🎯 Expected Behavior Setelah Fix

1. **Saat pertama masuk halaman Settlement:**
   - Data langsung muncul (tidak perlu klik filter)
   - Summary cards muncul
   - Badge counts muncul

2. **Saat ganti filter tahun:**
   - Data update sesuai tahun yang dipilih
   - Tahun 2024 menampilkan settlement dari 2024 (baik dari expense.date atau settlement.created_at)

3. **Saat ganti filter status:**
   - Data update sesuai status yang dipilih
   - "Semua" menampilkan semua settlement

4. **Saat search:**
   - Data filter by title/description
   - Clear search menampilkan semua data lagi

---

## 📝 Notes

- Filter tahun sekarang lebih permissive: settlement muncul jika **expense.date** ATAU **created_at** match tahun
- Ini intentional agar settlement tidak "hilang" hanya karena expense tanggalnya beda tahun
- Default report year sekarang di-set dari backend settings (biasanya 2024) tapi bisa diubah di Settings screen
- Debug logs bisa di-remove nanti kalau sudah stabil, atau di-keep untuk troubleshooting future issues

---

## 🚀 Rollback Plan

Jika ada masalah, rollback ke kondisi sebelumnya:

**Frontend:**
```dart
// Remove line dari dashboard_screen.dart
context.read<SettlementProvider>().loadSettlements(); // ← Remove this line
```

**Backend:**
```python
# Kembalikan ke logic lama di settlements.py
if report_year is not None:
    query = query.join(Expense).filter(
        db.extract('year', Expense.date) == report_year,
    ).distinct()
```

---

**Status:** ✅ Fixed  
**Tested:** ⏳ Pending user confirmation
