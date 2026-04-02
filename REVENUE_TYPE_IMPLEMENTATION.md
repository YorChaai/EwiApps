# Implementasi Revenue Type Differentiation

## Overview
Implementasi pembedaan antara **PENDAPATAN LANGSUNG** dan **PENDAPATAN LAIN LAIN** pada sistem revenue, mirip dengan differentiation yang sudah ada di Table 3 (Batch vs Single).

## Perubahan yang Dilakukan

### 1. Database Layer

#### File: `backend/models.py`
- ✅ Menambahkan kolom `revenue_type` (VARCHAR(32)) ke model `Revenue`
- ✅ Default value: `'pendapatan_langsung'`
- ✅ Index untuk performa query yang lebih baik
- ✅ Menambahkan konstanta kelas:
  - `REVENUE_DIRECT = 'pendapatan_langsung'`
  - `REVENUE_OTHER = 'pendapatan_lain_lain'`
- ✅ Menambahkan method helper `normalize_revenue_type()` untuk validasi input
- ✅ Update `to_dict()` untuk include `revenue_type`

#### File: `backend/migrate_add_revenue_type.py`
- ✅ Script migration untuk menambahkan kolom ke database
- ✅ Otomatis set default value untuk data existing
- ✅ Include verification step

### 2. Backend API Layer

#### File: `backend/routes/revenues.py`
- ✅ Update endpoint `POST /api/revenues` untuk accept `revenue_type`
- ✅ Update endpoint `PUT /api/revenues/<id>` untuk update `revenue_type`
- ✅ Validasi: `revenue_type` harus `'pendapatan_langsung'` atau `'pendapatan_lain_lain'`
- ✅ Normalisasi input menggunakan `Revenue.normalize_revenue_type()`

### 3. Frontend Layer (Flutter)

#### File: `frontend/lib/screens/revenue_management_screen.dart`
- ✅ Menambahkan helper widget `_dropdownField()` untuk dropdown input
- ✅ Menambahkan dropdown "Revenue" di form tambah/edit revenue
- ✅ Opsi dropdown:
  - `PENDAPATAN LANGSUNG` → value: `'pendapatan_langsung'`
  - `PENDAPATAN LAIN LAIN` → value: `'pendapatan_lain_lain'`
- ✅ Default selection: `PENDAPATAN LANGSUNG`
- ✅ Include `revenue_type` dalam payload saat create/update

### 4. Report Generation Layer

#### File: `backend/routes/reports/annual.py`

**Helper Function:**
- ✅ Menambahkan `_group_revenues_by_type()` untuk grouping revenue

**Excel Export:**
- ✅ Group header untuk setiap tipe revenue
- ✅ Data rows untuk setiap revenue dalam group
- ✅ Subtotal row untuk setiap group
- ✅ Grand total row di akhir
- ✅ Blank row separator antar groups

**PDF Export:**
- ✅ Same structure seperti Excel export
- ✅ Group header row
- ✅ Subtotal per group
- ✅ Grand total

## Struktur Tampilan

### Table 1: REVENUE & TAX (Excel & PDF)

```
=== PENDAPATAN LANGSUNG ===
Row 1: Revenue data processing MTD_Tomori
Row 2: ALFA Service PDP-075 Pertamina Zona#4
...
Subtotal Pendapatan Langsung                    [SUM]

=== PENDAPATAN LAIN LAIN ===
Row 1: Bunga Bank 2024
...
Subtotal Pendapatan Lain Lain                  [SUM]

REVENUE (IDR)                                   [GRAND TOTAL]
```

## Migration Steps

### Cara Menjalankan Migration

1. **Pastikan semua dependency terinstall:**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Jalankan migration script:**
   ```bash
   python migrate_add_revenue_type.py
   ```

3. **Verifikasi hasil migration:**
   - Script akan menampilkan distribusi revenue_type
   - Semua data existing akan memiliki `'pendapatan_langsung'` sebagai default

### Rollback (Jika Diperlukan)

```sql
-- Hapus kolom revenue_type
ALTER TABLE revenues DROP COLUMN revenue_type;

-- Hapus index
DROP INDEX IF EXISTS ix_revenues_revenue_type;
```

## Testing Checklist

### Backend Testing
- [ ] Create revenue dengan `revenue_type = 'pendapatan_langsung'`
- [ ] Create revenue dengan `revenue_type = 'pendapatan_lain_lain'`
- [ ] Update revenue: ganti `revenue_type`
- [ ] API validation: reject invalid `revenue_type` values
- [ ] GET revenue: verify `revenue_type` included in response

### Frontend Testing
- [ ] Form tambah revenue: dropdown muncul
- [ ] Default selection: PENDAPATAN LANGSUNG
- [ ] Switch ke PENDAPATAN LAIN LAIN
- [ ] Simpan dan verify data tersimpan dengan benar
- [ ] Edit revenue: dropdown show current value

### Report Testing
- [ ] Generate annual report Excel
- [ ] Verify group headers muncul
- [ ] Verify subtotal per group correct
- [ ] Verify grand total correct
- [ ] Generate annual report PDF
- [ ] Same structure seperti Excel

### Edge Cases
- [ ] Revenue dengan `revenue_type = NULL` → default ke `'pendapatan_langsung'`
- [ ] Empty group (semua revenue 1 tipe) → hanya show 1 group
- [ ] Data existing (before migration) → otomatis dapat default value

## API Examples

### Create Revenue

```json
POST /api/revenues
{
  "invoice_date": "2024-01-15",
  "description": "Revenue from project X",
  "invoice_value": 100000000,
  "currency": "IDR",
  "client": "Client A",
  "receive_date": "2024-02-15",
  "amount_received": 100000000,
  "revenue_type": "pendapatan_langsung"
}
```

### Update Revenue

```json
PUT /api/revenues/123
{
  "revenue_type": "pendapatan_lain_lain"
}
```

### Response

```json
{
  "id": 123,
  "invoice_date": "2024-01-15",
  "description": "Revenue from project X",
  ...
  "revenue_type": "pendapatan_langsung",
  ...
}
```

## Backward Compatibility

- ✅ Data existing otomatis dapat default value `'pendapatan_langsung'`
- ✅ API accept `revenue_type` optional (default ke `'pendapatan_langsung'`)
- ✅ `normalize_revenue_type()` handle various input formats
- ✅ Report tetap work jika ada revenue tanpa `revenue_type` (fallback ke default)

## Notes

1. **PENTING:** Migration HARUS dijalankan sebelum aplikasi digunakan
2. **RECOMMENDED:** Backup database sebelum migration
3. **TESTING:** Test di development environment dulu sebelum production
4. **MONITORING:** Monitor error logs setelah deployment untuk catch edge cases

## Files Modified

1. `backend/models.py` - Revenue model
2. `backend/routes/revenues.py` - API endpoints
3. `backend/routes/reports/annual.py` - Report generation
4. `frontend/lib/screens/revenue_management_screen.dart` - UI form

## Files Created

1. `backend/migrate_add_revenue_type.py` - Migration script
2. `backend/migrations/versions/add_revenue_type_to_revenues.sql` - SQL migration
3. `REVENUE_TYPE_IMPLEMENTATION.md` - This documentation

## Next Steps (Optional Enhancements)

- [ ] Add filter by revenue_type di UI
- [ ] Add statistics/dashboard per revenue_type
- [ ] Export separate reports per revenue_type
- [ ] Add validation rules (e.g., certain categories must be specific type)
