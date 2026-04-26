# PLAN FITUR: TOGGLE TAB SETTLEMENT & KASBON + ANTISIPASI PERFORMA DATA BESAR
**Project:** MiniProjectKPI_EWI
**Scope:** Settlement List (`dashboard_screen.dart`) & Kasbon/Advance List (`advances_screen.dart`)
**Last Updated:** 2026-04-24

---

## 📝 CHANGE LOG

- **2026-04-24** — Dokumen pertama kali dibuat. Berisi plan fitur toggle tab dan catatan performa data besar.

---

## 🛠 QUICK FIX MATRIX

| Masalah | Cek Cepat | Solusi Cepat |
|---|---|---|
| List lag saat data besar | Cek apakah pakai `ListView.builder` atau list statis | Pastikan pakai `ListView.builder`, aktifkan pagination backend |
| Header `Pengeluaran Sendiri` tidak responsif | Masih berupa teks statis | Ubah ke toggle button |
| Default tampil batch padahal harusnya single | Cek nilai awal state toggle | Set default `_selectedTab = 'single'` |
| Data batch ikut muncul saat tab single aktif | Filter list belum terhubung ke tab | Filter `settlements` berdasarkan `settlement_type == selectedTab` |

---

## 🔎 RINGKASAN CEPAT (WAJIB BACA DULU)

### A) Status saat ini
- List settlement saat ini **menampilkan single dan batch sekaligus** dalam satu list dengan pemisah header teks.
- Header `Pengeluaran Sendiri (56)` dan `Pengeluaran Batch (...)` hanya **label statis**, bukan tombol interaktif.
- Belum ada **pagination** — data diambil sekaligus dari backend tanpa batasan halaman.

### B) Potensi masalah kalau data 10.000+
- Flutter `ListView.builder` secara teknis aman untuk data besar karena lazy render.
- **Yang berbahaya** adalah jika backend mengembalikan 10.000+ item sekaligus dalam satu response JSON → parsing + deserialize berat di Flutter + jaringan lambat.
- Saat ini **belum ada pagination backend**, jadi ini adalah risiko nyata jika data tumbuh besar.

### C) Fitur yang perlu dibangun
1. **Toggle Tab: "Pengeluaran Sendiri" vs "Pengeluaran Batch"** — berlaku di Settlement dan Kasbon.
2. **Pagination Backend + Frontend** (opsional tapi sangat disarankan untuk skalabilitas).

---

## 1) Fitur Toggle Tab (PRIORITAS UTAMA)

### 1.1 Deskripsi Fitur
Mengganti header statis menjadi dua **toggle button** interaktif:
- `Pengeluaran Sendiri` (default aktif)
- `Pengeluaran Batch`

Saat user klik salah satu tab, list di bawahnya langsung berganti menampilkan data sesuai tipe.

---

### 1.2 Tampilan yang Diinginkan

```
[ Pengeluaran Sendiri ]  [ Pengeluaran Batch ]
────────────────────────────────────────────
 ALFA Service PDP-075...  Rp 29.640.916  >
 ALFA Service PDS-01ST... Rp 29.640.916  >
 ...
```

- Tab aktif: outline bold / background berbeda
- Tab tidak aktif: outline tipis / background netral
- Default: **Pengeluaran Sendiri** selalu aktif pertama kali dibuka

---

### 1.3 Lokasi Perubahan

| Screen | File | Lokasi |
|---|---|---|
| Settlement | `frontend/lib/screens/dashboard_screen.dart` | `_SettlementListViewState` |
| Kasbon | `frontend/lib/screens/advance/advances_screen.dart` | `AdvancesScreenState` |

---

### 1.4 Perubahan Frontend (Settlement)

**State yang perlu ditambahkan:**
```dart
String _selectedType = 'single'; // default single
```

**Widget toggle yang perlu dibuat:**
```dart
Widget _buildTypeToggle() {
  return Row(
    children: [
      _toggleButton('single', 'Pengeluaran Sendiri'),
      const SizedBox(width: 8),
      _toggleButton('batch', 'Pengeluaran Batch'),
    ],
  );
}

Widget _toggleButton(String type, String label) {
  final isActive = _selectedType == type;
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      backgroundColor: isActive ? AppTheme.primary : Colors.transparent,
      foregroundColor: isActive ? Colors.white : AppTheme.primary,
      side: BorderSide(color: AppTheme.primary),
    ),
    onPressed: () => setState(() => _selectedType = type),
    child: Text(label),
  );
}
```

**Filter list yang perlu disesuaikan:**
```dart
final filtered = prov.settlements
    .where((s) => (s['settlement_type'] ?? 'single') == _selectedType)
    .toList();
```

**Hapus / nonaktifkan header statis `__header_single__` dan `__header_batch__`.**

---

### 1.5 Perubahan Frontend (Kasbon)

Sama persis dengan Settlement, bedanya:
- State di `AdvancesScreenState`
- List yang difilter dari `AdvanceProvider`
- Apakah kasbon punya konsep single/batch perlu dicek dulu di backend

---

### 1.6 Default Tab

| Screen | Default |
|---|---|
| Settlement | `single` (Pengeluaran Sendiri) |
| Kasbon | `single` (kalau ada konsep batch-nya) |

---

### 1.7 Checklist Implementasi Toggle

- [ ] Tambah state `_selectedType = 'single'` di Settlement
- [ ] Tambah state `_selectedType = 'single'` di Kasbon (jika berlaku)
- [ ] Buat widget `_buildTypeToggle()`
- [ ] Pasang toggle di atas list, di bawah filter status
- [ ] Filter list berdasarkan `_selectedType`
- [ ] Hapus header statis `__header_single__` dan `__header_batch__`
- [ ] Reset `_selectedType` ke `single` saat reload/refresh
- [ ] Uji di mobile dan desktop

