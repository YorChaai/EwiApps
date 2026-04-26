# PANDUAN FITUR KOTAK REPORT, CACHE, DAN SCROLLBAR  
**Project:** MiniProjectKPI_EWI  
**Scope:** Laporan Tahunan (`AnnualReportScreen`) & Laporan Summary (`ReportScreen`)  
**Path referensi utama:**  
- `frontend/lib/screens/reports/annual_report_screen.dart`  
- `frontend/lib/screens/reports/report_screen.dart`  
**Last Updated:** 2026-04-24

---

## 📝 CHANGE LOG SINGKAT (TERBARU)

- **2026-04-24**
  - Menambahkan **Ringkasan Cepat (Wajib Baca Dulu)** di bagian atas dokumen.
  - Menambahkan ringkasan status penting: sinkronisasi logika Summary vs Annual.
  - Menambahkan catatan tuning scrollbar agar gap kiri/bawah lebih rapi dan tidak menabrak teks.
  - Menambahkan section **Quick Fix Matrix** agar troubleshooting lebih cepat.

---

## 🛠 QUICK FIX MATRIX (MASALAH → CEK → SOLUSI CEPAT)

| Masalah | Cek Cepat | Solusi Cepat |
|---|---|---|
| Scrollbar kiri menabrak teks kolom pertama | Nilai `leftScrollbarSpace`, padding kiri list | Naikkan `leftScrollbarSpace` bertahap (`+1/+2`), tambah padding kiri kecil |
| Scrollbar horizontal menempel row terakhir | Padding bawah list, tinggi body | Tambah padding bawah kecil (`+2/+4`) atau naikkan `bodyHeight` sedikit |
| Kotak terlihat “terlalu masuk” / double border terasa dalam | Padding card + inset kiri scrollbar | Kurangi padding horizontal card atau kecilkan inset kiri |
| Scrollbar kiri terasa hilang | `thumbVisibility`, kontras warna, ketebalan | Naikkan `thickness`, tingkatkan kontras, aktifkan track bila perlu |
| Nilai kategori induk di Summary terlihat 0 padahal ada transaksi anak | Logika agregasi parent di backend summary | Pastikan parent = akumulasi anak + direct expense |
| Annual dan Summary terlihat beda total | Filter status & periode query backend | Samakan filter tahun/range/status, lalu bandingkan per kategori-bulan |
| Posisi scroll tidak reset saat ganti tahun | Reset controller saat reload/fetch | Pastikan seluruh controller `jumpTo(0)` saat data dimuat ulang |

---

## 🔎 RINGKASAN CEPAT (WAJIB BACA DULU)

## A) Status penting saat ini
1. **Summary**: logika kategori induk sudah menampilkan total riil (tidak dipaksa `0`).
2. **Annual Tabel 4**: aman dari bug induk `0`, karena menggunakan payload `operation_cost` terpisah.
3. **UI Scrollbar**: Summary sudah disesuaikan agar mendekati gaya Tahunan (ada gap tipis kiri & bawah agar tidak nabrak teks).

## B) Parameter paling sering diubah (quick tuning)
1. `leftScrollbarSpace` → jarak scrollbar kiri ke isi.
2. `thickness` scrollbar → visibilitas scrollbar.
3. `ListView padding` kiri/bawah → mencegah teks ketutup scrollbar.
4. `bodyHeight` / max height (`650/800`) → ruang tampil body table.
5. padding card (`6/10`, `8/12`) → kerapian “kotak dalam kotak”.

## C) Urutan cek cepat kalau ada bug visual
1. Cek scrollbar nabrak teks kolom pertama.
2. Cek scrollbar horizontal menempel row terakhir.
3. Cek kesan “kotak terlalu masuk / double border”.
4. Cek di 3 lebar layar: `<550`, `550–799`, `>=800`.
5. Cek tidak ada overflow/render error.

## D) Validasi data cepat (Summary vs Annual)
1. Bandingkan `Summary grand_total` dengan total biaya yang diharapkan.
2. Jika beda, cek perbedaan filter status data backend.
3. Pastikan kategori induk di Summary ikut akumulasi anak + direct expense.

