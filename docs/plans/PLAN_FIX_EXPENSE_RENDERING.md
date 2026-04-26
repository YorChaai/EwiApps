# PLAN: Fix Expense Rendering - Match Template Structure

## 📊 Analisis Masalah

### Template Excel Structure (BENAR):
```
Row 41: [Accommodation] ← Subcategory header
        Column B: EMPTY (no date)
        Column C: EMPTY (no sequence)
        Column D: "Accommodation" (bold)

Row 42: 07-Mar-24 | 1 | Laundry 30 days... ← Expense item
        Column B: Date
        Column C: Sequence number
        Column D: Description

Row 43: 07-Mar-24 | 2 | ... ← Expense item
```

### Download Result (SALAH):
```
Row 41: 08-Feb-24 | 6 | Biaya Operasi ← SALAH! Ini header tapi ada date & seq
Row 42: 07-Feb-24 | 1 | Airplane Ticket...
```

---

## 🔍 Root Cause

**Problem:** Code saya menganggap SEMUA row adalah expense items, padahal ada 2 jenis row:

1. **Subcategory Header Row** - TIDAK boleh ada:
   - ❌ Date (column B)
   - ❌ Sequence number (column C)
   - ✅ Bold text di column D (subcategory name)

2. **Expense Item Row** - HARUS ada:
   - ✅ Date (column B)
   - ✅ Sequence number (column C)
   - ✅ Description (column D)

---

## ✅ Fix Plan

### Step 1: Restore New Data-Driven Code
Uncomment `_render_expense_section_from_data()` yang sudah diperbaiki.

### Step 2: Fix Subcategory Header Rendering
**Current Code (SALAH):**
```python
for subcat, items in batch_grouped['groups'].items():
    # Render header
    _safe_set_cell(ws, row_cursor, 2, _parse_iso_date(...))  # ❌ SALAH!
    _safe_set_cell(ws, row_cursor, 3, batch_item_counter)    # ❌ SALAH!
    _safe_set_cell(ws, row_cursor, 4, subcat)
    row_cursor += 1
    
    # Render items
    for expense in items:
        ...
```

**Fixed Code (BENAR):**
```python
for subcat, items in batch_grouped['groups'].items():
    # Render header - NO DATE, NO SEQUENCE
    for col in range(2, last_category_col + 1):
        cell = ws.cell(row=row_cursor, column=col)
        if not isinstance(cell, MergedCell):
            cell.fill = copy(white_fill)
            cell.border = THIN_BORDER
    
    _safe_set_cell(ws, row_cursor, 4, subcat)  # ✅ Only subcategory name
    ws.cell(row=row_cursor, column=4).font = Font(bold=True)
    row_cursor += 1  # ✅ Don't increment sequence counter
    
    # Render items - WITH DATE, WITH SEQUENCE
    for expense in items:
        _safe_set_cell(ws, row_cursor, 2, _parse_iso_date(expense.get('date')))
        _safe_set_cell(ws, row_cursor, 3, batch_item_counter)  # ✅ Continue sequence
        ...
        batch_item_counter += 1  # ✅ Increment only for items
```

### Step 3: Fix Single Expenses Same Way
Same fix untuk single expenses section.

### Step 4: Verify Sequence Numbering
**Expected:**
```
Expense#1: ALFA_TLJ-58
  Biaya Operasi
    08-Feb-24 | 1 | ...
    07-Feb-24 | 2 | ...
  Pembelian Barang
    07-Feb-24 | 3 | ...  ← Continue from 2, NOT reset to 1
    19-Feb-24 | 4 | ...
```

**Current (SALAH):**
```
Expense#1: ALFA_TLJ-58
  Biaya Operasi
    08-Feb-24 | 1 | ...
  Pembelian Barang
    07-Feb-24 | 1 | ...  ← ❌ Reset to 1!
```

---

## 📝 Implementation Steps

1. **Uncomment new rendering code**
2. **Fix subcategory header rendering** (no date, no sequence)
3. **Fix sequence numbering** (continue across subcategories)
4. **Test export**
5. **Compare with template**

---

## ✅ Expected Result

After fix, export should match template:
- ✅ Subcategory headers: NO date, NO sequence, BOLD name
- ✅ Expense items: WITH date, WITH sequence, normal text
- ✅ Sequence continues across subcategories (1,2,3... not reset)
- ✅ Blue fill for batch headers
- ✅ Green fill for separator
- ✅ White fill for subcategory headers and expense items