---

## 2) Potensi Lag Data Besar (ANTISIPASI PERFORMA)

### 2.1 Kondisi Saat Ini

| Komponen | Kondisi | Risiko |
|---|---|---|
| Flutter `ListView.builder` | Sudah dipakai | Aman (lazy render) |
| Pagination backend | **Belum ada** | Risiko tinggi jika data > 1000 |
| Filter/search | Ada (frontend filter) | Kurang optimal jika data besar |
| Cache provider | Ada sebagian | Perlu dikembangkan |

---

### 2.2 Estimasi Batas Aman

| Jumlah Data | Status |
|---|---|
| < 500 item | Aman, performa normal |
| 500 – 2000 item | Mulai terasa, tapi masih OK |
| 2000 – 5000 item | Perlu pagination atau lazy load |
| > 5000 item | **Wajib pagination**, risk crash/timeout |

---

### 2.3 Rencana Pagination (Jika Dibutuhkan)

#### Backend (Python/Flask)
Tambahkan parameter `page` dan `per_page` di endpoint:
```
GET /api/settlements?page=1&per_page=20&type=single&status=all
```

Response tambahan:
```json
{
  "data": [...],
  "total": 1050,
  "page": 1,
  "per_page": 20,
  "total_pages": 53
}
```

#### Frontend (Flutter)
- Tambah state `_currentPage = 1`
- Load data saat scroll mendekati bawah (`ScrollController` listener)
- Append data baru ke list yang sudah ada (infinite scroll)
- Tampilkan indikator loading di bawah list saat fetch halaman baru

---

### 2.4 Alternatif Lebih Ringan (Sebelum Full Pagination)

Jika tidak ingin pagination penuh dulu, opsi sementara:
1. **Batasi default load**: backend hanya kirim 100 item terbaru, ada tombol "Muat Lebih".
2. **Search wajib sebelum list muncul**: tapi ini mengubah UX.
3. **Filter ketat by year**: sudah ada, pertahankan dan pastikan selalu aktif.

---

### 2.5 Checklist Antisipasi Performa

- [ ] Pastikan semua list settlement/kasbon pakai `ListView.builder`
- [ ] Pastikan `itemExtent` diset jika tinggi item konsisten (lebih efisien)
- [ ] Pastikan `cacheExtent` di-set untuk pre-render item di luar viewport
- [ ] Tambahkan pagination backend (jika data mulai besar)
- [ ] Filter `year` selalu aktif sebagai pembatas default
- [ ] Monitor response time API jika data tumbuh

---

## 3) Urutan Pengerjaan yang Disarankan

```
1. Implementasi Toggle Tab (Settlement dulu, lalu Kasbon)
2. Uji di data normal (< 200 item)
3. Uji di data simulasi besar (mock 1000+ item)
4. Evaluasi: apakah perlu pagination?
5. Jika ya → implementasi pagination backend dulu, baru frontend
6. Update dokumen ini setelah selesai
```

---

## 4) Catatan Khusus Kasbon (Advance)

Sebelum implementasi toggle di Kasbon, perlu dikonfirmasi:
1. Apakah kasbon/advance punya tipe `single` dan `batch` seperti settlement?
2. Jika ya, field apa di model `Advance` yang membedakannya?
3. Jika tidak ada konsep batch di kasbon, toggle di Kasbon tidak diperlukan.

---

## 5) Referensi File Terkait

| File | Keterangan |
|---|---|
| `frontend/lib/screens/dashboard_screen.dart` | List Settlement utama |
| `frontend/lib/screens/advance/advances_screen.dart` | List Kasbon/Advance |
| `frontend/lib/providers/settlement_provider.dart` | State management settlement |
| `frontend/lib/providers/advance_provider.dart` | State management kasbon |
| `backend/routes/settlements.py` | Endpoint backend settlement |
| `backend/routes/advances.py` | Endpoint backend kasbon |

---

## 6) Penutup

Fitur toggle ini relatif **ringan di sisi implementasi** karena datanya sudah ada di provider (hanya perlu filter). Yang lebih berat adalah antisipasi performa jika data tumbuh besar — itu butuh koordinasi backend + frontend.

Disarankan kerjakan **toggle dulu** karena manfaat UX langsung terasa, baru pagination jika mulai ada keluhan performa.


Sudah saya buatkan dokumen plan baru ✅

File baru:
- `MiniProjectKPI_EWI/panduan/PLAN_FITUR_TOGGLE_SETTLEMENT_DAN_PERFORMA.md`

---

Isi lengkapnya:

### A) Tentang potensi lag data 10.000+
- `ListView.builder` Flutter sendiri **aman** (lazy render)
- **Yang berbahaya** adalah backend kirim semua sekaligus tanpa pagination
- Saya kasih **tabel estimasi batas aman** (< 500 aman, > 5000 wajib pagination)
- Ada rencana pagination backend + frontend kalau dibutuhkan nanti

### B) Plan toggle "Pengeluaran Sendiri" vs "Pengeluaran Batch"
- State yang perlu ditambah
- Widget toggle button siap pakai
- Filter list berdasarkan tab aktif
- Default selalu **Pengeluaran Sendiri**
- Berlaku di **Settlement** dan **Kasbon** (dengan catatan konfirmasi dulu apakah kasbon punya konsep batch)

### C) Urutan pengerjaan yang disarankan
- Toggle dulu → uji → baru evaluasi perlu pagination atau tidak

---

Kalau kamu mau saya langsung **implementasi toggle-nya** sekarang di kode, tinggal bilang saja.
