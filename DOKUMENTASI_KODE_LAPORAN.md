# Dokumentasi Kode Laporan Tahunan - Backend EWI

**Last Updated:** 30 Maret 2026  
**Author:** AI Assistant  
**Project:** MiniProject KPI EWI

---

## 📁 **File Structure**

```
backend/routes/reports/
├── annual.py      (1677 lines) - Endpoint Laporan Tahunan
├── helpers.py     (429 lines)  - Helper Functions untuk Reports
└── summary.py     (686 lines)  - Endpoint Laporan Summary
```

---

## 📊 **1. annual.py - Laporan Tahunan**

### **🎯 Purpose**
File ini menangani export **Laporan Tahunan** (Revenue vs Operation Cost) dalam 3 format:
- JSON (untuk frontend Flutter)
- PDF 
- Excel

### **📍 Base URL**
```
GET /api/reports/annual
GET /api/reports/annual/pdf
GET /api/reports/annual/excel
```

### **🔑 Main Functions**

#### **1.1 Endpoints (Line 1429-1677)**

| Function | Line | Method | Description |
|----------|------|--------|-------------|
| `get_annual_report()` | 1429 | GET | Return JSON payload untuk frontend |
| `get_annual_report_pdf()` | 1440 | GET | Export PDF Laporan Tahunan |
| `get_annual_report_excel()` | 1451 | GET | Export Excel Laporan Tahunan |

**Parameters:**
```python
year = request.args.get('year', _default_report_year(), type=int)
```

---

#### **1.2 Data Building (Line 220-473)**

**`_build_annual_payload_from_db(year)`** - Line 220

**Purpose:** Mengambil semua data dari database untuk laporan tahunan

**Data yang Diambil:**
```python
1. Revenue   → Filter: db.extract('year', Revenue.invoice_date) == year
2. Tax       → Filter: db.extract('year', Tax.date) == year
               Special: 2024 includes 2023 data (legacy migration)
3. Expenses  → Filter: db.extract('year', Expense.date) == year
               Join: Settlement.status IN ('approved', 'completed')
4. Dividends → Filter: db.extract('year', Dividend.date) == year
```

**Return:**
```python
{
    'year': int,
    'revenue': {
        'data': List[Revenue],
        'total_amount_received': float,
        'total_ppn': float,
        'total_pph23': float
    },
    'tax': {
        'data': List[Tax],
        'total_ppn': float,
        'total_pph21': float,
        'total_pph23': float,
        'total_pph26': float
    },
    'dividend': {...},
    'operation_cost': {
        'data': List[Expense],
        'total_expenses': float
    },
    'generated_at': datetime
}
```

**Special Logic:**
- **Report Tags:** Jika ada tag di `report_entry_tags`, gunakan ID dari tag (prioritas)
- **Tax Year 2024:** Include 2023 data untuk legacy migration
- **Expense Grouping:** Group by settlement (single vs batch)

---

#### **1.3 Excel Export (Line 1451-1677)**

**`get_annual_report_excel()`** - Main Flow:

```python
1. Load template Excel
   - Priority: Imported template > Revenue-Cost_2024_cleaned_asli_cleaned.xlsx
   
2. Clear template data
   - Revenue section (rows 7-21)
   - Tax section (rows 27-36)
   - Clear old merge cells (data rows only)
   
3. Render Revenue & Tax (Table 1)
   - Clear rows 7-21, columns B-O
   - Hide all rows first
   - Render revenue data
   - If no data: show 1 row "Belum ada data revenue"
   - Apply borders
   - TOTAL row with Excel formulas + gray fill
   
4. Render Tax (Table 2)
   - Clear rows 27-36
   - Render tax data
   - Apply merge cells from combine_groups
   
5. Render Expenses (Table 3)
   - Call _render_expense_section_from_data()
   - Single expenses grouped by subcategory
   - Batch expenses grouped by settlement
   - TOTAL row with formulas
   
6. Generate secondary sheets
   - Laba rugi -{year}
   - Business Summary
   
7. Send file
```

---

#### **1.4 Expense Rendering (Line 684-970)**

**`_render_expense_section_from_data(ws, expenses, cat_names, category_by_id_map, year)`**

**Purpose:** Render expense section dari scratch (data-driven, seperti frontend Flutter)

