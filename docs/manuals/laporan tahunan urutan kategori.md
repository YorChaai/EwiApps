📋 PLAN IMPLEMENTASI: KATEGORI TABULAR

##  Latar Belakang Masalah

###  Kondisi Saat Ini
| Fitur | Status | Keterangan |
|-------|--------|------------|
| Download Excel Laporan | ✅ Ada | 3 sheet: Revenue, Cost, Summary |
| Sheet Revenue - Tabel 3 | ✅ Ada | Data Pengeluaran per Kategori |
| Urutan Kategori di Excel | ❌ **Masalah** | Masih acak, tidak terurut |
| Sub Kategori di Excel | ❌ **Masalah** | Tidak urut A-Z (harusnya A→Z) |
| Atur Urutan Kategori | ❌ **Belum Ada** | User tidak bisa custom order |

---

##  Solusi yang Diusulkan

###  1. Kategori Tabular (New Feature)
- Halaman khusus untuk mengatur urutan **kategori utama**
- Hanya kategori parent yang bisa di-urutkan
- Sub kategori otomatis urut A-Z (tidak bisa manual)
- Urutan disimpan permanen ke database

###  2. Excel Export Update
- Kolom **Kategori** dipindah jadi **kolom pertama** (setelah No)
- Baris pengeluaran diurutkan berdasarkan:
  1. Parent kategori: Manual order (sort_order)
  2. Sub kategori: Alphabetical (A-Z)

---

##  Implementasi (2 Fase)

###  FAZE 1: Kategori Tabular + Excel Parent Sort
**Goal:** User bisa atur urutan kategori utama, Excel ikuti urutan tersebut

###  FAZE 2: Sub Kategori Auto Sort A-Z
**Goal:** Sub kategori otomatis urut A-Z di Excel (fix bug batch settlement)

---

# 🔵 FAZE 1: KATEGORI TABULAR

##  1.1 Backend Tasks

| No | Task | File | Detail | Estimasi |
|----|------|------|--------|----------|
| 1.1.1 | Add `sort_order` column | `backend/models.py` | Tambah field di Category model | 15 min |
| 1.1.2 | Migration script | `backend/migrate_sort_order.py` | Isi default sort_order based on id | 20 min |
| 1.1.3 | Update Category.to_dict() | `backend/models.py` | Include sort_order in response | 5 min |
| 1.1.4 | API: GET categories | `backend/routes/categories.py` | Return categories with sort_order | 20 min |
| 1.1.5 | API: PUT reorder | `backend/routes/categories.py` | Bulk update sort_order | 30 min |
| 1.1.6 | Update Excel export | `backend/routes/reports.py` | Sort expenses by category.sort_order | 45 min |

**Total Backend: ~2 jam 15 menit**

---

##  1.2 Frontend Tasks

| No | Task | File | Detail | Estimasi |
|----|------|------|--------|----------|
| 1.2.1 | Create screen | `category_tabular_screen.dart` | New page for category ordering | 60 min |
| 1.2.2 | UI: Category list | `category_tabular_screen.dart` | Show numbered list (01, 02, 03...) | 30 min |
| 1.2.3 | Filter parent only | `category_tabular_screen.dart` | Hide sub categories from list | 15 min |
| 1.2.4 | UI: Checkbox select | `category_tabular_screen.dart` | Select category to move | 20 min |
| 1.2.5 | UI: UP/DOWN buttons | `category_tabular_screen.dart` | Move category position | 30 min |
| 1.2.6 | Logic: Swap position | `category_tabular_screen.dart` | Reorder list locally | 30 min |
| 1.2.7 | Logic: Save to API | `category_tabular_screen.dart` | Persist order to database | 20 min |
| 1.2.8 | Integrate to Laporan | `laporan_screen.dart` | Add button to main page | 15 min |
| 1.2.9 | Update API service | `api_service.dart` | Add reorderCategories() method | 15 min |

