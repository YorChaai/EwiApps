# 📋 PLAN LENGKAP - Fix Kategori Dinamis Laporan Tahunan

**Tanggal:** 29 Maret 2026  
**Status:** ✅ **SIAP IMPLEMENTASI**

---

## 📊 **RINGKASAN MASALAH:**

### **Masalah 1: Frontend - Kategori Tidak Dinamis** ✅ **SUDAH DIPERBAIKI**

**File:** `frontend/lib/screens/annual_report_screen.dart`

**Masalah:**
- Kategori header hardcoded (9 kategori lama saja)
- Kategori baru tidak muncul otomatis
- Urutan tidak mengikuti Kategori Tabular

**Status:** ✅ **SUDAH DIPERBAIKI**
- Fetch kategori dari API dengan response format yang benar
- Gunakan kategori dinamis untuk header tabel
- Urutan sesuai `sort_order` dari database

---

### **Masalah 2: Backend Excel - Header Kategori Baru Tidak Hijau** ❌ **BELUM DIPERBAIKI**

**File:** `backend/routes/reports/annual.py`

**Fungsi:** `_write_dynamic_category_headers()` (Line ~75-95)

**Masalah:**
- 9 kategori lama = header hijau ✅
- Kategori baru = header putih polos ❌
- Terlihat seperti 2 tabel terpisah

**Screenshot:**
```
┌────────────────────────────────────────────┐ ┌──────────────────────┐
│ 9 KATEGORI LAMA                            │ │ KATEGORI BARU        │
│ ✅ Header hijau                            │ │ ❌ Header putih      │
│ Biaya Research | Biaya Operasi | ...      │ │ makanan jepang | ... │
└────────────────────────────────────────────┘ └──────────────────────┘
```

**Yang Diinginkan:**
```
┌────────────────────────────────────────────────────────────────────┐
│ SEMUA KATEGORI (LAMA + BARU)                                      │
│ ✅ SEMUA header hijau                                             │
│ Biaya Research | Biaya Operasi | ... | makanan jepang | aaaaa | ...│
└────────────────────────────────────────────────────────────────────┘
```

---

### **Masalah 3: Backend Excel - Column Width Tidak Uniform** ❌ **BELUM DIPERBAIKI**

**File:** `backend/routes/reports/annual.py`

**Fungsi:** `get_annual_report_excel()` (Line ~1180-1190)

**Masalah:**
- Kategori lama = column width lebar (auto-fit)
- Kategori baru = column width sangat sempit (text vertikal)
- Tidak konsisten

**Yang Diinginkan:**
- SEMUA kolom kategori = lebar sama (uniform)
- Tidak peduli panjang text nama kategori

---

## 🔧 **PLAN PERBAIKAN:**

### **Step 1: Fix Header Warna Hijau untuk Semua Kategori**

**File:** `backend/routes/reports/annual.py`

**Fungsi:** `_write_dynamic_category_headers()`

**Kode Sekarang (Line ~75-95):**
```python
def _write_dynamic_category_headers(ws, root_cats, header_row=40, start_col=9, template_end_col=17):
    last_used_col = max(template_end_col, start_col + len(root_cats) - 1)
    for col in range(start_col, last_used_col + 1):
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        if col >= start_col + len(root_cats):
            cell.value = None

    for offset, category in enumerate(root_cats):
        col = start_col + offset
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        cell.value = category.name
        # ❌ BUG: Hanya copy format dari template, kategori baru tidak dapat format
        alignment = copy(cell.alignment)
        alignment.wrap_text = True
        alignment.horizontal = 'center'
        alignment.vertical = 'center'
        cell.alignment = alignment
        # ❌ TIDAK SET GREEN FILL COLOR
```

