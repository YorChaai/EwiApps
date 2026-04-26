# 🐛 BUG: KATEGORI COLUMN & SUB KATEGORI TIDAK SORT

**Created:** 26 Maret 2026  
**Severity:** 🔴 HIGH  
**Status:** ❌ NOT FIXED

---

## 📋 MASALAH

### 1. Excel Category Columns - Header Statis & Panjang ❌

**Current (WRONG):**
```
Column I: "Biaya Operasi (Gaji, Tunjangan Lapangan, Training, THR, Transport, Meal, Hotel, laundry)"
Column J: "Biaya research (R & D)"
Column K: "BIAYA SEWA PERALATAN"
```

**Expected (CORRECT):**
```
Column I: "Biaya Research (R&D)"      ← Follow Kategori Tabular #01
Column J: "Biaya Operasi"             ← Follow Kategori Tabular #02
Column K: "Biaya Sewa Peralatan"      ← Follow Kategori Tabular #03
Column L: "Biaya Interpretasi Log Data" ← #04
Column M: "Administrasi"              ← #05
```

**Root Cause:**
- Header text diambil dari **TEMPLATE EXCEL HARDCODED**, bukan dari database
- Code tidak modify header row, hanya fill data
- Template file: `excel/Revenue-Cost_2024_cleaned_asli_cleaned.xlsx`

---

### 2. Sub-Kategori di Batch Tidak A-Z ❌

**Current (WRONG):**
```
Row 116: Transportation
Row 120: Accommodation
Row 125: Logistic
Row 137: Meal
Row 141: Allowance
```

**Expected (CORRECT):**
```
Row 116: Accommodation    ← A
Row 120: Allowance        ← A
Row 125: Logistic         ← L
Row 137: Meal             ← M
Row 141: Transportation   ← T
```

**Root Cause:**
- Template Excel punya fixed row untuk setiap sub-kategori
- Code assign data ke row template, tidak reorder row
- Merged cells di template interfere dengan sorting logic

---

## 🎯 HARAPAN OUTPUT YANG BENAR

### Scenario 1: Kategori Tabular Order

**User Action:**
1. Buka Laporan Tahunan
2. Tap "Kategori Tabular"
3. Urutkan:
   ```
   01 Biaya Research (R&D)
   02 Biaya Operasi
   03 Biaya Sewa Peralatan
   04 Biaya Interpretasi Log Data
   05 Administrasi
   06 Pembelian Barang
   07 Sewa Kantor
   08 Kesehatan
   09 Bisnis Dev
   ```
4. Save

**Expected Excel Output:**
```
Header Row (Row 41):
Col I  | Col J | Col K | Col L | Col M | Col N | Col O | Col P | Col Q
-------|-------|-------|-------|-------|-------|-------|-------|-------
Biaya  | Biaya | BIAYA | BIAYA | ADMIN | PEMBE | SEWA  | KESEH | BISNIS
Research|Operasi|SEWA  |INTERP |ISTRASI|LIAN  |KANTOR|ATAN  |DEV
(R&D)  |       |PERALATAN|LOG DATA|       |Barang|       |       |
```

**Current Wrong Output:**
```
Header Row (Row 41):
Col I  | Col J | Col K | Col L | Col M | Col N | Col O | Col P | Col Q
-------|-------|-------|-------|-------|-------|-------|-------|-------
Biaya  | Biaya | BIAYA | BIAYA | ADMIN | PEMBE | SEWA  | KESEH | BISNIS
Operasi|research|SEWA  |INTERP |ISTRASI|LIAN  |KANTOR|ATAN  |DEV
(Gaji, |(R & D)|PERALATAN|LOG DATA|       |Barang|       |       |
Tunjangan,...) ← TEXT PANJANG!
```

---

### Scenario 2: Sub-Kategori A-Z di Batch

