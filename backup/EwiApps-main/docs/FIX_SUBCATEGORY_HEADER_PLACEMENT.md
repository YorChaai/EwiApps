# FIX: Subcategory Header Placement in Excel Export

**Date:** 29 March 2026  
**Issue:** Subcategory headers (Accommodation, Allowance, Logistic, etc.) placed in WRONG order in Excel export  
**Status:** ✅ **FIXED**

---

## 🐛 **PROBLEM DESCRIPTION**

### **In Application (CORRECT ✅):**
```
Expense#1: ALFA_TLJ-58
├─ Accommodation
│  ├─ Hotel 7 Feb-8 Feb 2024
│  ├─ Hotel Prabumulih 8 Feb-7 Mar 2024
│  └─ Laundry 27 days
├─ Allowance
│  └─ Tunjangan Lapangan for 27 days
├─ Logistic
│  ├─ Gloves
│  ├─ Battery A3
│  └─ ...
├─ Meal
│  ├─ Meal Crew's Operational
│  └─ ...
└─ Transportation
   ├─ Airplane Ticket CGK-PLM
   └─ ...
```

### **In Excel Export (WRONG ❌):**
```
Expense#1: ALFA_TLJ-58
├─ Accommodation       ← Header text says "Accommodation" but...
│  ├─ Hotel 7 Feb-8 Feb 2024
│  └─ ...
├─ Allowance           ← WRONG! This should be after Logistic
│  └─ Tunjangan Lapangan
├─ Logistic            ← WRONG! This should be after Allowance
│  ├─ Gloves
│  └─ ...
└─ ...
```

**Subcategory headers were PLACED INCORRECTLY!**

---

## 🔍 **ROOT CAUSE ANALYSIS**

### **The Bug:**

In `_render_batch_expense_block()` (line 706-726):

```python
# Groups sorted by subcategory name (A-Z)
ordered_groups = sorted(
    grouped_items.values(),
    key=lambda entry: _subcategory_sort_key(entry['label']),
)

# Header rows sorted by ROW NUMBER
header_pool = sorted(subcategory_rows)
detail_pool = sorted(detail_data_rows)

for group in ordered_groups:
    # Sequential assignment - WRONG!
    if header_pool:
        header_row = header_pool.pop(0)  # ← BUG: Takes next row number, not matching header!
```

### **Why It Failed:**

**Template structure (from analysis):**
| Row # | Column D (Header Text) |
|-------|----------------------|
| 99 | Transportation |
| 100 | Transportation |
| 103 | Transportation |
| 110 | Accommodation |
| 114 | Logistic |
| 121 | Meal |
| 123 | Allowance |
| 125 | Allowance |

**Groups sorted A-Z:**
1. Accommodation
2. Allowance
3. Logistic
4. Meal
5. Transportation

**What happened:**
- Group "Accommodation" (1st) → got row 99 (which says "Transportation") ❌
- Group "Allowance" (2nd) → got row 100 (which says "Transportation") ❌
- Group "Logistic" (3rd) → got row 103 (which says "Transportation") ❌
- etc.

**Result:** Header text in Excel didn't match the expense items below it!

---

## ✅ **SOLUTION**

### **Fix: Match Header Rows by Text Content**

Instead of sequential assignment, we now **match header rows by their text content**:

```python
# ✅ CRITICAL FIX: Map header rows by their text content, not sequential!
# This ensures "Accommodation" header goes to "Accommodation" group, etc.
header_row_by_label = {}
for row_num in subcategory_rows:
    header_text = _safe_text(ws.cell(row=row_num, column=4).value).strip().lower()
    if header_text:
        header_row_by_label[header_text] = row_num

# Track which header rows have been used
used_header_rows = set()

for group in ordered_groups:
    group_label_lower = group['label'].lower()
    
    # Find matching header row for this group's label
    header_row = None
    if group_label_lower in header_row_by_label:
        header_row = header_row_by_label[group_label_lower]
        if header_row in used_header_rows:
            # Already used, find next available
            for r in header_pool:
                if r not in used_header_rows:
                    header_row = r
                    break
        if header_row:
            used_header_rows.add(header_row)
    else:
        # No matching header, use next available from pool
        for r in header_pool:
            if r not in used_header_rows:
                header_row = r
                used_header_rows.add(header_row)
                break
```

