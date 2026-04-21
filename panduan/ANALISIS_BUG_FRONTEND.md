# 📱 ANALISIS BUG, REDUNDANSI & PERFORMA - FRONTEND (FLUTTER)

**Tanggal Analisis:** 19 April 2026
**Fokus:** File Bloat, Kinerja Scrolling, dan Konsistensi Kode.

---

## 🔴 CRITICAL SEVERITY

### 1. Massive File Sizes (Maintenance Nightmare)
**Temuan:** Beberapa file screen memiliki ribuan baris kode:
- `settlement_detail_screen.dart`: **3.082 baris**
- `advance_detail_screen.dart`: **2.932 baris**
- `dashboard_screen.dart`: **1.679 baris**
**Dampak:** Perubahan kecil di satu bagian berisiko tinggi merusak bagian lain (Regresi). IDE menjadi lambat saat mengedit file ini.
**Rekomendasi:** Lakukan refactoring segera. Pecah widget besar menjadi widget-widget kecil di file terpisah (misal: `widgets/settlement_header.dart`).

---

## 🟠 HIGH SEVERITY

### 2. ListView Performance - Missing `itemExtent`
**Temuan:** `ListView.builder` di dashboard dan list screen belum menggunakan `itemExtent`.
**Dampak:** Flutter harus menghitung tinggi setiap item secara dinamis saat di-scroll, yang menyebabkan **frame drop (lag)** pada list yang panjang.
**Rekomendasi:** Tambahkan `itemExtent` (misal: `itemExtent: 120.0`) jika tinggi card sudah pasti.

### 3. Sequential API Calls in `initState`
**Temuan:** Banyak screen melakukan 3-4 API calls secara berurutan (`await call1(); await call2();`).
**Dampak:** Waktu loading screen menjadi akumulatif (lama). User melihat spinner terlalu lama.
**Rekomendasi:** Gunakan `Future.wait([call1(), call2()])` untuk menjalankan request secara paralel.

---

## 🟡 MEDIUM SEVERITY

### 4. Repeated `Theme.of(context)` Calls
**Temuan:** Kode memanggil `Theme.of(context)` berkali-kali di dalam metode `build`.
**Dampak:** Sedikit overhead performa karena Flutter harus mencari data tema di setiap panggilan.
**Rekomendasi:** Simpan hasil pencarian di variabel lokal di awal `build` (misal: `final theme = Theme.of(context);`).

### 5. Inconsistent Debounce on Search
**Temuan:** Fitur pencarian di beberapa screen langsung menembak API di setiap ketikan huruf, sementara yang lain sudah ada debounce.
**Dampak:** Beban server (Backend) meningkat tajam saat user mengetik cepat.
**Rekomendasi:** Standardisasi penggunaan `EasyDebounce` atau Timer di semua input pencarian.

---

## 🟢 LOW SEVERITY

### 6. Missing Tooltips & Accessibility
**Temuan:** Masih ada tombol-tombol icon (`IconButton`) yang tidak memiliki `tooltip`.
**Dampak:** Pengalaman pengguna (UX) berkurang bagi pengguna baru yang tidak tahu fungsi icon tersebut.
**Rekomendasi:** Tambahkan properti `tooltip` di setiap `IconButton`.

### 7. String Concatenation in Loops
**Temuan:** Masih ada beberapa bagian di `api_service.dart` yang merangkai URL menggunakan `+=`.
**Dampak:** Kurang efisien dalam penggunaan memori jika string yang dirangkai sangat panjang.
**Rekomendasi:** Gunakan `StringBuffer` untuk performa manipulasi string yang lebih baik.

---

## 🚀 PERFORMANCE STATS (PREDICTION)

| Component | Status | Note |
|-----------|--------|------|
| **Frame Rate (FPS)** | ⚠️ Unstable | Terganggu oleh list panjang tanpa itemExtent. |
| **Memory Consumption**| ⚠️ High | Bloated widget tree karena file terlalu besar. |
| **Initial Load** | ⚠️ Average | Bisa ditingkatkan dengan Parallel API calls. |
| **Asset Loading** | ✅ Good | Penanganan gambar sudah cukup baik. |
