# 📋 FIX - Table Range Extension

**Masalah:**
1. Table selection hanya single expense (tidak sampai batch)
2. Border hitam hanya sampai single (tidak sampai batch)
3. Row biru berantakan (karena bukan bagian dari table)
4. TOTAL row tidak ada di akhir

**Root Cause:**
- Template Excel punya **table range hardcoded** (misal: A1:Q61)
- Batch expense di-render di **luar table range** (row 97+)
- Format table (border, fill) tidak apply ke luar table range

**Solusi:**
1. **Extend table range** programmatically setelah semua rendering selesai
2. **Apply table style** ke seluruh range (single + batch + total)