**User Action:**
1. Download Excel Laporan Tahunan
2. Ada batch settlement "ALFA_TLJ-58" dengan items:
   ```
   - [Transportation] Airplane Ticket
   - [Transportation] Taxi
   - [Accommodation] Hotel
   - [Accommodation] Laundry
   - [Meal] Gloves
   - [Meal] White Marker
   ```

**Expected Excel Output (Batch Section):**
```
Row 116: Accommodation          ← Header A
Row 117:   Hotel
Row 118:   Laundry
Row 120: Allowance              ← Header A (if exists)
Row 125: Logistic               ← Header L
Row 126:   Meal Crew's
Row 137: Meal                   ← Header M
Row 138:   Gloves
Row 139:   White Marker
Row 141: Transportation         ← Header T
Row 142:   Airplane Ticket
Row 143:   Taxi
```

**Current Wrong Output:**
```
Row 116: Transportation         ← Template order (WRONG!)
Row 117:   Airplane Ticket
Row 118:   Taxi
Row 120: Accommodation
Row 121:   Hotel
Row 122:   Laundry
...
```

---

## 🔍 ROOT CAUSE ANALYSIS

### Issue 1: Category Columns Hardcoded

**Location:** `backend/routes/reports/annual.py`

**Problem Flow:**
```
1. Load template Excel → Template punya header text hardcoded
2. Code query categories: root_cats = Category.query...order_by(Category.sort_order)
   ✅ Query sudah BENAR (urut by sort_order)
3. Code mapping expense ke column:
   fallback_col = 9 + _map_expense_category_index_from_name(root_name, cat_names)
   ✅ Mapping sudah BENAR (ikutin urutan cat_names)
4. Code TIDAK modify header row (row 41)
   ❌ HEADER TETAP TEMPLATE LAMA!
```

**Why Not Working:**
- Code hanya fill data ke column yang benar
- **TAPI header row 41 tidak di-update**
- Header text masih dari template Excel (hardcoded)

---

### Issue 2: Sub-Kategori Sort Tidak Jalan

**Location:** `backend/routes/reports/annual.py` line 1183-1318

**Problem Flow:**
```
1. Code collect section headers dari template
2. Code sort headers alphabetically: section_headers_sorted
   ✅ Sorting sudah BENAR
3. Code rebuild section_ranges_sorted
   ⚠️ Logic kompleks, mungkin ada bug
4. Code clear original headers: ws.cell(...).value = None
   ✅ Clear BENAR
5. Code write sorted headers: ws.cell(row=header_row, column=4).value = sorted_titles[idx]
   ⚠️ Write ke row yang SALAH?
```

**Why Not Working:**
- `header_rows_in_order` = row numbers dari `section_ranges_sorted`
- Row numbers ini **MASIH ROW TEMPLATE LAMA** (116, 120, 125, dll)
- Write header "Accommodation" ke row 116 (yang seharusnya Transportation)
- **DATA items juga masih di row lama!**

---

## 💡 SOLUSI FINAL

### Fix 1: Update Category Header Columns

**File:** `backend/routes/reports/annual.py`  
**Add after line 1031:**

```python
# UPDATE HEADER ROW TO MATCH CATEGORY ORDER!
header_row = 41  # Row dengan category headers
for col_idx, category in enumerate(root_cats, start=9):  # Start from column I (9)
    ws.cell(row=header_row, column=col_idx).value = category.name
    ws.cell(row=header_row, column=col_idx).font = Font(bold=True, size=10)
    ws.cell(row=header_row, column=col_idx).alignment = Alignment(wrap_text=True, vertical='center', horizontal='center')
```

---

### Fix 2: Simplify Sub-Category Sort

**File:** `backend/routes/reports/annual.py`  
**Replace line 1183-1318 dengan:**

