# 🧪 Testing Plan - Kategori Dinamis Laporan Tahunan

**Tanggal:** 29 Maret 2026  
**File yang Diubah:** `frontend/lib/screens/annual_report_screen.dart`  
**Status:** ✅ **SIAP TEST**

---

## 🔧 **Perubahan yang Dilakukan:**

### **1. Fetch Kategori dari API**
```dart
Future<void> _fetchCategories() async {
  final res = await api.getCategories();
  // Backend return: {'categories': [...]}
  if (res.containsKey('categories')) {
    // Sort by sort_order
    _categories = cats;
  }
}
```

### **2. Ganti Hardcoded Headers dengan Dinamis**
```dart
// SEBELUM:
final catHeaders = ['Biaya Operasi', 'Research', ...]; // hardcoded

// SEKARANG:
final catHeaders = _categories.isNotEmpty
    ? _categories.map((c) => c['name']).toList() // dinamis dari API
    : ['Biaya Operasi', 'Research', ...]; // fallback
```

### **3. Mapping Expense ke Kategori Dinamis**
```dart
// SEBELUM:
final idx = _expenseCategoryIndex(categoryName); // hardcoded

// SEKARANG:
final idx = _getCategoryIndexFromDynamic(categoryName); // dinamis
```

---

## ✅ **Cara Testing:**

### **Test 1: Kategori Existing (9 kategori lama)**

**Langkah:**
1. Buka aplikasi → **Laporan Tahunan**
2. Pilih tahun (misal 2024/2026)
3. Lihat **Tabel 3: PENGELUARAN & OPERATION COST**

**Expected Result:**
- ✅ Kolom kategori masih muncul (Biaya Operasi, Research, Sewa Alat, dll)
- ✅ Urutan sesuai dengan yang ada di **Kategori Tabular**
- ✅ Data expense masuk ke kolom yang benar

**Jika GAGAL:**
- ❌ Masih pakai fallback (hardcoded)
- ❌ API call gagal atau response format salah

---

### **Test 2: Kategori Baru (YANG PENTING!)**

**Langkah:**
1. Buka **Kategori Tabular**
2. **Buat kategori baru** (misal: "Marketing & Promosi")
3. Atur posisinya (misal: setelah "Bisnis Dev")
4. Klik **Simpan**
5. Buka **Laporan Tahunan**
6. Refresh/reload halaman
7. Lihat **Tabel 3**

**Expected Result:**
- ✅ Kategori baru "Marketing & Promosi" **OTOMATIS MUNCUL** di kolom
- ✅ Urutan sesuai yang diatur di Kategori Tabular
- ✅ Expense dengan kategori ini masuk ke kolom yang benar

**Jika GAGAL:**
- ❌ Kategori baru tidak muncul = masih pakai fallback
- ❌ Urutan salah = sort_order tidak dibaca

---

### **Test 3: Ubah Urutan Kategori**

**Langkah:**
1. Buka **Kategori Tabular**
2. **Ubah urutan** (misal: "Research" pindah ke posisi 1, "Biaya Operasi" ke posisi 2)
3. Klik **Simpan**
4. Buka **Laporan Tahunan**
5. Refresh/reload halaman
6. Lihat **Tabel 3**

**Expected Result:**
- ✅ Urutan kolom **BERUBAH** sesuai Kategori Tabular
- ✅ Research sekarang di kolom pertama
- ✅ Biaya Operasi di kolom kedua

**Jika GAGAL:**
- ❌ Urutan masih sama = sort_order tidak dibaca
- ❌ Masih pakai hardcoded fallback

---

### **Test 4: Hapus Kategori**

**Langkah:**
1. Buka **Kategori Tabular**
2. **Hapus kategori** (jika ada yang bisa dihapus)
3. Simpan
4. Buka **Laporan Tahunan**
5. Refresh

**Expected Result:**
- ✅ Kategori yang dihapus **TIDAK MUNCUL** lagi di Tabel 3

---

## 🐛 **Troubleshooting:**

### **Masalah 1: Kategori Baru Tidak Muncul**

**Kemungkinan Penyebab:**
1. API call gagal
2. Response format tidak match
3. `_categories` masih empty

**Cara Cek:**
```dart
// Tambahkan debug print di _fetchCategories:
print('DEBUG: Fetch categories...');
print('DEBUG: Response = $res');
print('DEBUG: Categories count = ${_categories.length}');
```

**Solusi:**
- Cek console/log apakah ada error
- Cek network tab di DevTools apakah API return `{'categories': [...]}`

---

### **Masalah 2: Urutan Tidak Sesuai**

**Kemungkinan Penyebab:**
1. `sort_order` tidak dibaca dari API
2. Sort logic salah

**Cara Cek:**
- Print `sort_order` value dari setiap kategori
- Pastikan ascending order (1, 2, 3, ...)

---

### **Masalah 3: Expense Masuk Kolom Salah**

**Kemungkinan Penyebab:**
1. `_getCategoryIndexFromDynamic()` tidak match nama kategori
2. Nama kategori di expense beda dengan di `_categories`

**Cara Cek:**
```dart
// Tambahkan debug di _getCategoryIndexFromDynamic:
print('DEBUG: Looking for category = $categoryName');
print('DEBUG: Found at index = $idx');
print('DEBUG: Categories = ${_categories.map((c) => c['name']).toList()}');
```

---

## 📊 **Checklist Testing:**

| Test | Status | Notes |
|------|--------|-------|
| Kategori existing (9 lama) | ⬜ Pending | |
| Kategori baru muncul otomatis | ⬜ Pending | **YANG PENTING!** |
| Urutan sesuai Kategori Tabular | ⬜ Pending | |
| Expense masuk kolom benar | ⬜ Pending | |
| Hapus kategori tidak muncul lagi | ⬜ Pending | |

---

## 🎯 **Kriteria Sukses:**

✅ **LULUS** jika:
1. Kategori baru **otomatis muncul** di Laporan Tahunan
2. Urutan kolom **sesuai** dengan Kategori Tabular
3. Expense masuk ke **kolom yang benar**
4. Tidak ada error di console/log

❌ **GAGAL** jika:
1. Kategori baru **tidak muncul** = masih pakai fallback
2. Urutan **tidak sesuai** = sort_order tidak dibaca
3. Ada **error** di console

---

## 📝 **Fallback Behavior:**

Jika API gagal atau `_categories` empty, maka:
- ✅ Pakai hardcoded list sebagai fallback
- ✅ Aplikasi tetap jalan (tidak crash)
- ❌ Tapi kategori baru tidak akan muncul

**Ini expected behavior** - fallback hanya untuk safety, tapi seharusnya tidak dipakai jika API berhasil.

---

**Dibuat oleh:** AI Assistant  
**Untuk:** MiniProjectKPI_EWI - Fix Kategori Dinamis  
**Status:** ✅ **SIAP TEST**