**Structure:**
```
Row 41+: Single Expenses
  - Grouped by subcategory (A-Z)
  - Subcategory header (bold, no date/sequence)
  - Expense items (with date, sequence number)

Row X: Separator (green fill)
  "OPERATION COST AND OFFICE - Expenses Report"

Row X+1+: Batch Expenses
  - Expense#1: [Settlement Title] (blue fill)
    - Subcategory header (bold)
    - Expense items
  - Expense#2: [Settlement Title] (blue fill)
    - ...

Row Y: TOTAL (gray fill)
  - Excel formulas: =SUM(...)
```

**Subcategory Extraction (Line 589-655):**
```python
def _expense_subcategory_label(expense):
    # Priority 1: [SubCategory] prefix in description
    # Priority 2: 'Subcategory: X' in notes
    # Priority 3: Keyword matching (like Flutter)
    #    - 'rental tool' → 'Rental Tool'
    #    - 'gaji'/'bonus' → 'Gaji'
    #    - 'allowance' → 'Allowance'
    #    - etc. (15+ keywords)
    # Priority 4: subcategory_name field (fallback)
```

**Keyword Matching (SAME AS FLUTTER):**
```python
'rental tool' → 'Rental Tool'
'sales' → 'Sales'
'gaji' or 'bonus' → 'Gaji'
'pembuatan alat' or 'mesin retort' → 'Pembuatan Alat'
'thr' or 'allowance' → 'Allowance'
'data processing' → 'Data Processing'
'moving slickline' or 'project lampu' → 'Project Operation'
'sampling tool' or 'sparepart' or 'ups biaya import' → 'Sparepart'
'repair esor' → 'Maintenance'
'licence' or 'license' → 'Software License'
'handphone operational' → 'Operation'
'sewa ruangan' or 'virtual office' → 'Sewa Ruangan'
'modal kerja' → 'Modal Kerja'
'team building' → 'Team Building'
'biaya transaksi bank' → 'Biaya Bank'
```

---

#### **1.5 Helper Functions**

| Function | Line | Purpose |
|----------|------|---------|
| `_extract_subcategory_from_description()` | 69 | Extract [SubCategory] prefix |
| `_root_category_info()` | 78 | Get root & subcategory name from category_id |
| `_subcategory_sort_key()` | 87 | Sort key for subcategories (A-Z) |
| `_write_dynamic_category_headers()` | 93 | Write category headers from DB |
| `_expense_column_mapping_name()` | 148 | Map expense to category column |
| `_expense_amount_for_display()` | 168 | Calculate IDR amount from currency |
| `_compute_dividend_distribution()` | 195 | Calculate dividend per person |
| `_group_annual_expenses()` | 354 | Group expenses by settlement |
| `_manual_combine_groups_by_table()` | 1050 | Get merge groups from database |
| `_apply_manual_revenue_combine_groups()` | 1056 | Apply merge cells to revenue |
| `_ensure_formatted_secondary_sheets()` | 1102 | Create Laba rugi & Business Summary sheets |
| `_sync_formatted_secondary_sheets()` | 1184 | Sync secondary sheets with main data |

---

### **⚠️ Known Issues**

1. **Line too long (C0301):** 100+ lines exceed 100 characters
2. **Too many locals (R0914):** Functions have >15 local variables
3. **Too many branches (R0912):** Functions have >12 if/else statements
4. **Too many statements (R0915):** Functions have >50 statements
5. **Multiple statements on one line (C0321):** Code style issue
6. **Unused imports (W0611):** OrderedDict, helper functions not used
7. **Broad exception (W0718):** Catching general Exception
8. **Missing docstrings (C0114, C0116):** No module/function documentation

---

## 🛠️ **2. helpers.py - Helper Functions**

### **🎯 Purpose**
Shared utility functions untuk package reports (annual.py, summary.py)

### **🔑 Main Functions**

#### **2.1 Configuration (Line 9-10)**

```python
def _default_report_year():
    """Get default year from config or current year"""
    return int(current_app.config.get('REPORT_DEFAULT_YEAR', datetime.now().year))
```

---

#### **2.2 Safe Cell Operations (Line 12-40)**

```python
def _safe_set_cell(ws, row, col, value):
    """Set cell value, skip if merged cell"""
    
def _safe_set_number(ws, row, col, value, number_format=None):
    """Set number with format, skip if merged cell"""
    
def _safe_text(value):
    """Convert value to string safely"""
```