---

## 1) Tujuan Dokumen

Dokumen ini menjelaskan secara lengkap fitur-fitur yang ada di **kotak laporan** (card/table container), termasuk:

1. Fitur konten di dalam kotak laporan
2. Mekanisme cache
3. Pengaturan ukuran responsif (mobile vs desktop)
4. Perilaku scrollbar (utama, horizontal, vertikal kiri)
5. Parameter ukuran penting (padding, ketebalan scrollbar, batas tinggi body table)
6. Checklist verifikasi manual

---

## 2) Ringkasan Arsitektur UI Report

## 2.1 Laporan Tahunan (`AnnualReportScreen`)
Menampilkan beberapa tabel di dalam kotak-kotak card:

- **Tabel 1: REVENUE & TAX**
- **Tabel 2: PAJAK**
- **Tabel 3: DIVIDEN**
- **Tabel 4: OPERATION COST**
- **Tabel 5: NERACA**

Komponen penting:
- Outer scroll halaman: `Scrollbar + SingleChildScrollView` (vertikal halaman)
- Inner table scroll:
  - Horizontal per tabel
  - Vertikal per tabel
  - Vertikal table diarahkan ke **kiri** untuk keterbacaan struktur data

---

## 2.2 Laporan Summary (`ReportScreen`)
Menampilkan 1 kotak summary tabel bulanan:
- Kolom: `Kategori`, `Jan..Des`, `TOTAL`
- Baris: daftar kategori + baris `GRAND TOTAL`

Komponen penting:
- Outer scroll halaman: vertikal
- Inner scroll table summary:
  - Horizontal untuk banyak kolom bulan
  - Vertikal data list
  - Indikator scrollbar vertikal kiri ditampilkan sebagai visual marker area data

---

## 3) Fitur di Dalam Kotak Laporan

## 3.1 Struktur Kotak (Card)
Setiap kotak tabel memiliki:
- Border + radius
- Header judul tabel
- Header kolom
- Body data dengan row bergaris
- Scrollbar horizontal & vertikal (sesuai jenis report)

### Parameter visual utama (Tahunan)
- `padding` card:
  - Mobile: horizontal `6`, vertical `8`
  - Desktop: horizontal `10`, vertical `12`
- Jarak judul ke tabel: `6`
- Border radius tabel: `8`
- Tinggi row:
  - Tabel umum: `52`
  - Tabel 4: `60`

---

## 3.2 Interaksi Navigasi Data
Pada Laporan Tahunan, tersedia tombol cepat ke modul:
- `Revenue`
- `Pajak`
- `Dividen`
- `Neraca`

Setelah kembali dari modul tersebut, data tahunan otomatis di-refresh.

---

## 4) Cache: Konsep dan Implementasi

## 4.1 Cache Data di Laporan Tahunan
Implementasi cache di `AnnualReportScreen` mencakup:

- `_cachedGroupedExpenses`  
  Menyimpan hasil grouping expenses agar tidak dihitung ulang setiap rebuild.
- `_subcategoryLabelCache`  
  Cache label subkategori.
- `_lastProcessedReportYear`  
  Menandai tahun terakhir yang sudah diproses cache.

### Alur cache
1. Saat fetch report:
   - cache di-reset dulu (`_cachedGroupedExpenses = null`, clear label cache)
2. Data dari API masuk
3. Grouping expense dihitung dan disimpan ke cache
4. Saat build tabel:
   - jika tahun sama & cache ada -> pakai cache
   - jika tidak -> hitung ulang

---

## 4.2 Informasi Cache di UI
Kotak informasi cache menampilkan:
- `cache_source` (`cache` / `refresh` / `init`)
- `cache_generated_at` atau `generated_at`

Label tampilan:
- `CACHE (tidak hit DB)`
- `REFRESH (DB terbaru)`
- `INIT`

Tujuan:
- Transparansi sumber data kepada user
- Memudahkan validasi apakah data fresh atau dari cache

---

## 5) Responsif Ukuran Layar

