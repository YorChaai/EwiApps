# 🧠 ANALISIS BUG, REDUNDANSI & PERFORMA - BACKEND & DATABASE

**Tanggal Analisis:** 19 April 2026
**Fokus:** Performa Database, Redundansi Logic, dan Skalabilitas.

---

## 🔴 CRITICAL SEVERITY

### 1. Database Indexing - Performance Bottleneck
**Temuan:** Tidak ada index eksplisit di `models.py` untuk foreign keys dan kolom pencarian utama.
**Dampak:** Saat data mencapai ribuan baris, query pencarian (search) dan filter (status, year) akan menjadi sangat lambat (Full Table Scan).
**Rekomendasi:** Tambahkan `index=True` pada:
- `Category.parent_id`, `Category.status`
- `Advance.user_id`, `Advance.status`
- `Settlement.user_id`, `Settlement.status`, `Settlement.advance_id`
- `Expense.settlement_id`, `Expense.category_id`

### 2. Manual Column Management in `app.py`
**Temuan:** Banyak fungsi `ensure_..._column` di `app.py` yang melakukan manipulasi skema secara manual (raw SQL).
**Dampak:** Redundansi tinggi karena aplikasi sudah menggunakan `Flask-Migrate`. Jika skema di database berbeda dengan model SQLAlchemy, aplikasi bisa crash.
**Rekomendasi:** Hapus semua fungsi `ensure_` manual dan gunakan `flask db migrate` secara disiplin untuk semua perubahan skema.

---

## 🟠 HIGH SEVERITY

### 3. Circular Dependency Risk in `seed_data`
**Temuan:** `seed_data()` di `app.py` memanggil model `Category` sebelum migrasi dipastikan selesai.
**Dampak:** Seperti yang terjadi sebelumnya, aplikasi gagal start jika ada kolom baru yang belum ada di database fisik tapi sudah diakses oleh model.
**Rekomendasi:** Pindahkan logic seeding ke script terpisah atau bungkus dalam blok `try-except` yang lebih aman.

### 4. Sequential API Execution
**Temuan:** Banyak endpoint yang melakukan query database secara berurutan dalam loop (N+1 query).
**Dampak:** Response time API melambat secara eksponensial seiring bertambahnya data.
**Rekomendasi:** Gunakan `.options(joinedload(...))` atau `subqueryload` di SQLAlchemy untuk mengambil relasi data dalam satu query.

---

## 🟡 MEDIUM SEVERITY

### 5. Data Integrity - Orphaned Records
**Temuan:** Beberapa relasi foreign key belum menggunakan `ondelete='CASCADE'`.
**Dampak:** Potensi data sampah (data yang merujuk ke ID yang sudah dihapus) atau error `IntegrityError` yang tidak ditangani dengan baik di UI.
**Rekomendasi:** Audit kembali semua relasi di `models.py` dan pastikan behavior penghapusan sudah tepat.

### 6. Redundant JSON Parsing
**Temuan:** Di `routes/expenses.py`, parsing `category_ids` dilakukan berulang kali.
**Dampak:** Sedikit beban CPU ekstra dan kode menjadi sulit dibaca.
**Rekomendasi:** Buat helper utility untuk parsing parameter JSON dari form-data.

---

## 🟢 LOW SEVERITY

### 7. Code Bloat - `app.py`
**Temuan:** `app.py` memiliki >800 baris kode karena mencampur inisialisasi app, helper migrasi, dan data seeding.
**Dampak:** Sulit untuk di-debug dan dipelihara.
**Rekomendasi:** Pecah `app.py` menjadi modul-modul kecil (misal: `database_utils.py`, `seeding.py`).

### 8. Hardcoded Strings
**Temuan:** Status seperti 'approved', 'pending', 'draft' tersebar di banyak file.
**Dampak:** Jika ada perubahan nama status, berisiko ada yang terlewat.
**Rekomendasi:** Gunakan Enum atau Class Constants untuk mendefinisikan status.

---

## 🚀 PERFORMANCE STATS (PREDICTION)

| Component | Status | Note |
|-----------|--------|------|
| **Query Speed** | ⚠️ Risky | Butuh Indexing segera. |
| **Start-up Time** | ⚠️ Slow | Terhambat banyak pengecekan kolom manual. |
| **API Throughput** | ✅ Good | Flask-CORS dan JWT sudah terimplementasi dengan baik. |
| **Memory Usage** | ✅ Efficient | SQLite cocok untuk beban kerja saat ini. |