---

#### **2.3 Row/Cell Detection (Line 42-145)**

```python
def _is_date_like(value):
    """Check if value is date-like (string, datetime, date)"""
    
def _is_template_detail_data_row(ws, row_num):
    """
    Detect if row is expense detail row.
    Criteria:
    - Column B has date (primary)
    - Column C has sequence number (fallback)
    """
    
def _extract_imported_row(notes):
    """Extract 'Imported from row X' from notes"""
    
def _extract_batch_number(title):
    """Extract batch number from title (e.g., 'Batch #5')"""
    
def _is_batch_settlement(settlement_type, title):
    """Check if settlement is batch type"""
```

---

#### **2.4 Category Mapping (Line 147-282)**

```python
def _map_expense_category_index(expense, cat_names):
    """Map expense to category column index (0-based)"""
    
def _map_expense_category_index_from_name(category_name, cat_names):
    """Map category name to column index"""
    
def _map_expense_column(category_name):
    """Map category name to Excel column letter"""
```

---

#### **2.5 Expense Grouping (Line 316-429)**

**`_group_annual_expenses(expenses, year)`** - Line 353

**Purpose:** Group expenses by settlement for annual report

**Logic:**
```python
1. Group by settlement_id (or title if no ID)
2. Sort within group by:
   - Subcategory (A-Z)
   - Imported row (priority)
   - Date
   - ID
3. Sort groups by:
   - Subcategory (A-Z)
   - Batch vs Single
   - Date
```

**Subcategory Extraction (Line 333-401):**
```python
# Same logic as annual.py _expense_subcategory_label()
# Priority: [Prefix] → Notes → Keywords → subcategory_name
```

---

#### **2.6 Template Operations (Line 284-314)**

```python
def _normalize_external_formula_refs(wb):
    """Fix external formula references in workbook"""
    
def _clear_range(ws, start_row, end_row, start_col, end_col):
    """Clear cell values in range (keep format)"""
    
def _set_rows_hidden(ws, start_row, end_row, hidden):
    """Hide/unhide rows"""
    
def _clone_row_format(ws, source_row, target_row):
    """Copy format from source row to target row"""
```

---

### **⚠️ Known Issues**

1. **Line too long:** Some lines exceed 100 characters
2. **Protected access (W0212):** Access to _style member
3. **Broad exception:** Catching general Exception

---

## 📈 **3. summary.py - Laporan Summary**

### **🎯 Purpose**
Export **Laporan Summary** (Monthly/Yearly summary) dalam format:
- JSON
- PDF
- Excel

### **📍 Base URL**
```
GET /api/reports/summary
GET /api/reports/summary/pdf
GET /api/reports/excel
```

---

### **🔑 Main Functions**

#### **3.1 Data Building (Line 42-213)**

**`_get_summary_approved_expenses(year, start_date, end_date)`** - Line 42

**Purpose:** Get approved expenses for summary period

**Filter:**
```python
Settlement.status IN ('approved', 'completed')
AND Expense.date BETWEEN start_date AND end_date
```

---

#### **3.2 Endpoints (Line 224-686)**

| Function | Line | Method | Description |
|----------|------|--------|-------------|
| `get_summary_report()` | 224 | GET | JSON summary data |
| `get_summary_pdf()` | 243 | GET | PDF summary export |
| `get_summary_excel()` | 310 | GET | Excel summary export |

**Parameters:**
```python
year = request.args.get('year', _default_report_year(), type=int)
month = request.args.get('month', type=int)  # Optional
```

---

#### **3.3 Excel Export Flow (Line 310-686)**

```python
1. Fetch data:
   - Revenues (by year/month)
   - Taxes (by year/month)
   - Expenses (approved, by year/month)
   
2. Load template:
   - Summary_report_template.xlsx
   
3. Render sheets:
   - Summary (main)
   - Laba rugi
   - Business Summary
   
4. Apply formulas:
   - Monthly totals
   - Yearly totals
   
5. Send file
```

---

### **⚠️ Known Issues**

1. **Line too long:** Many lines exceed 100 characters
2. **Too many locals:** Functions have >15 variables
3. **Too many branches:** Complex if/else logic
4. **Missing docstrings:** No function documentation

---