**Total Frontend: ~4 jam**

---

##  1.3 Testing Tasks

| No | Task | Detail | Estimasi |
|----|------|--------|----------|
| 1.3.1 | Test API endpoints | GET categories, PUT reorder | 20 min |
| 1.3.2 | Test UI flow | Select, up/down, save | 30 min |
| 1.3.3 | Test Excel export | Verify parent order matches UI | 30 min |
| 1.3.4 | Test persistence | Restart app, check order persists | 15 min |
| 1.3.5 | Test multi-user | Manager A changes, Manager B sees same | 15 min |

**Total Testing: ~1 jam 50 menit**

---

##  1.4 Deliverables (Faze 1)

###  Backend
- [ ] `backend/models.py` - Category with sort_order
- [ ] `backend/migrate_sort_order.py` - Migration script
- [ ] `backend/routes/categories.py` - GET + PUT endpoints
- [ ] `backend/routes/reports.py` - Excel export with sort

###  Frontend
- [ ] `frontend/lib/screens/category_tabular_screen.dart` - New page
- [ ] `frontend/lib/services/api_service.dart` - reorderCategories()
- [ ] `frontend/lib/screens/laporan_screen.dart` - Integration

###  Database
- [ ] `categories.sort_order` column added
- [ ] Default values populated

---

# 🔴 FAZE 2: SUB KATEGORI AUTO SORT A-Z

##  2.1 Problem Statement

**Current Behavior:**
```
Single Settlement Excel: ✅ BENAR
┌─────────────────────────┐
│ Makanan                 │ ← A
│   ├─ Ayam               │
│   ├─ Bakso              │
│   └─ Cimol              │
│ Transport               │
│   ├─ Angkot             │
│   └─ Bus                │
└─────────────────────────┘

Batch Settlement Excel: ❌ SALAH
┌─────────────────────────┐
│ Makanan                 │
│   ├─ Cimol              │ ← Z (should be A)
│   ├─ Ayam               │
│   └─ Bakso              │
│ Transport               │
│   ├─ Bus                │
│   └─ Angkot             │
└─────────────────────────┘
```

**Root Cause:** Batch settlement tidak ada sorting logic, urutan berdasarkan database INSERT order

---

##  2.2 Backend Tasks

| No | Task | File | Detail | Estimasi |
|----|------|------|--------|----------|
| 2.2.1 | Fix sorting logic | `backend/routes/reports.py` | Add sort: parent by sort_order, child by name ASC | 30 min |
| 2.2.2 | Test single settlement | Export Excel | Verify still works | 15 min |
| 2.2.3 | Test batch settlement | Export Excel | Verify sub kategori A-Z | 15 min |

**Total Backend: ~1 jam**

---

##  2.3 Code Implementation

###  File: `backend/routes/reports.py`

**Current Code (SALAH):**
```python
expenses = Expense.query.filter_by(settlement_id=settlement_id).all()
# No sorting → random order
```

**Fixed Code (BENAR):**
```python
expenses = Expense.query.filter_by(settlement_id=settlement_id).all()

def sort_key(expense):
    category = expense.category
    if category.parent:
        # Sub kategori: parent sort_order + child name A-Z
        return (category.parent.sort_order or 999, category.name.upper())
    else:
        # Parent kategori: sort_order only
        return (category.sort_order or 999, '')

expenses.sort(key=sort_key)
```

---

##  2.4 Testing Checklist

| Test Case | Expected Result | Status |
|-----------|-----------------|--------|
| Single settlement with sub kategori | Sub kategori urut A-Z | ⬜ |
| Batch settlement with sub kategori | Sub kategori urut A-Z | ⬜ |
| Parent kategori custom order | Excel ikuti sort_order | ⬜ |
| Mixed parent + sub | Parent by order, child by A-Z | ⬜ |

---

# 📊 TIMELINE SUMMARY