**Kode Setelah Fix:**
```python
from openpyxl.styles import PatternFill, Font, Alignment

# Define green fill style (same as template)
GREEN_FILL = PatternFill(fill_type='solid', fgColor='C6EFCE')  # Light green
GREEN_FONT = Font(bold=True, color='006100', size=10)  # Dark green text

def _write_dynamic_category_headers(ws, root_cats, header_row=40, start_col=9, template_end_col=17):
    last_used_col = max(template_end_col, start_col + len(root_cats) - 1)
    for col in range(start_col, last_used_col + 1):
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        if col >= start_col + len(root_cats):
            cell.value = None

    for offset, category in enumerate(root_cats):
        col = start_col + offset
        cell = ws.cell(row=header_row, column=col)
        if isinstance(cell, MergedCell):
            continue
        cell.value = category.name
        
        # ✅ FORCE APPLY GREEN FORMAT TO ALL CATEGORIES (OLD + NEW)
        cell.fill = GREEN_FILL
        cell.font = GREEN_FONT
        
        alignment = Alignment(wrap_text=True, horizontal='center', vertical='center')
        cell.alignment = alignment
```

**Perubahan:**
- ✅ Import `PatternFill`, `Font`, `Alignment` dari `openpyxl.styles`
- ✅ Define constant `GREEN_FILL` dan `GREEN_FONT`
- ✅ Apply green fill ke SEMUA kategori (tidak bergantung template)

---

### **Step 2: Fix Column Width Uniform untuk Semua Kategori**

**File:** `backend/routes/reports/annual.py`

**Fungsi:** `get_annual_report_excel()`

**Lokasi:** Setelah line ~1188 (setelah `_write_dynamic_category_headers()`)

**Kode Sekarang:**
```python
# Fetch root categories dynamically from DB - ORDER BY sort_order
root_cats = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
cat_columns = [c.name for c in root_cats]
cat_names = cat_columns
category_by_id_map = {c.id: c for c in root_cats}
_write_dynamic_category_headers(ws, root_cats)
# ❌ TIDAK SET COLUMN WIDTH
```

**Kode Setelah Fix:**
```python
from openpyxl.utils import get_column_letter

# ... existing code ...

# Fetch root categories dynamically from DB - ORDER BY sort_order
root_cats = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
cat_columns = [c.name for c in root_cats]
cat_names = cat_columns
category_by_id_map = {c.id: c for c in root_cats}
_write_dynamic_category_headers(ws, root_cats)

# ✅ SET UNIFORM COLUMN WIDTH FOR ALL CATEGORIES
UNIFORM_CATEGORY_WIDTH = 18  # Adjust as needed
for offset in range(len(root_cats)):
    col = start_col + offset  # start_col = 9
    col_letter = get_column_letter(col)
    ws.column_dimensions[col_letter].width = UNIFORM_CATEGORY_WIDTH
```

**Perubahan:**
- ✅ Import `get_column_letter` dari `openpyxl.utils`
- ✅ Define constant `UNIFORM_CATEGORY_WIDTH = 18`
- ✅ Loop semua kategori dan set width yang sama

---

## 📝 **FILE YANG DIUBAH:**

| File | Line | Perubahan | Status |
|------|------|-----------|--------|
| `backend/routes/reports/annual.py` | ~1-20 | Import `PatternFill`, `Font`, `Alignment`, `get_column_letter` | ❌ TODO |
| `backend/routes/reports/annual.py` | ~75-95 | Fix `_write_dynamic_category_headers()` - apply green | ❌ TODO |
| `backend/routes/reports/annual.py` | ~1180-1190 | Fix `get_annual_report_excel()` - set uniform width | ❌ TODO |
| `frontend/lib/screens/annual_report_screen.dart` | ~20-68 | Fetch kategori dinamis | ✅ DONE |
| `frontend/lib/screens/annual_report_screen.dart` | ~414-430 | Fungsi `_getCategoryIndexFromDynamic()` | ✅ DONE |
| `frontend/lib/screens/annual_report_screen.dart` | ~812-828 | Dynamic `catHeaders` | ✅ DONE |

---

## 🧪 **TESTING PLAN:**

### **Test 1: Download Excel - Header Hijau**

**Langkah:**
1. Buka Laporan Tahunan
2. Download Excel
3. Buka file Excel

**Expected:**
- ✅ SEMUA header kategori hijau (9 lama + semua baru)
- ✅ Tidak ada header putih

**Jika GAGAL:**
- ❌ Beberapa header masih putih = `GREEN_FILL` tidak di-apply

---

### **Test 2: Download Excel - Column Width Uniform**