## 5.1 Breakpoint
Digunakan dua breakpoint utama:
- **Compact/mobile:** `< 550`
- **Narrow/desktop transisi:** `< 800` (khusus beberapa layout summary)

---

## 5.2 Dampak Breakpoint
Yang menyesuaikan otomatis:
- Ukuran font judul/body
- Padding container
- Tinggi tombol/spacing
- Tinggi body maksimal tabel

Contoh batas tinggi body table:
- Mobile: sekitar `650`
- Desktop: sekitar `800`

---

## 6) Scrollbar: Perilaku Lengkap

## 6.1 Scrollbar Halaman Utama
### Annual
- Scrollbar halaman utama ada di outer vertical scroll.
- Visibility mengikuti rule `showMainScrollbar` berbasis lebar layar.

### Summary
- Scrollbar halaman utama vertical aktif di kontainer luar report summary.

---

## 6.2 Scrollbar di Dalam Kotak Tabel (Annual)
Setiap card tabel memiliki:
1. **Scrollbar horizontal** untuk `SingleChildScrollView` arah X
2. **Scrollbar vertikal kiri** untuk list body tabel arah Y

Parameter penting:
- `leftScrollbarSpace`: `14`  
  Ruang aman kiri agar scrollbar tidak menimpa teks.
- `thickness`: `6` (inner table)
- `notificationPredicate` dipisah:
  - horizontal -> axis horizontal
  - vertical -> axis vertical

### Catatan anti-overlap
- Ada padding kiri kecil pada body list (`left: 2`) untuk menjaga teks kolom pertama tetap terbaca.

---

## 6.3 Scrollbar di Kotak Summary
Struktur summary menggunakan:
- Layer horizontal scroll untuk tabel
- Layer indikator scrollbar vertikal kiri (positioned) agar tetap menjadi acuan visual saat geser horizontal

Parameter utama:
- `leftScrollbarSpace`: `12`
- `thickness` horizontal: `8`
- `thickness` vertical indicator: `6`
- Body height menyesuaikan jumlah data hingga batas max (mobile/desktop)

---

## 7) Reset Posisi Scroll saat Refresh/Tahun Ganti

Pada `AnnualReportScreen`, saat `_fetchReport()`:
- Beberapa controller di-reset ke posisi `0`
- Tujuan:
  - UX konsisten saat pindah tahun
  - Mencegah user masuk ke posisi scroll lama yang membingungkan

Controller yang di-reset mencakup outer scroll + horizontal/vertical di tabel-tabel utama.

---

## 8) Fitur Data & Isi Tabel

## 8.1 Annual
- Menyusun data revenue, tax, dividend, operation cost, neraca
- Menghitung total per section
- Khusus operation cost:
  - grouping by settlement
  - pemisahan single vs batch
  - sorting subkategori + urutan data
  - total kategori dinamis

## 8.2 Summary
- Data per kategori bulanan (Jan–Des)
- Nilai yearly total per kategori
- `GRAND TOTAL` baris akhir:
  - akumulasi seluruh kategori per bulan
  - total tahunan

---

## 9) Export & Aksi Tambahan

### Annual
- Export PDF tahunan
- Export Excel tahunan

### Summary
- Export PDF summary
- Export Excel summary
- Filter year + date range

---

## 10) Konfigurasi Ukuran (Cheat Sheet Cepat)

## 10.1 Annual
- Breakpoint compact: `< 550`
- Main scrollbar thickness: `6`
- Inner scrollbar thickness: `6`
- Ruang kiri scrollbar tabel: `14`
- Row height:
  - umum `52`
  - tabel 4 `60`
- Max body height:
  - mobile `650`
  - desktop `800`

## 10.2 Summary
- Breakpoint compact: `< 550`
- Breakpoint narrow: `< 800`
- Horizontal scrollbar thickness: `8`
- Vertical indicator thickness: `6`
- Ruang kiri scrollbar: `12`
- Row height: `48`
- Max body height:
  - mobile `650`
  - desktop `800`

---

## 11) Checklist Uji Manual (Disarankan)