| Fase | Backend | Frontend | Testing | Total |
|------|---------|----------|---------|-------|
| **Faze 1** | 2j 15m | 4j | 1j 50m | **8j 5m** |
| **Faze 2** | 1j | - | - | **1j** |
| **GRAND TOTAL** | | | | **9j 5m** |

---

# 🎯 ACCEPTANCE CRITERIA

##  Faze 1 Must-Have

###  Backend
- [ ] `sort_order` column exists in `categories` table
- [ ] `GET /api/categories` returns sorted list
- [ ] `PUT /api/categories/reorder` accepts bulk update
- [ ] Excel export sorts by `category.sort_order`
- [ ] Kolom Kategori di Excel = kolom pertama (setelah No)

###  Frontend
- [ ] Button "Kategori Tabular" visible di Laporan Tahunan
- [ ] Halaman Kategori Tabular opens correctly
- [ ] Only parent categories shown (no sub categories)
- [ ] Numbered list displays (01, 02, 03...)
- [ ] Checkbox selection works
- [ ] UP/DOWN buttons enabled after selection
- [ ] UP/DOWN buttons move category correctly
- [ ] SIMPAN button saves to database
- [ ] Order persists after app restart
- [ ] Download Excel follows new order

###  Excel
- [ ] Sheet Revenue Tabel 3: Kategori = kolom #2
- [ ] Rows sorted by parent category order
- [ ] No data loss or corruption

---

##  Faze 2 Must-Have

###  Backend
- [ ] Single settlement: sub kategori A-Z ✅
- [ ] Batch settlement: sub kategori A-Z ✅
- [ ] Parent order preserved from Faze 1
- [ ] No regression in existing features

---

# 🚀 GETTING STARTED

##  Pre-requisites
1. Backup database sebelum migration
2. Backup Excel template original
3. Test environment ready

##  Step-by-Step Start

###  Day 1: Backend Faze 1
```bash
# 1. Add sort_order column
cd backend
python -c "from models import db, Category; db.create_all()"

# 2. Run migration
python migrate_sort_order.py

# 3. Test API
curl http://localhost:5000/api/categories
```

###  Day 2: Frontend Faze 1
```bash
# 1. Create new screen
cd frontend/lib/screens
flutter create category_tabular_screen.dart

# 2. Add button to laporan_screen.dart

# 3. Test UI flow
flutter run
```

###  Day 3: Testing + Faze 2
```bash
# 1. Test Faze 1 end-to-end

# 2. Fix sub kategori sorting (Faze 2)

# 3. Final regression test
```

---

# ⚠️ RISK & MITIGATION

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Database migration fails | High | Low | Backup before migrate |
| Excel template breaks | High | Medium | Keep original backup |
| Multi-manager conflict | Medium | Medium | Last-write-wins strategy |
| Performance issue (large data) | Low | Low | Add index on sort_order |

---

# ❓ CLARIFICATION NEEDED

Sebelum mulai coding, konfirmasi:

1. **Apakah plan ini sudah cukup jelas?**
2. **Apakah mau langsung mulai Faze 1 sekarang?**
3. **Ada deadline khusus untuk selesai?**

---

**Tunggu konfirmasi kamu sebelum saya mulai implement!** 🚀



test 

3. Test di Aplikasi

1. **Buka Flutter App**
2. **Navigate ke Laporan Tahunan**
3. **Tap button "Kategori Tabular"** di AppBar
4. **Pilih kategori** (tap checkbox)
5. **Tap ↑ atau ↓** untuk pindah posisi
6. **Tap "Simpan"** untuk save ke database

###  4. Download Excel

Saat download Excel Laporan Tahunan:
- ✅ Kolom **Kategori** akan jadi **kolom pertama** (setelah No)
- ✅ Baris pengeluaran sorted by **parent category sort_order**
- ✅ Sub kategori otomatis **A-Z** (akan di-fix di FAZE 2)