## 🔗 **Data Flow Diagram**

```
Frontend (Flutter)
    ↓
GET /api/reports/annual?year=2027
    ↓
annual.py:get_annual_report_excel()
    ↓
_build_annual_payload_from_db(2027)
    ├── Revenue.query.filter(year=2027)
    ├── Tax.query.filter(year=2027)
    ├── Expense.query.filter(year=2027)
    └── Dividend.query.filter(year=2027)
    ↓
_render_expense_section_from_data()
    ├── Group by subcategory (keyword matching)
    ├── Render single expenses
    ├── Render batch expenses
    └── Render TOTAL row
    ↓
Sync secondary sheets (Laba rugi, Business Summary)
    ↓
Return Excel file
```

---

## 🐛 **Common Bugs & Fixes**

### **Bug 1: Data 2026 Muncul di Export 2027**

**Cause:** Filter menggunakan `db.extract('year', Expense.date)`

**Fix:** Check database for expenses with wrong date:
```sql
SELECT id, date, description 
FROM expenses 
WHERE strftime('%Y', date) = '2026'
AND settlement_id IN (
    SELECT id FROM settlements 
    WHERE strftime('%Y', date) = '2027'
);
```

---

### **Bug 2: Subcategory Tidak Sesuai Frontend**

**Cause:** Backend pakai `subcategory_name` field, frontend pakai keyword matching

**Fix:** Update `_expense_subcategory_label()` to match Flutter logic:
```python
# Priority 3: Keyword matching (like Flutter)
if 'rental tool' in desc: return 'Rental Tool'
if 'gaji' in desc or 'bonus' in desc: return 'Gaji'
# ... (15+ keywords)
```

---

### **Bug 3: Merge Cells 2024 Kena di 2027**

**Cause:** Template masih punya merge cells dari export sebelumnya

**Fix:** Clear merge cells sebelum render:
```python
for merged_range in list(ws.merged_cells.ranges):
    min_row, max_row = merged_range.bounds[1], merged_range.bounds[3]
    if (7 <= min_row <= 21) or (7 <= max_row <= 21):
        ws.unmerge_cells(str(merged_range))
```

---

### **Bug 4: Row Kosong Banyak di Revenue**

**Cause:** Template punya 15 row, tidak di-hide saat tidak ada data

**Fix:** Hide unused rows:
```python
if not revenues:
    _set_rows_hidden(ws, 7, 21, True)  # Hide all
    _set_rows_hidden(ws, 7, 7, False)  # Unhide 1 row
```

---

## 📝 **Code Style Issues (Pylint)**

### **Critical (E - Error):**
- `E0401`: Unable to import (flask_jwt_extended, reportlab)
  - **Fix:** Install dependencies in venv

### **Warning (W - Warning):**
- `W0718`: Catching too general exception Exception
  - **Fix:** Catch specific exceptions (ValueError, KeyError)
- `W0612`: Unused variable
  - **Fix:** Remove unused variables
- `W0611`: Unused import
  - **Fix:** Remove unused imports
- `W1309`: f-string without interpolated variables
  - **Fix:** Use regular string or add interpolation

### **Convention (C - Convention):**
- `C0301`: Line too long (100+ chars)
  - **Fix:** Break into multiple lines
- `C0321`: Multiple statements on one line
  - **Fix:** Separate statements
- `C0114/C0116`: Missing docstring
  - **Fix:** Add docstrings

### **Refactor (R - Refactor):**
- `R0914`: Too many local variables (>15)
  - **Fix:** Split into smaller functions
- `R0912`: Too many branches (>12)
  - **Fix:** Use early returns, extract methods
- `R0915`: Too many statements (>50)
  - **Fix:** Refactor into smaller functions

---

## 🚀 **Recommendations**

1. **Split annual.py** into smaller modules:
   - `annual_data.py` - Data building
   - `annual_excel.py` - Excel rendering
   - `annual_pdf.py` - PDF generation

2. **Add type hints** for better IDE support

3. **Add unit tests** for:
   - `_expense_subcategory_label()`
   - `_group_annual_expenses()`
   - `_render_expense_section_from_data()`

4. **Use dataclasses** for payload structure

5. **Add logging** instead of print() statements

---

## 📞 **Contact**

Untuk pertanyaan atau update dokumentasi, hubungi development team.
