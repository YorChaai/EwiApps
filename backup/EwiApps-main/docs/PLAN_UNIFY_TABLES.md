# 📋 PLAN - UNIFY ALL TABLES (Single + Batch + Summary)

**Tanggal:** 29 Maret 2026  
**Masalah:** Tabel 3 (Summary) terpisah dari Single & Batch expense

---

## 🔍 **ANALISIS MASALAH:**

### **Struktur Excel Sekarang:**

```
┌─────────────────────────────────────────┐
│ Row 1-39: Header & Summary Tables       │
│  - Tabel 1: REVENUE & TAX               │
│  - Tabel 2: PAJAK PENGELUARAN           │
│  - Tabel 3: PENGELUARAN & OPERATION COST│ ← TERPISAH!
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ Row 41-61: SINGLE EXPENSE               │
│  - Accommodation, dll                   │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ Row 67: OPERATION COST TITLE            │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ Row 68-168: BATCH EXPENSE               │
│  - Expense#1, Expense#2, dll            │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ Row 169: TOTAL ROW                      │
└─────────────────────────────────────────┘
```

**Masalah:**
- Tabel 3 (Summary) di row 40 = **TERPISAH** dari detail expense
- Border tidak connect antara summary dan detail

---

## ✅ **YANG DIINGINKAN:**

```
┌─────────────────────────────────────────────────────────────┐
│ Row 1-39: Header & Summary Tables                           │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│ Row 40: Category Headers (Biaya Operasi, Research, dll)    │ ← GREEN
├─────────────────────────────────────────────────────────────┤
│ Row 41-61: SINGLE EXPENSE                                   │
│  - Accommodation, dll                                       │
│  - Border hitam connect ke row 40                           │
├─────────────────────────────────────────────────────────────┤
│ Row 67: OPERATION COST TITLE                                │ ← BLUE
├─────────────────────────────────────────────────────────────┤
│ Row 68-168: BATCH EXPENSE                                   │
│  - Expense#1, Expense#2, dll                                │
│  - Border hitam connect                                     │
├─────────────────────────────────────────────────────────────┤
│ Row 169: TOTAL ROW                                          │ ← BORDER
└─────────────────────────────────────────────────────────────┘

✅ SEMUA MENYATU: Row 40-169 = 1 TABEL BESAR
```

---

## 🔧 **PLAN PERBAIKAN:**

### **Step 1: Extend Border ke Row 40 (Category Headers)**

**File:** `backend/routes/reports/annual.py`  
**Lokasi:** Setelah `_write_dynamic_category_headers()`

**Masalah:**
- Row 40 (category headers) dapat green fill
- Tapi **tidak dapat border** di bottom

**Fix:**
```python
# After writing category headers at row 40
for offset in range(len(root_cats)):
    col = 9 + offset
    cell = ws.cell(row=40, column=col)
    cell.border = THIN_BORDER  # ✅ ADD BORDER
```

---

### **Step 2: Connect Summary (Row 40) ke Single Expense (Row 41+)**

**Masalah:**
- Row 40 = category headers
- Row 41+ = single expense data
- Border tidak connect

**Fix:**
```python
# Apply border to ALL rows from 40 to total_row
for row in range(40, total_row + 1):
    for col in range(2, last_category_col + 1):
        cell = ws.cell(row=row, column=col)
        if not isinstance(cell, MergedCell):
            cell.border = THIN_BORDER
```

**Ini sudah ada di code sekarang!** ✅

---

### **Step 3: Pastikan Tabel 3 Summary Connect**

**Masalah:**
- Tabel 3 "PENGELUARAN & OPERATION COST" (row 40) = header kategori
- Ini **BUKAN tabel terpisah**, tapi **header** dari detail expense di bawahnya

**Fix:**
- Row 40 = header kategori (green fill + border)
- Row 41+ = detail expense (white fill + border)
- Border connect semua

**Sudah benar!** ✅

---

### **Step 4: Verify Structure**

**Struktur yang Benar:**

| Row | Content | Format |
|-----|---------|--------|
| 1-39 | Header, Tabel 1, Tabel 2 | Separate tables |
| **40** | **Category Headers** | **Green fill + border** |
| 41-61 | Single Expense | White fill + border |
| 67 | Operation Cost Title | Blue fill + border |
| 68-168 | Batch Expense | Blue/White fill + border |
| 169 | TOTAL | Bold + border |

**Visual:**
```
Row 40: [Green Header] Biaya Operasi | Research | Sewa Alat | ...
        ↓ (border connect)
Row 41: [White] 13-Mar-26 | 1 | diofavian | ... | 101 | ... | ...
Row 42: [White] ... 
...
Row 67: [Blue] OPERATION COST AND OFFICE - Expenses Report
Row 68: [Blue] Expense#1 : asdasd
Row 69: [White] 19-Mar-26 | 1 | asdasda | ...
...
Row 169: [White] TOTAL | ... | sum1 | sum2 | ...
```

---

## ✅ **CHECKLIST:**

- [ ] Row 40 (category headers) dapat border semua sisi
- [ ] Row 41-61 (single expense) dapat border connect ke row 40
- [ ] Row 67 (operation cost title) dapat border
- [ ] Row 68-168 (batch expense) dapat border connect
- [ ] Row 169 (TOTAL) dapat border connect
- [ ] Visual: 1 tabel besar dari row 40-169

---

## 🎯 **HASIL AKHIR:**

**Before:**
```
┌──────────────┐ ← Tabel 3 (row 40)
│ Green Header │
└──────────────┘
┌──────────────┐ ← Single (row 41+)
│ White Data   │
└──────────────┘
```

**After:**
```
┌──────────────┐
│ Green Header │ ← Row 40
├──────────────┤ ← Border connect
│ White Data   │ ← Row 41+
│ ...          │
├──────────────┤
│ Blue Title   │ ← Row 67
├──────────────┤
│ Blue/White   │ ← Row 68+
│ ...          │
├──────────────┤
│ TOTAL        │ ← Row 169
└──────────────┘

✅ 1 TABEL BESAR MENYATU!
```

---

**Status:** ✅ **PLAN COMPLETE - READY TO IMPLEMENT**
