# IMPLEMENTASI Opsi 1 - Rebuild Table 3 dari Data

## Rencana Implementasi

### Files to Modify:
1. `backend/routes/reports/annual.py` - Main Excel export logic

### Changes:

#### 1. Hapus Template Dependency untuk Table 3
- Tidak lagi menggunakan template rows untuk expense rendering
- Render semua expense dari data API response
- Sama seperti frontend Flutter

#### 2. New Function: `_render_expense_section_from_data()`
```python
def _render_expense_section_from_data(ws, expenses, cat_names, category_by_id_map, year):
    """
    Render expense section from scratch using data-driven approach.
    Same logic as frontend Flutter app.
    
    Structure:
    - Single expenses grouped by subcategory (A-Z)
    - Batch expenses grouped by settlement, then subcategory (A-Z)
    - Total row with category totals
    """
```

#### 3. Expense Rendering Flow:
```
1. Separate single vs batch expenses
2. Group single expenses by subcategory (from subcategory_name field)
3. Sort subcategories A-Z
4. Render single expenses with subcategory headers
5. Render batch expense headers (Expense#1, Expense#2, ...)
6. For each batch, group by subcategory and render
7. Add TOTAL row with category totals
```

#### 4. Key Improvements:
- Use `subcategory_name` field from database (NOT keyword matching)
- Dynamic row creation (no template dependency)
- Consistent with frontend display
- Support for dynamic categories from Kategori Tabular

## Implementation Details

### Subcategory Extraction (FIXED):
```python
def _expense_subcategory_label(expense):
    # PRIORITY 1: Use subcategory_name field from database
    subcategory_name = _safe_text(expense.get('subcategory_name')).strip()
    if subcategory_name:
        return subcategory_name
    
    # PRIORITY 2: Fallback to [SubCategory] prefix in description
    raw_desc = _safe_text(expense.get('description')).strip()
    prefixed = re.match(r'^\[(.*?)\]\s*(.*)$', raw_desc)
    if prefixed:
        prefix = _safe_text(prefixed.group(1)).strip()
        if prefix:
            return prefix
    
    # PRIORITY 3: Fallback to notes
    notes = _safe_text(expense.get('notes')).strip()
    note_match = re.search(r'\bSubcategory:\s*([^|]+)', notes, flags=re.IGNORECASE)
    if note_match:
        note_subcategory = _safe_text(note_match.group(1)).strip()
        if note_subcategory:
            return note_subcategory
    
    return ''  # Empty = uncategorized
```

### Category Column Mapping (FIXED):
```python
# Fetch root categories from DB ordered by sort_order
root_cats = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
cat_names = [c.name for c in root_cats]
category_by_id_map = {c.id: c for c in root_cats}

# Map expense to column index
def _get_category_column_index(category_name, cat_names):
    if not category_name:
        return 0
    category_lower = category_name.lower().strip()
    for i, name in enumerate(cat_names):
        if name.lower() == category_lower:
            return i
    return 0  # Fallback to first column
```

### Expense Grouping (SAME AS FRONTEND):
```python
def _group_expenses_by_subcategory(expenses):
    """Group expenses by subcategory, same as frontend Flutter"""
    groups = {}
    uncategorized = []
    
    for e in expenses:
        subcat = _expense_subcategory_label(e).strip()
        if not subcat:
            uncategorized.append(e)
        else:
            if subcat not in groups:
                groups[subcat] = []
            groups[subcat].append(e)
    
    # Sort subcategories A-Z
    sorted_subcats = sorted(groups.keys(), key=lambda x: x.lower())
    
    return {
        'groups': {subcat: groups[subcat] for subcat in sorted_subcats},
        'uncategorized': uncategorized,
    }
```

## Expected Output Structure

### Single Expenses Section (Row 41+):
```
Row 41: [Accommodation] <- subcategory header (bold)
Row 42: 07-Mar-24 | 1 | Laundry 30 days... | Rp 1.500.000 | ...
Row 43: 
Row 44: [Allowance] <- subcategory header (bold)
Row 45: 07-Mar-24 | 2 | Tunjangan Lapangan... | Rp 11.705.250 | ...
Row 46:
Row 47: [Logistic] <- subcategory header (bold)
Row 48: 02-Feb-24 | 3 | Safety Shoes | Rp 499.940 | ...
...
```

### Batch Expenses Section:
```
Row XX: Expense#1 : ALFA TLJ-58 (...) <- batch header (blue fill)
Row XX+1: [Accommodation] <- subcategory header (bold)
Row XX+2: 07-Mar-24 | 1 | Laundry 30 days... | Rp 1.500.000 | ...
Row XX+3: [Allowance] <- subcategory header (bold)
Row XX+4: 07-Mar-24 | 2 | Tunjangan Lapangan... | Rp 11.705.250 | ...
...
```

### Total Row:
```
Row YY: TOTAL | | | Rp XXX.XXX | ... | [Cat1 Total] | [Cat2 Total] | ...
```

## Testing Checklist

- [ ] Single expenses grouped by subcategory A-Z
- [ ] Batch expenses grouped by settlement, then subcategory A-Z
- [ ] Category columns match Kategori Tabular order
- [ ] Total row shows correct totals per category
- [ ] No template dependency issues
- [ ] Export matches frontend display 100%