1. Buka Annual report di mobile width (kecil) dan desktop width
2. Cek semua tabel tampil normal (Tabel 1-5)
3. Swipe horizontal di tabel lebar:
   - teks kolom pertama tidak ketutup
   - scrollbar tetap terlihat
4. Scroll vertikal dalam tabel:
   - scrollbar kiri terlihat
   - tidak menimpa isi
5. Ganti tahun:
   - posisi scroll reset ke awal
   - data reload benar
6. Cek kotak info cache:
   - source & generated tampil
7. Uji export PDF/Excel
8. Buka Summary report:
   - scroll horizontal/vertikal berfungsi
   - grand total tampil benar
9. Cek di resolusi sempit (simulasi Android kecil)
10. Pastikan tidak ada crash render/layout

---

## 12) Catatan Teknis Penting

- Jika scrollbar terlihat “hilang”, biasanya karena:
  - kontras warna rendah
  - area scroll terlalu kecil
  - thumb tidak aktif pada kondisi tertentu
- Jika teks kolom kiri terpotong:
  - naikkan `leftScrollbarSpace`
  - cek padding body list
- Jika performa menurun pada data besar:
  - pertahankan `ListView.builder`
  - cache grouping tetap aktif
  - hindari render ulang besar tanpa kebutuhan

---

## 13) Rekomendasi Lanjutan

1. Tambah konstanta global untuk ukuran scrollbar/padding agar konsisten lintas screen.
2. Tambah `ScrollbarTheme` terpusat untuk kontras warna.
3. Tambah dokumentasi screenshot per kondisi:
   - mobile compact
   - desktop
   - horizontal scroll max
   - cache info panel

---

## 14) Penutup

Dengan konfigurasi saat ini, kotak report sudah memiliki:
- layout responsif
- cache terstruktur
- perilaku scrollbar yang lebih stabil
- dukungan data besar melalui lazy list

Dokumen ini dapat dijadikan acuan saat maintenance UI report berikutnya.

---

## 15) Troubleshooting Cepat (Praktis untuk Maintenance)

## 15.1 Gejala: Scrollbar kiri “terlihat hilang”
**Cek cepat:**
1. Pastikan area data memang bisa di-scroll vertikal (kalau data sedikit, thumb bisa tampak pasif).
2. Pastikan `thumbVisibility` aktif pada scrollbar terkait.
3. Pastikan kontras warna thumb terhadap background cukup.

**Aksi cepat:**
- Naikkan `thickness` (contoh `6 -> 7/8`)
- Aktifkan `trackVisibility` jika perlu observasi visual lebih jelas
- Tambah kontras di tema scrollbar

---

## 15.2 Gejala: Teks kolom pertama ketutup scrollbar kiri
**Akar masalah umum:**
- Ruang kiri untuk scrollbar (`leftScrollbarSpace`) terlalu kecil
- Padding body row terlalu mepet

**Aksi cepat:**
- Annual: naikkan `leftScrollbarSpace` bertahap (`14 -> 16`)
- Summary: naikkan `leftScrollbarSpace` bertahap (`12 -> 14`)
- Tambah padding kiri kecil di body list jika diperlukan (kenaikan kecil, contoh `+1` s.d `+3`)

---

## 15.3 Gejala: Scrollbar vertikal tidak konsisten saat swipe horizontal
**Akar masalah umum:**
- Filter notifikasi scroll tidak dipisah per axis
- Struktur widget horizontal/vertical scrollbar saling menimpa

**Aksi cepat:**
- Pastikan `notificationPredicate` dipisah:
  - vertikal hanya axis Y
  - horizontal hanya axis X
- Pertahankan pola layer terpisah (konten + indikator vertikal kiri) untuk summary

---

## 15.4 Gejala: Posisi scroll “nyangkut” saat ganti tahun/filter
**Akar masalah umum:**
- Controller tidak di-reset saat reload data

**Aksi cepat:**
- Pastikan setiap controller terkait di-`jumpTo(0)` pada proses fetch/reload

---

## 15.5 Gejala: UI stutter saat data besar
**Aksi cepat:**
1. Pastikan tetap pakai `ListView.builder` (bukan list statis panjang).
2. Gunakan cache grouping expense (annual) dan hindari hitung ulang berulang.
3. Hindari operasi berat di `build()` jika tidak wajib.

