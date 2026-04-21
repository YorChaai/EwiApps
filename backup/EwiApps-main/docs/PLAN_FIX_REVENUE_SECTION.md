# PLAN: Fix Revenue Section - Dynamic Rows, Formula, Borders, Merge Cells

## 📊 **Masalah yang Ditemukan**

### **1. Revenue Rows Tidak Dinamis**
**Current:**
- Template punya 15 row (7-21)
- Jika data > 15, data terpotong
- Jika data < 15, banyak row kosong

**Expected:**
- Row otomatis insert jika data > 15
- Row otomatis hide jika data < 15
- Tidak ada row kosong

---

### **2. Total Row Bukan Formula Excel**
**Current:**
```python
# HARDcoded values (SALAH!)
_safe_set_number(ws, 22, 11, total_received)  # ← Python calculation
_safe_set_number(ws, 22, 12, total_ppn_rec)   # ← Python calculation
```

**Expected:**
```python
# Excel formulas (BENAR!)
ws.cell(row=22, column=11).value = '=SUM(K7:K21)'  # ← Auto calculate
ws.cell(row=22, column=12).value = '=SUM(L7:L21)'  # ← Auto calculate
```

**Keuntungan Formula:**
- ✅ Auto-calculate saat user edit data di Excel
- ✅ Tidak ada rounding error dari Python
- ✅ Excel bisa recalculate sendiri

---

### **3. Borders Tidak Apply ke New Rows**
**Current:**
- Borders dari template (static)
- New rows (inserted) tidak punya border
- Hasilnya: ada garis putus-putus

**Expected:**
- Apply THIN_BORDER ke semua rows (template + inserted)
- Consistent borders seperti Expense section

---

### **4. Merge Cells 2024 Kena di 2027**
**Current:**
- Merge cells dari template 2024 masih ada
- Saat export 2027, merge cells 2024 masih ter-apply
- Hasilnya: merge cells salah tempat

**Root Cause:**
```python
# Template masih punya merge cells dari tahun sebelumnya
wb = load_workbook(template_path)  # ← Load template dengan merge cells lama
# Tidak ada code untuk clear merge cells!
```

**Expected:**
- Clear ALL merge cells dari template sebelum render
- Apply merge cells HANYA untuk data tahun yang di-export
- Merge cells berdasarkan `combine_groups` dari database

---

## ✅ **SOLUTION PLAN**

### **Step 1: Clear Merge Cells dari Template**
```python
# Add this AFTER loading template
print(f'[ANNUAL_EXCEL] Clearing old merge cells from template...')
for merged_range in list(ws.merged_cells.ranges):
    # Only clear merge cells in Revenue section (rows 7-21)
    min_row, max_row = merged_range.bounds[1], merged_range.bounds[3]
    if 7 <= min_row <= 21 or 7 <= max_row <= 21:
        try:
            ws.unmerge_cells(str(merged_range))
            print(f'[ANNUAL_EXCEL] Unmerged: {merged_range}')
        except Exception as e:
            print(f'[ANNUAL_EXCEL] Failed to unmerge {merged_range}: {e}')
```

---

### **Step 2: Dynamic Row Insertion for Revenue**
```python
# After rendering all revenues
max_template_row = 21
visible_revenue_rows = len(revenues)

if visible_revenue_rows > max_template_row - 6:  # More than 15 rows
    extra_rows_needed = visible_revenue_rows - (max_template_row - 6)
    insert_at = max_template_row + 1
    
    print(f'[ANNUAL_EXCEL] Inserting {extra_rows_needed} rows for revenue...')
    ws.insert_rows(insert_at, extra_rows_needed)
    
    # Clone format from last template row
    for i in range(extra_rows_needed):
        _clone_row_format(ws, max_template_row, insert_at + i)
    
    print(f'[ANNUAL_EXCEL] Inserted {extra_rows_needed} rows at {insert_at}')
    max_template_row += extra_rows_needed
```

---

### **Step 3: Apply Borders to All Revenue Rows**
```python
# After rendering all revenues
for row in range(7, 6 + visible_revenue_rows + 1):
    for col in range(2, 16):  # Columns B to O
        cell = ws.cell(row=row, column=col)
        if not isinstance(cell, MergedCell):
            cell.border = THIN_BORDER

# Apply border to Total row (22)
for col in range(2, 16):
    cell = ws.cell(row=22, column=col)
    if not isinstance(cell, MergedCell):
        cell.border = THIN_BORDER
```

---