```python
# SIMPLE APPROACH: Don't use template rows, create new structure
# 1. Group items by subcategory
items_by_subcategory = OrderedDict()
for item in block_items:
    subcat = _expense_subcategory_label(item) or '-'
    items_by_subcategory.setdefault(subcat, []).append(item)

# 2. Sort subcategories A-Z
sorted_subcats = sorted(items_by_subcategory.keys(), key=str.lower)

# 3. Get all available detail rows
all_detail_rows = [r for r in range(start_row, end_row + 1) 
                   if _is_template_detail_data_row(ws, r) or r in subcategory_rows]

# 4. Clear all rows first
for row in all_detail_rows:
    _clear_range(ws, row, row, 2, 17)
    _set_rows_hidden(ws, row, row, False)

# 5. Fill data in sorted order
current_row_idx = 0
for subcat in sorted_subcats:
    # Write header
    if current_row_idx < len(all_detail_rows):
        header_row = all_detail_rows[current_row_idx]
        ws.cell(row=header_row, column=4).value = subcat
        ws.cell(row=header_row, column=4).font = Font(bold=True)
        current_row_idx += 1
    
    # Write items
    for item in items_by_subcategory[subcat]:
        if current_row_idx < len(all_detail_rows):
            item_row = all_detail_rows[current_row_idx]
            _fill_expense_row(ws, item_row, item)  # Create this helper
            current_row_idx += 1

# Hide unused rows
for remaining_row in all_detail_rows[current_row_idx:]:
    _set_rows_hidden(ws, remaining_row, remaining_row, True)
```

---

## 🧪 DEBUG STEPS

### Step 1: Add Print Statements

**File:** `backend/routes/reports/annual.py`

```python
# Line 1029 - After category query
root_cats = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
print(f"\n[DEBUG] === CATEGORY ORDER ===")
for cat in root_cats:
    print(f"  {cat.sort_order}. {cat.name}")
print(f"[DEBUG] cat_names = {cat_names}\n")

# Line 1208 - After sorting subcategories
print(f"\n[DEBUG] === SUBCATEGORY SORT ===")
print(f"  Original: {[subtitle for _, subtitle in section_headers_unsorted]}")
print(f"  Sorted:   {[subtitle for _, subtitle in section_headers_sorted]}\n")
```

### Step 2: Restart Backend & Check Console

```bash
# Windows
taskkill /F /IM python.exe
cd backend
python app.py

# Look for [DEBUG] prints in console
```

### Step 3: Clear Excel Cache

```bash
# Delete cache
del /Q /S backend\exports\annual_cache\*

# Or via Python
import shutil, os
cache_dir = 'backend/exports/annual_cache'
if os.path.exists(cache_dir):
    shutil.rmtree(cache_dir)
    os.makedirs(cache_dir)
```

### Step 4: Test Download

1. Buka Flutter app
2. Laporan Tahunan → Download Excel
3. Check console untuk debug output
4. Buka Excel, verify headers

---

## ✅ ACCEPTANCE CRITERIA

### Kategori Columns
- [ ] Header row 41 shows clean category names (no subcategories in parentheses)
- [ ] Column order matches Kategori Tabular UI
- [ ] Dynamic: Change order in UI → Excel changes on next download

### Sub-Kategori Batch
- [ ] Subcategory headers sorted A-Z
- [ ] Items under correct subcategory header
- [ ] No empty/gap rows between subcategories
- [ ] Works for all batch settlements

---

## 📝 NOTES FOR OTHER AI

**Key Insight:**
- Template Excel adalah **MUSUH** - jangan pakai template rows
- **CREATE FRESH STRUCTURE** based on sorted data
- Header text di template **HARDCODED** - harus di-overwrite

**Files to Focus:**
1. `backend/routes/reports/annual.py` - MAIN ISSUE
2. `backend/routes/reports/helpers.py` - Helper functions
3. `excel/Revenue-Cost_2024_cleaned_asli_cleaned.xlsx` - Template file

**DO NOT MODIFY:**
- Frontend code (already working)
- Migration scripts (already run)
- API endpoints (already working)

**FOCUS ON:**
- Excel generation logic in `annual.py`
- Template header overwrite
- Simple subcategory sort (don't use complex section_ranges)

---

**Good luck! 🍀**