---

## 16) Titik Ubah Parameter (Single Source of Tuning)

Bagian ini untuk mempercepat penyesuaian UI tanpa perlu cari seluruh file.

### 16.1 Annual (`annual_report_screen.dart`)
Parameter utama yang paling sering dituning:
1. `leftScrollbarSpace` (ruang aman scrollbar kiri tabel)
2. `thickness` scrollbar horizontal/vertikal inner
3. `padding` card tabel (horizontal/vertical)
4. `rowHeight` (`52` / `60`)
5. `max body height` (`650` mobile, `800` desktop)
6. `showMainScrollbar` threshold berbasis `550/800`

---

### 16.2 Summary (`report_screen.dart`)
Parameter utama:
1. `leftScrollbarSpace`
2. `thickness` horizontal dan indikator vertikal kiri
3. `rowHeight` (`48`)
4. `max body height` (`650/800`)
5. Padding luar card dan kontainer scroll

---

### 16.3 Rule Tuning Aman (Agar tidak pecah layout)
- Ubah **satu parameter sekali jalan**, lalu uji manual.
- Untuk ruang scrollbar, naikkan bertahap kecil (`+2`).
- Untuk ketebalan scrollbar, naikkan bertahap (`+1`).
- Hindari mengubah banyak parameter sekaligus sebelum verifikasi.

---

## 17) Prosedur Regresi (Supaya Perubahan Aman)

Gunakan prosedur ini setiap ada perubahan pada ukuran, cache, atau scrollbar.

## 17.1 Regresi Fungsional
1. Buka Annual, cek Tabel 1–5 tampil.
2. Buka Summary, cek kategori + GRAND TOTAL tampil.
3. Ganti tahun, pastikan data reload.
4. Uji date range di Summary.
5. Uji export PDF/Excel (Annual & Summary).

---

## 17.2 Regresi Scroll & Layout
1. Scroll vertikal halaman utama (outer) normal.
2. Scroll horizontal tabel lebar normal.
3. Scroll vertikal dalam tabel normal.
4. Scrollbar kiri tidak menutup teks penting.
5. Tidak ada overlap border, tidak ada “kotak dalam kotak” berlebihan.
6. Tidak ada render overflow/error layout di runtime.

---

## 17.3 Regresi Responsif
Uji minimal 3 kondisi:
1. **Compact mobile** (`<550`)
2. **Narrow/transisi** (`550–799`)
3. **Desktop** (`>=800`)

Checklist tiap kondisi:
- tombol tidak saling tabrak
- teks judul tidak terpotong kritis
- scrollbar terlihat dan fungsional
- data tetap terbaca

---

## 17.4 Regresi Performa Dasar
1. Uji data sedikit, sedang, banyak.
2. Pastikan scroll tetap halus.
3. Pastikan tidak ada freeze saat buka screen report pertama kali.
4. Pastikan perpindahan tahun tidak lama berlebihan.

---

## 18) Catatan Operasional Tim (Anti Ribet)

1. Jika ada perubahan style report, update dokumen ini pada hari yang sama.
2. Simpan perubahan ukuran dalam pola konsisten (jangan angka acak).
3. Prioritaskan stabilitas layout dulu, baru kosmetik.
4. Kalau ada bug visual, sertakan:
   - screenshot
   - ukuran layar
   - langkah reproduksi
   - kondisi data (banyak/sedikit)
5. Untuk rilis cepat, jalankan minimal:
   - checklist regresi scroll/layout
   - checklist regresi responsif

---

## 19) Lampiran Mini Playbook (Perubahan Paling Umum)

### Kasus A: “Scrollbar kiri kurang jelas”
- Naikkan `thickness`
- Tingkatkan kontras warna
- Aktifkan track bila diperlukan

### Kasus B: “Kolom pertama ketimpa”
- Naikkan `leftScrollbarSpace`
- Tambah padding kiri body ringan

### Kasus C: “Setelah ganti tahun, posisi scroll aneh”
- Pastikan semua controller reset ke 0