### **Step 4: Use Excel Formulas for Total**
```python
# Instead of hardcoded values
# _safe_set_number(ws, 22, 11, total_received)  # ← REMOVE THIS

# Use Excel formulas
last_revenue_row = 6 + visible_revenue_rows
ws.cell(row=22, column=11).value = f'=SUM(K7:K{last_revenue_row})'
ws.cell(row=22, column=12).value = f'=SUM(L7:L{last_revenue_row})'
ws.cell(row=22, column=13).value = f'=SUM(M7:M{last_revenue_row})'
ws.cell(row=22, column=14).value = f'=SUM(N7:N{last_revenue_row})'

# Keep Python calculation for display in log only
print(f'[ANNUAL_EXCEL] Revenue total: {total_received} (calculated by Excel formula)')
```

---

### **Step 5: Apply Merge Cells Based on combine_groups**
```python
# Apply merge cells ONLY for current year's data
revenue_combine_groups = _manual_combine_groups_by_table('revenues', year)
_apply_manual_revenue_combine_groups(ws, revenues, revenue_combine_groups, start_row=7)

print(f'[ANNUAL_EXCEL] Applied {len(revenue_combine_groups)} merge groups for revenue')
```

---

## 📋 **Implementation Order**

1. **Clear merge cells** from template (rows 7-21)
2. **Render revenue data** (existing code)
3. **Insert extra rows** if needed
4. **Apply borders** to all rows
5. **Set Excel formulas** for Total row
6. **Apply merge cells** from combine_groups

---

## 🎯 **Expected Result**

### **Scenario 1: No Data (2027)**
```
Row 7:  | # | Belum ada data pendapatan | ... |
Row 8-21: [HIDDEN]
Row 22: | REVENUE (IDR) | - | =SUM(K7:K7) | =SUM(L7:L7) | ... |
```

### **Scenario 2: 3 Items**
```
Row 7:  | 1 | Invoice A | 1000 | ... |
Row 8:  | 2 | Invoice B | 2000 | ... |
Row 9:  | 3 | Invoice C | 3000 | ... |
Row 10-21: [HIDDEN]
Row 22: | REVENUE (IDR) | 6000 | =SUM(K7:K9) | =SUM(L7:L9) | ... |
```

### **Scenario 3: 20 Items (> 15)**
```
Row 7:   | 1 | Invoice A | 1000 | ... |
Row 8:   | 2 | Invoice B | 2000 | ... |
...
Row 21:  | 15 | Invoice O | 15000 | ... |
Row 22:  | 16 | Invoice P | 16000 | ... |  ← INSERTED
Row 23:  | 17 | Invoice Q | 17000 | ... |  ← INSERTED
...
Row 26:  | 20 | Invoice T | 20000 | ... |  ← INSERTED
Row 27:  | REVENUE (IDR) | =SUM(...) | ... |
```

### **Scenario 4: Merge Cells (2024 data)**
```
Row 7-8:  | [MERGED] Invoice A (2 rows) | ... |  ← Merged from combine_groups
Row 9:    | 2 | Invoice B | ... |
Row 10-12:| [MERGED] Invoice C (3 rows) | ... |  ← Merged from combine_groups
```

---

## 🧪 **Testing Checklist**

- [ ] Export 2024 (with data + merge cells)
  - [ ] Merge cells applied correctly
  - [ ] Borders consistent
  - [ ] Formula works in Excel

- [ ] Export 2027 (no data)
  - [ ] No merge cells from 2024
  - [ ] Only 1 row visible ("Belum ada data")
  - [ ] Row 8-21 hidden

- [ ] Export with 3 items
  - [ ] 3 rows visible
  - [ ] Row 10-21 hidden
  - [ ] Total formula correct

- [ ] Export with 20 items
  - [ ] 5 extra rows inserted
  - [ ] Borders applied to inserted rows
  - [ ] Total formula includes all rows

- [ ] Open in Excel
  - [ ] Formula auto-calculates
  - [ ] No #REF! errors
  - [ ] Borders display correctly

---

## 📝 **Files to Modify**

1. **`backend/routes/reports/annual.py`**
   - Function: `get_annual_report_excel()`
   - Section: TABLE 1: REVENUE & TAX (around line 1525-1590)

---

## ⚠️ **Potential Issues**

1. **Formula Reference Error**
   - If row insertion changes row numbers, formula must update
   - Solution: Use dynamic `last_revenue_row` variable

2. **Merge Cell Conflicts**
   - Old merge cells may conflict with new ones
   - Solution: Clear ALL merge cells before rendering

3. **Border Style Mismatch**
   - Inserted rows may have different border style
   - Solution: Use `_clone_row_format()` to copy exact style

---

**Ready to implement?** Let me know! 🚀