**Langkah:**
1. Buka Laporan Tahunan
2. Download Excel
3. Buka file Excel
4. Cek lebar kolom kategori

**Expected:**
- ✅ SEMUA kolom kategori lebar sama (18)
- ✅ Text tidak vertikal/sangat sempit

**Jika GAGAL:**
- ❌ Kolom baru masih sempit = width tidak di-set

---

### **Test 3: Kategori Baru Muncul**

**Langkah:**
1. Buat kategori baru di Kategori Tabular
2. Download Excel Laporan Tahunan
3. Buka file Excel

**Expected:**
- ✅ Kategori baru muncul di tabel
- ✅ Header hijau
- ✅ Column width sama dengan yang lain

---

### **Test 4: Frontend - Kategori Dinamis**

**Langkah:**
1. Buka Laporan Tahunan di aplikasi
2. Lihat Tabel 3

**Expected:**
- ✅ Kolom kategori sesuai Kategori Tabular
- ✅ Urutan sesuai `sort_order`

---

## ✅ **CHECKLIST IMPLEMENTASI:**

### **Backend (annual.py):**

- [ ] Import `PatternFill`, `Font`, `Alignment` dari `openpyxl.styles`
- [ ] Import `get_column_letter` dari `openpyxl.utils`
- [ ] Define `GREEN_FILL = PatternFill(fill_type='solid', fgColor='C6EFCE')`
- [ ] Define `GREEN_FONT = Font(bold=True, color='006100', size=10)`
- [ ] Define `UNIFORM_CATEGORY_WIDTH = 18`
- [ ] Update `_write_dynamic_category_headers()` - apply green ke semua
- [ ] Update `get_annual_report_excel()` - set uniform width
- [ ] Test download Excel
- [ ] Verify semua header hijau
- [ ] Verify semua kolom lebar sama

### **Frontend (annual_report_screen.dart):**

- [x] Fetch kategori dari API
- [x] Gunakan dynamic `catHeaders`
- [x] Gunakan `_getCategoryIndexFromDynamic()`
- [x] Test frontend display

---

## 🎯 **HASIL AKHIR:**

| Aspek | Sebelum | Setelah |
|-------|---------|---------|
| **Frontend** | | |
| Kategori header | Hardcoded 9 | ✅ Dinamis semua |
| Kategori baru | ❌ Tidak muncul | ✅ Muncul otomatis |
| Urutan | ❌ Tidak sesuai | ✅ Sesuai sort_order |
| **Backend Excel** | | |
| Header lama | ✅ Hijau | ✅ Hijau |
| Header baru | ❌ Putih | ✅ Hijau |
| Column width lama | Variatif | ✅ Uniform (18) |
| Column width baru | ❌ Sempit | ✅ Uniform (18) |
| Tampilan | ❌ Terpisah 2 tabel | ✅ Menyatu 1 tabel |

---

## ⚠️ **CATATAN PENTING:**

1. **JANGAN UBAH:**
   - Logic fetch kategori dari database (sudah benar)
   - Logic mapping expense ke kategori (sudah benar)
   - Frontend Excel download button (sudah benar)
   - PDF export (tidak disentuh)

2. **HANYA UBAH:**
   - Format header (apply green ke semua)
   - Column width (set uniform)

3. **BACKWARD COMPATIBLE:**
   - Kategori lama tetap muncul
   - Kategori baru otomatis muncul
   - Urutan sesuai Kategori Tabular

---

## 📄 **DOKUMENTASI TERKAIT:**

| File | Deskripsi |
|------|-----------|
| `VERIFIKASI_PERUBAHAN_KODE.md` | Verifikasi perubahan sebelumnya |
| `TESTING_KATEGORI_DINAMIS.md` | Plan testing frontend |
| `panduan/KATEGORI_TABULAR.md` | Dokumentasi Kategori Tabular |

---

**Status:** ✅ **PLAN COMPLETE - SIAP IMPLEMENTASI**

**Next Step:** Implementasi backend fix (Step 1 & Step 2)

---

**Dibuat oleh:** AI Assistant  
**Untuk:** MiniProjectKPI_EWI - Fix Kategori Dinamis Laporan Tahunan  
**Review:** Menunggu konfirmasi user sebelum implementasi