### Kasus D: “UI patah di layar kecil”
- Kecilkan padding horizontal card
- Kecilkan ukuran icon/button trailing
- Kurangi spasi antar elemen

---

## 20) Catatan Perbandingan Gap Scrollbar: Annual vs Summary  
> **Catatan:** Poin-poin inti di section ini sudah diringkas juga di bagian **Ringkasan Cepat (Wajib Baca Dulu)** pada awal dokumen.

Bagian ini menjelaskan perbedaan gap scrollbar yang sempat jadi acuan saat penyesuaian UI.

### 20.1 Annual (acuan visual rapi)
Pada Laporan Tahunan, gap scrollbar kiri terhadap isi tabel dibuat sedikit lebih longgar sehingga:
- thumb tidak menabrak teks kolom pertama
- border kiri + isi terlihat “bernapas”
- hasil visual lebih rapi pada tabel lebar (terutama Tabel 4)

Karakter tampilan:
- ada jarak tipis tapi jelas antara scrollbar kiri dan konten
- ada ruang bawah tipis sebelum scrollbar horizontal

---

### 20.2 Summary (penyesuaian agar mirip Annual)
Pada Laporan Summary, awalnya terjadi dua kondisi:
1. terlalu masuk ke kanan (kesan kotak dobel terlalu dalam), atau
2. terlalu mepet (scrollbar terasa nabrak isi)

Setelan yang dipakai sekarang adalah kompromi:
- tetap dekat seperti annual
- tapi ada gap tipis agar teks aman terbaca

---

### 20.3 Parameter Praktis yang Mempengaruhi Gap
Parameter paling berpengaruh untuk “rasa” kerapian:

1. `leftScrollbarSpace`  
   Mengatur jarak area kiri antara scrollbar dan konten tabel.

2. `ListView padding kiri`  
   Fine tuning agar huruf pertama kolom tidak ketutup thumb.

3. `ListView padding bawah`  
   Membuat jarak aman kecil terhadap scrollbar horizontal.

4. `bodyHeight` (plus offset kecil)  
   Menghindari scrollbar horizontal terlihat menempel ke isi row terakhir.

5. `thickness` scrollbar  
   Semakin tebal, biasanya butuh gap sedikit lebih besar.

---

### 20.4 Rekomendasi Penyamaan Tampilan (Agar Tidak Ribet)
Gunakan urutan tuning berikut supaya cepat dan aman:

1. Samakan `thickness` dulu (Annual & Summary)
2. Samakan `leftScrollbarSpace` secara bertahap
3. Samakan padding bawah body list
4. Cek di 3 lebar layar: `<550`, `550–799`, `>=800`
5. Verifikasi dengan data panjang (banyak baris)

---

### 20.5 Preset Tuning Cepat (Jika Mau Diseragamkan Lagi)
- **Preset Rapat (lebih dekat ke isi):**
  - `leftScrollbarSpace` kecil
  - padding kiri sangat tipis
  - cocok jika ingin konten maksimal

- **Preset Seimbang (disarankan):**
  - `leftScrollbarSpace` sedang
  - padding kiri tipis
  - padding bawah tipis
  - paling aman untuk readability

- **Preset Lega (paling aman anti tabrak):**
  - `leftScrollbarSpace` lebih besar
  - padding kiri & bawah lebih jelas
  - cocok untuk scrollbar tebal / monitor kecil

---

### 20.6 Checklist Validasi Visual Gap
Setelah ubah parameter, cek cepat:
1. Kolom pertama tidak ketimpa thumb kiri.
2. Scrollbar horizontal tidak menempel row terakhir.
3. Border kiri card tetap terlihat bersih.
4. Tidak ada kesan “kotak dobel terlalu masuk”.
5. Tidak ada overflow / clipping saat swipe cepat.

---

Dokumen ini sekarang mencakup **fitur, cache, ukuran, scrollbar, troubleshooting, titik ubah parameter, perbandingan gap Annual vs Summary, panduan penyamaan tampilan, dan prosedur regresi** agar maintenance lebih cepat dan tidak ribet.