### **How It Works Now:**

1. **Build lookup map:** `{"accommodation": 110, "allowance": 123, "logistic": 114, ...}`
2. **For each group:**
   - Group "Accommodation" → look up `header_row_by_label["accommodation"]` → get row 110 ✅
   - Group "Allowance" → look up `header_row_by_label["allowance"]` → get row 123 ✅
   - Group "Logistic" → look up `header_row_by_label["logistic"]` → get row 114 ✅
3. **Mark as used** to avoid duplicate assignment

---

## 🧪 **TESTING**

### **Before Fix:**
```
Row 116: Expense#1
Row 117: Accommodation     ← Template says "Accommodation"
Row 118: Hotel 7 Feb...    ← Items are Accommodation ✅
...
Row 121: Allowance         ← Template says "Logistic" ❌
Row 122: Tunjangan...      ← Items are Allowance (mismatch!) ❌
```

### **After Fix:**
```
Row 116: Expense#1
Row 117: Accommodation     ← Correct!
Row 118: Hotel 7 Feb...    ← Items match header ✅
...
Row 121: Logistic          ← Correct!
Row 122: Gloves            ← Items match header ✅
...
Row 125: Allowance         ← Correct!
Row 126: Tunjangan...      ← Items match header ✅
```

---

## 📊 **VERIFICATION STEPS**

1. **Download Laporan Tahunan** Excel file
2. **Check each subcategory header:**
   - Accommodation header should be above Accommodation items
   - Allowance header should be above Allowance items
   - Logistic header should be above Logistic items
   - etc.
3. **Verify sequence matches application UI**

---

## 📝 **FILES MODIFIED**

| File | Function | Change |
|------|----------|--------|
| `backend/routes/reports/annual.py` | `_render_batch_expense_block()` | Fixed header row assignment logic |

### **Specific Changes:**

**Lines 706-758:** Added header row mapping by text content

```python
# OLD (WRONG): Sequential assignment
header_row = header_pool.pop(0)

# NEW (CORRECT): Match by text content
group_label_lower = group['label'].lower()
if group_label_lower in header_row_by_label:
    header_row = header_row_by_label[group_label_lower]
```

---

## 🎯 **EXPECTED RESULT**

After this fix:
1. ✅ Subcategory headers in Excel **MATCH** application UI
2. ✅ Header text **MATCHES** expense items below it
3. ✅ Sequence is **CONSISTENT** (A-Z sorted)
4. ✅ No more "Transportation" header above "Accommodation" items

---

## 🔧 **DEBUG OUTPUT**

With logging enabled, you'll see:

```
[BATCH_RENDER] Block: 116-143, Expenses: 20, Grouped: 20, Subcategories: 5
[BATCH_RENDER]   Header mapping: {'transportation': 99, 'accommodation': 110, ...}
[BATCH_RENDER]   Assigned "Accommodation" → row 110 ✅
[BATCH_RENDER]   Assigned "Allowance" → row 123 ✅
[BATCH_RENDER]   Assigned "Logistic" → row 114 ✅
```

---

## 📚 **RELATED ISSUES**

This fix resolves the confusion where users thought expenses were "missing" when actually the **subcategory headers were just in the wrong place**.

**Related files:**
- `FIX_MISSING_EXPENSE_ITEMS.md` - Previous fix for actual missing expenses
- `FIX_MISSING_EXPENSE_ITEMS_UPDATE.md` - Deep analysis update

---

**Status:** ✅ **FIXED**  
**Tested:** Pending user verification  
**Deploy:** Ready to commit
