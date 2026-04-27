# Rewrite Annual Excel Generation — Fix Ghost Data & Table Collisions

## Background

File `annual.py` (~3222 lines) generates a multi-table Excel report using an `.xlsx` template. The template has **fixed reference rows** at positions 23–41 that contain styling/headers for Tax and Expense tables. When revenue data exceeds ~15 rows, it **overwrites these template rows**, causing:

1. **Ghost data** — old template values bleed into the output
2. **Table collisions** — Tax & Expense sections lose their headers/separators because `_copy_template_row()` reads from already-overwritten source rows
3. **Tax hard-capped at 10 rows** — only 10 taxes ever rendered

## Root Cause

```
Template layout (rows 8–41):
  Row 8-22:   Revenue data (14 slots)
  Row 23:     Separator ←─── template source
  Row 24-26:  Tax title + headers ←─── template source
  Row 27-37:  Tax data (10 slots) + total ←─── template source
  Row 38-41:  Expense gap + title + header + data ←─── template source
```

When there are 300+ revenues, rows 8–307 are filled with revenue data, **destroying rows 23-41**. Later, `_copy_template_row(ws, 24, tax_title_row)` copies from a row that's now filled with revenue data → broken headers.

## Proposed Changes

> [!IMPORTANT]
> This is a **surgical rewrite** of the Excel generation section only (lines ~2747–3190). The business logic (`_build_annual_payload_from_db`, `_render_expense_section_from_data`, `_sync_formatted_secondary_sheets`, helpers) stays **untouched**.

### Strategy: Backup Template Rows to Hidden Sheet

Before clearing or writing any data:
1. Copy rows 23–41 (all template source rows) into a hidden `_tpl` sheet
2. Clear the entire data area (rows 8 to max_row) safely
3. All `_copy_template_row()` calls read from `_tpl` sheet instead of `ws`
4. At the end, delete the `_tpl` sheet

---

### [MODIFY] [annual.py](file:///d:/2.%20Organize/1.%20Projects/MiniProjectKPI_EWI/backend/routes/reports/annual.py)

#### Change 1: Add `_copy_template_row_from_backup()` helper (~line 215)

New function that copies from a **backup worksheet** instead of the main worksheet. This is the core fix — all template copies use this function.

```python
def _copy_template_row_from_backup(ws_backup, ws_target, source_row, target_row, ...):
    # Same logic as _copy_template_row but reads from ws_backup, writes to ws_target
```

#### Change 2: Rewrite Excel generation setup (lines ~2747–2810)

**Before clearing:**
- Create hidden `_tpl` backup sheet
- Copy rows 23–41 from `ws` to `_tpl` (values + styles + merges)

**Clearing:**
- Single `_clear_range_force(ws, 8, max(ws.max_row, 700), 2, 17)` — safe because templates are backed up

#### Change 3: Replace all `_copy_template_row(ws, TEMPLATE_ROW, ...)` calls (lines ~2896–3085)

Replace every call like:
```python
_copy_template_row(ws, REVENUE_SEPARATOR_TEMPLATE_ROW, revenue_gap_row, ...)
_copy_template_row(ws, TAX_TITLE_TEMPLATE_ROW, tax_title_row, ...)
```
With:
```python
_copy_template_row_from_backup(ws_backup, ws, REVENUE_SEPARATOR_TEMPLATE_ROW, revenue_gap_row, ...)
_copy_template_row_from_backup(ws_backup, ws, TAX_TITLE_TEMPLATE_ROW, tax_title_row, ...)
```

~12 call sites total.

#### Change 4: Remove 10-row tax cap (already done, keep it)

```diff
-visible_tax_rows = max(1, min(len(taxes), 10))
+visible_tax_rows = max(1, len(taxes))
-for idx, t in enumerate(taxes[:10]):
+for idx, t in enumerate(taxes):
```

#### Change 5: Cleanup — delete `_tpl` sheet before save (line ~3190)

```python
if backup_sheet_name in wb.sheetnames:
    del wb[backup_sheet_name]
```

---

### helpers.py — No Changes Needed

`helpers.py` (674 lines) contains pure utility functions (`_clear_range_force`, `_safe_set_cell`, `_to_float`, etc.) that are **not affected** by this change. No modifications needed.

## Open Questions

> [!NOTE]
> Saat ini kode backup sudah mulai di-edit tapi belum selesai. Apakah kamu mau saya:
> 1. **Lanjut dari annual.py yang sekarang** — apply backup-sheet strategy ke kode yang sudah di-edit (incremental fix)
> 2. **Reset dari backup, lalu apply clean** — copy `annual (backup).py` → `annual.py`, lalu apply semua fix dari awal

Opsi 1 lebih cepat. Opsi 2 lebih bersih tapi perlu re-apply semua fix yang sudah ada.

## Verification Plan

### Automated Tests
```bash
python -c "import py_compile; py_compile.compile('backend/routes/reports/annual.py', doraise=True)"
```

### Manual Verification
1. Generate Excel with **< 15 revenue** rows → verify tables stay at original template positions
2. Generate Excel with **300+ revenue** rows → verify:
   - Revenue total row appears correctly
   - Tax section has proper separator, title "PAJAK PENGELUARAN", and column headers
   - All tax rows render (not capped at 10)
   - Expense section has proper separator, title "PENGELUARAN", and column headers
   - No ghost data between tables
3. Generate Excel with **2000+ revenue + 200+ tax** → same checks
