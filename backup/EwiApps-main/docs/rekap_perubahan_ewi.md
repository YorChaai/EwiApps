# Rekapitulasi Lengkap Perubahan Kode (Priority 1 - Priority 3)

Dokumen ini merangkum **semua** yang kita kerjakan pada aplikasi MiniProjectKPI_EWI.
Setiap perubahan dijelaskan dengan format **Before → After** agar mudah dipahami.

---

## Daftar Semua File yang Tersentuh

### File Baru Dibuat
| # | File | Kategori |
|---|------|----------|
| 1 | `frontend/lib/screens/widgets/sidebar.dart` | Refactoring (P2) |
| 2 | `frontend/lib/screens/widgets/page_selector.dart` | Refactoring (P2) |
| 3 | `frontend/lib/screens/widgets/settlement_widgets.dart` | Refactoring (P2) |
| 4 | `frontend/lib/screens/widgets/settlement_detail_widgets.dart` | Refactoring (P2) |
| 5 | `frontend/lib/screens/category_management_screen.dart` | Refactoring (P2) |
| 6 | `backend/routes/reports/__init__.py` | Refactoring (P2) |
| 7 | `backend/routes/reports/helpers.py` | Refactoring (P2) |
| 8 | `backend/routes/reports/summary.py` | Refactoring (P2) |
| 9 | `backend/routes/reports/annual.py` | Refactoring (P2) |
| 10 | `backend/routes/dashboard.py` | Fitur Baru (P3) |
| 11 | `backend/_archive/` (folder baru) | Pembersihan (P1) |

### File yang Dimodifikasi
| # | File | Kategori |
|---|------|----------|
| 1 | `frontend/lib/screens/dashboard_screen.dart` | Refactoring (P2) + Fitur Baru (P3) |
| 2 | `frontend/lib/screens/settlement_detail_screen.dart` | Refactoring (P2) |
| 3 | `frontend/lib/services/api_service.dart` | Fitur Baru (P3) |
| 4 | `frontend/lib/providers/settlement_provider.dart` | Fitur Baru (P3) |
| 5 | `frontend/lib/screens/widgets/sidebar.dart` | Fitur Baru (P3) |
| 6 | `backend/app.py` | Refactoring (P2) + Fitur Baru (P3) |
| 7 | `backend/routes/settlements.py` | Fitur Baru (P3) |
| 8 | `backend/routes/advances.py` | Fitur Baru (P3) |

### File yang Dihapus / Dipindahkan
| # | File | Aksi |
|---|------|------|
| 1 | `frontend/lib/screens/advance/advance_request_screen.dart` | Dihapus (kosong) |
| 2 | `backend/routes/reports.py` | Dihapus (diganti folder package) |
| 3 | `backend/read_excel.py` | Pindah ke `_archive/` |
| 4 | `backend/read_excel2.py` | Pindah ke `_archive/` |
| 5 | `backend/read_excel_output.txt` | Pindah ke `_archive/` |
| 6 | `backend/temp_check.py` | Pindah ke `_archive/` |
| 7 | `backend/temp_inspect.py` | Pindah ke `_archive/` |
| 8 | `backend/update_categories.py` | Pindah ke `_archive/` |
| 9 | `backend/update_excel_db.py` | Pindah ke `_archive/` |

---

## Priority 1: Pembersihan File

**Tujuan:** Bersihkan file-file mati yang mengotori proyek. Tidak ada logika yang berubah.

### 1A. Hapus File Frontend Kosong
- **Before:** Ada file `advance_request_screen.dart` di folder `advance/` yang isinya 0 baris (kosong total), tidak di-import di manapun.
- **After:** File dihapus. Tidak mengganggu apapun karena memang tidak pernah dipakai.

### 1B. Arsipkan Script Percobaan Backend
- **Before:** Di folder `backend/` ada 7 file Python sisa percobaan awal (baca Excel, tes database, update kategori manual). File-file ini bercampur dengan kode aplikasi utama sehingga membuat folder berantakan.
- **After:** Dibuat folder `backend/_archive/`, ketujuh file dipindahkan ke sana. Folder utama backend sekarang hanya berisi file yang benar-benar dipakai server.

---

## Priority 2: Refactoring (Pecah File Raksasa)

**Tujuan:** File-file yang isinya ribuan baris dipecah menjadi file-file kecil. **Tampilan aplikasi TIDAK berubah sama sekali — hanya struktur kode di balik layar yang berubah.**

### 2A. Pecah `dashboard_screen.dart` (Frontend)

- **Before:** Satu file `dashboard_screen.dart` berisi **1.953 baris** yang mencampur aduk:
  - Widget sidebar (menu samping)
  - Widget dropdown navigasi HP
  - Widget kartu settlement + filter status
  - Halaman manajemen kategori (CRUD)
  - Layout utama dashboard
  
  Kalau mau edit sidebar saja, harus buka file 2000 baris dan cari-cari di mana kodenya.

- **After:** Dipecah menjadi 5 file:

  | File Baru | Isi | Baris |
  |-----------|-----|-------|
  | `widgets/sidebar.dart` | Class `DashboardSidebar` + `SidebarNavItem` | ~280 |
  | `widgets/page_selector.dart` | Class `PageSelector` (dropdown navigasi mobile) | ~50 |
  | `widgets/settlement_widgets.dart` | Class `SettlementCard`, `StatusFilterChip`, `StatusBadge`, `formatNumber` | ~300 |
  | `category_management_screen.dart` | Class `CategoryManagementView` (CRUD kategori) | ~350 |
  | `dashboard_screen.dart` (sisa) | Layout utama + `_SettlementListView` | ~700 |

  Sekarang kalau mau edit sidebar, cukup buka `sidebar.dart` yang ukurannya kecil.

### 2B. Pecah `settlement_detail_screen.dart` (Frontend)

- **Before:** Satu file `settlement_detail_screen.dart` berisi **1.745 baris**. Semuanya ada di sini: layout detail, kartu ringkasan expense, tombol-tombol aksi (Submit, Approve, Reject, Complete), dialog konfirmasi.

- **After:** Bagian widget yang sering di-reuse diekstrak ke file baru:

  | File Baru | Isi |
  |-----------|-----|
  | `widgets/settlement_detail_widgets.dart` | Class `SummaryCard` (kotak ringkasan total) + `SettlementActionButton` (tombol aksi) |
  
  File utama `settlement_detail_screen.dart` susut dan sekarang tinggal memanggil class dari file widget tersebut.

### 2C. Pecah `reports.py` (Backend)

- **Before:** Satu file `backend/routes/reports.py` berisi **1.977 baris**. Isinya campur aduk semua logika laporan:
  - Fungsi-fungsi pembantu (format tanggal, format mata uang, baca Excel)
  - Endpoint laporan summary bulanan
  - Endpoint export PDF receipt
  - Endpoint laporan tahunan (Revenue vs Cost) ke Excel template
  - Endpoint export PDF annual report
  - Logic caching laporan

  Kalau ada bug di export PDF, developer harus menelusuri hampir 2000 baris kode.

- **After:** File `reports.py` dihapus dan diubah menjadi folder (Python Package) `reports/`:

  | File Baru | Isi | Baris |
  |-----------|-----|-------|
  | `reports/__init__.py` | Deklarasi blueprint `reports_bp`, import semua route | ~20 |
  | `reports/helpers.py` | Fungsi utility: format tanggal, format uang, helper baca Excel | ~200 |
  | `reports/summary.py` | Endpoint summary bulanan, export receipt PDF, bulk export PDF | ~400 |
  | `reports/annual.py` | Endpoint laporan tahunan Excel + PDF, logic caching | ~600 |

  Sekarang kalau ada bug di laporan tahunan, developer cukup buka `annual.py` (600 baris) tanpa takut menyenggol kode laporan summary.

### 2D. Perbaikan `app.py` (Backend)

- **Before:** File `app.py` meng-import blueprint langsung dari file: `from routes.reports import reports_bp`.
- **After:** Karena `reports.py` sekarang jadi folder package, import diubah menjadi: `from routes.reports import reports_bp` (sama tulisannya, tapi Python sekarang membaca dari `reports/__init__.py`). Semua blueprint registrasi lainnya dipastikan utuh dan tidak hilang.

---

## Priority 3: Fitur Baru

**Tujuan:** Menambahkan 3 fitur baru yang bisa dilihat dan dirasakan langsung oleh pengguna (baik dari sisi Manager maupun User biasa).

### 3A. Dashboard Summary Cards (Kartu Ringkasan Angka)

**Apa fiturnya:** 3 kotak kartu berwarna-warni muncul di atas daftar settlement, memberikan informasi ringkasan secara instan.

- **Before:** Saat membuka aplikasi, user langsung disambut daftar settlement yang panjang. Tidak ada informasi ringkasan. Manager harus menghitung manual berapa settlement yang perlu di-review.

- **After:** Di atas daftar settlement sekarang muncul 3 kotak:
  - 🟠 **Settlement Pending** — menampilkan angka total settlement berstatus "submitted" yang belum di-approve.
  - 🟣 **Kasbon Pending** — menampilkan angka total kasbon berstatus "submitted" yang belum di-approve.
  - 🟢 **Pengeluaran Bulan Ini** — menampilkan total Rupiah (Rp) dari semua pengeluaran yang sudah di-approve di bulan berjalan.

**Perubahan kode yang terjadi:**

| File | Apa yang ditambah/diubah |
|------|--------------------------|
| `backend/routes/dashboard.py` **[BARU]** | Endpoint API `GET /api/dashboard/summary`. Backend menghitung jumlah settlement + advance berstatus "submitted", dan menjumlahkan semua expense yang approved bulan ini pakai SQL query. |
| `backend/app.py` | Menambahkan 2 baris: import `dashboard_bp` dan `app.register_blueprint(dashboard_bp, url_prefix='/api/dashboard')` |
| `frontend/lib/services/api_service.dart` | Menambahkan method baru `getDashboardSummary()` yang memanggil `GET /api/dashboard/summary` |
| `frontend/lib/screens/dashboard_screen.dart` | Menambahkan: (1) variabel `_dashboardSummary` untuk menyimpan data, (2) fungsi `_loadDashboardSummary()` dipanggil saat halaman dibuka, (3) fungsi `_buildSummaryCards()` dan `_summaryTile()` yang menggambar 3 kotak kartu berwarna |

### 3B. Notification Badges (Angka Merah di Sidebar)

**Apa fiturnya:** Kotak merah kecil berisi angka muncul di samping menu "Settlements" dan "Kasbon" pada sidebar, menunjukkan jumlah item yang menunggu approval.

- **Before:** Sidebar hanya menampilkan nama menu biasa: `Settlements`, `Kasbon`, `Laporan`, dst. Manager tidak tahu ada berapa pengajuan yang menunggu tanpa mengklik masuk satu-satu.

- **After:** Di samping tulisan "Settlements" muncul badge merah (misalnya `3`) artinya ada 3 settlement menunggu review. Di samping "Kasbon" muncul badge merah (misalnya `1`) artinya ada 1 kasbon menunggu approval. Kalau tidak ada yang pending, badge-nya tidak muncul.

**Perubahan kode yang terjadi:**

| File | Apa yang ditambah/diubah |
|------|--------------------------|
| `frontend/lib/screens/widgets/sidebar.dart` | (1) Class `DashboardSidebar` ditambah 2 parameter baru: `pendingSettlements` dan `pendingAdvances`. (2) Class `SidebarNavItem` ditambah parameter `badge`. (3) Jika `badge > 0`, muncul Container merah bundar berisi angka badge di ujung kanan menu item. |
| `frontend/lib/screens/dashboard_screen.dart` | (1) Ditambah variabel `_pendingSettlements` dan `_pendingAdvances` di state. (2) Fungsi `_fetchBadgeCounts()` memanggil API dashboard summary saat halaman pertama kali dibuka. (3) Angka pending dikirim ke `DashboardSidebar(pendingSettlements: ..., pendingAdvances: ...)`. |

### 3C. Search Bar (Pencarian Teks)

**Apa fiturnya:** Kotak input teks untuk mencari settlement berdasarkan judul atau deskripsi. Cukup ketik kata kunci, daftar langsung terfilter otomatis.

- **Before:** Jika user ingin mencari settlement lama (misal: "ALFA_TLJ-58 Prabumulih"), user harus scroll ke bawah halaman atau mengganti-ganti filter status dan tahun secara manual hingga menemukan yang dicari.

- **After:** Sekarang ada TextField bertuliskan *"Cari settlement..."* dengan icon kaca pembesar (🔍) di atas filter chips. User ketik "Prabumulih" → aplikasi langsung mengirim request ke backend dengan parameter `?search=Prabumulih` → backend memfilter database menggunakan SQL `ILIKE '%Prabumulih%'` pada kolom judul dan deskripsi → hanya settlement yang cocok yang ditampilkan. Ada juga tombol ✕ (clear) untuk menghapus pencarian.

**Perubahan kode yang terjadi:**

| File | Apa yang ditambah/diubah |
|------|--------------------------|
| `backend/routes/settlements.py` | Di fungsi `list_settlements()`: ditambah baca parameter `search` dari query string. Jika ada, query database di-filter dengan `Settlement.title.ilike('%kata%')` OR `Settlement.description.ilike('%kata%')`. |
| `backend/routes/advances.py` | Di fungsi `list_advances()`: ditambah logika search yang persis sama — filter `Advance.title.ilike(...)` OR `Advance.description.ilike(...)`. |
| `frontend/lib/services/api_service.dart` | Di fungsi `getSettlements()` dan `getAdvances()`: ditambahkan parameter opsional `String? search`. Jika diisi, URL request ditambahi `&search=xxx`. |
| `frontend/lib/providers/settlement_provider.dart` | Di fungsi `loadSettlements()`: ditambah parameter `String? search` yang diteruskan ke `api.getSettlements(search: search)`. |
| `frontend/lib/screens/dashboard_screen.dart` | (1) Ditambah variabel `_searchQuery` di state. (2) Di build method, ditambah widget `TextField` dengan styling (warna card, border, icon kaca pembesar, tombol clear). (3) `onChanged` dari TextField memanggil `_reloadSettlements()` yang sekarang menyertakan parameter `search:`. |

---

## Ringkasan Perubahan Secara Keseluruhan

| Aspek | Before | After |
|-------|--------|-------|
| **Struktur File Frontend** | 2 file raksasa (1.953 + 1.745 baris) | Dipecah menjadi 7+ file kecil yang fokus |
| **Struktur File Backend** | 1 file raksasa reports.py (1.977 baris) + script percobaan berserakan | reports/ jadi package (4 file), script lama diarsipkan |
| **Informasi di Dashboard** | Langsung list settlement, tidak ada ringkasan | Ada 3 kartu ringkasan (pending counts + expense bulan ini) |
| **Navigasi Sidebar** | Teks menu polos tanpa indikator | Ada badge angka merah menunjukkan jumlah pending |
| **Pencarian Data** | Harus scroll manual atau ganti filter | Ada search bar, ketik kata kunci langsung terfilter |
| **Jumlah Endpoint API** | Tidak ada endpoint dashboard | Tambah 1 endpoint baru: `GET /api/dashboard/summary` |
| **Parameter API** | Settlements dan Advances tidak bisa dicari teks | Kedua endpoint sekarang mendukung `?search=kata` |

---

**Status Akhir:** ✅ Semua perubahan sudah lulus uji coba:
- `flutter analyze` — 0 error
- Backend `create_app()` — Server OK
---

## Rekap Revisi 2: Flow Kasbon -> Settlement -> Revisi

Revisi tahap 2 ini fokus pada penyempurnaan **alur bisnis kasbon** agar lebih sesuai kebutuhan operasional nyata. Perubahan kali ini bukan sekadar menambah tombol, tapi merapikan hubungan antara:

- kasbon yang sudah di-approve
- draft settlement yang dibuat dari kasbon
- tambahan dana jika ternyata uang kurang
- perbandingan antara dana approved dan realisasi pengeluaran

Dengan revisi ini, manager sekarang bisa lebih mudah melihat apakah uang yang diminta benar-benar dipakai, masih sisa, atau justru kurang.

---

### Tujuan Revisi 2

- Kasbon yang sudah di-approve bisa langsung dibuat menjadi **draft settlement**
- Item kasbon approved otomatis masuk ke settlement
- Jika dana kurang, user tidak mengubah item lama, tetapi menambah lewat **Revisi 1** dan **Revisi 2**
- Item approved lama tetap terkunci agar histori tidak rusak
- Ditambahkan **warning policy ringan** untuk memantau selisih dan revisi aktif

---

## A. Before vs After dari Rekap 1 ke Revisi 2

### A1. Status Kasbon

- **Before (setelah Rekap 1):**
  - Status kasbon masih sederhana: `draft`, `submitted`, `approved`, `rejected`, `settled`
  - Saat settlement dibuat, status kasbon terlalu cepat terlihat seolah sudah selesai
  - Belum ada status khusus saat kasbon sedang dipakai di settlement atau sedang direvisi

- **After (Revisi 2):**
  - Status kasbon diperluas menjadi lebih realistis:
    - `draft`
    - `submitted`
    - `approved`
    - `revision_draft`
    - `revision_submitted`
    - `revision_rejected`
    - `in_settlement`
    - `completed`
    - `rejected`

**Yang terasa berubah:**
- User dan manager sekarang bisa tahu posisi kasbon dengan jauh lebih jelas
- Tidak ada lagi kebingungan antara “sudah di-approve” dengan “sudah benar-benar selesai”

---

### A2. Kasbon ke Settlement Sekarang Otomatis

- **Before (setelah Rekap 1):**
  - Hubungan kasbon ke settlement sudah ada, tetapi alurnya belum kuat
  - User belum punya jalur yang rapi untuk langsung membuat settlement dari kasbon approved

- **After (Revisi 2):**
  - Ditambahkan flow resmi:
    - kasbon approved
    - klik **Buat Settlement**
    - draft settlement otomatis dibuat
    - item kasbon approved otomatis dicopy menjadi expense settlement

**Yang terasa berubah:**
- User tidak perlu input ulang item awal
- Settlement terasa benar-benar turunan dari kasbon, bukan data terpisah

---

### A3. Revisi 1 dan Revisi 2

- **Before (setelah Rekap 1):**
  - Jika uang kasbon kurang, belum ada alur resmi
  - Solusi sebelumnya berpotensi bikin histori berantakan karena item lama harus diedit

- **After (Revisi 2):**
  - Ditambahkan mekanisme:
    - `Start Revisi`
    - tambah item revisi
    - submit revisi
    - approve / reject revisi oleh manager
  - Revisi dibatasi sampai:
    - `Revisi 1`
    - `Revisi 2`
  - Item lama yang sudah disetujui tidak bisa diedit lagi
  - Tambahan kebutuhan dana dicatat sebagai item baru di revisi

**Yang terasa berubah:**
- Histori dana jauh lebih rapi
- Manager bisa melihat mana permintaan awal dan mana tambahan karena dana kurang
- Audit lebih aman karena data approved lama tetap utuh

---

### A4. Item Kasbon Dipisah Per Revisi

- **Before (setelah Rekap 1):**
  - Semua item kasbon dianggap satu kumpulan biasa
  - Tidak terlihat item itu milik pengajuan awal atau revisi tambahan

- **After (Revisi 2):**
  - Setiap item kasbon sekarang punya `revision_no`
  - Di layar detail kasbon, item dikelompokkan menjadi:
    - `Pengajuan Awal`
    - `Revisi 1`
    - `Revisi 2`
  - Tiap kelompok punya totalnya sendiri
  - Status approved / belum approved per revisi ikut terlihat

**Yang terasa berubah:**
- Manager lebih cepat membaca histori permintaan dana
- User lebih paham item mana yang masih bisa diubah

---

### A5. Ringkasan Dana vs Realisasi

- **Before (setelah Rekap 1):**
  - Kasbon hanya menampilkan total umum
  - Settlement hanya menampilkan total expense dan approved amount
  - Belum ada pembanding jelas antara dana kasbon dan realisasi pengeluaran

- **After (Revisi 2):**
  - Detail kasbon sekarang menampilkan:
    - Pengajuan Awal
    - Tambahan Approved
    - Dana Tersedia
    - Realisasi Settlement
    - Selisih
  - Detail settlement juga menampilkan:
    - dana kasbon
    - selisih
    - ringkasan kasbon awal dan revisi

**Yang terasa berubah:**
- Manager bisa langsung lihat:
  - dana approved berapa
  - sudah dipakai berapa
  - sisa atau kurang berapa

Ini adalah perubahan yang paling terasa dari sisi kontrol keuangan.

---

### A6. Policy Limitation Versi Ringan

- **Before (setelah Rekap 1):**
  - Belum ada warning jika realisasi melebihi dana kasbon
  - Sistem belum membantu memberi sinyal risiko secara ringan

- **After (Revisi 2):**
  - Ditambahkan warning ringan, bukan hard-block
  - Contoh warning:
    - realisasi settlement melebihi dana approved
    - masih ada sisa dana kasbon
    - masih ada revisi aktif yang belum selesai

**Yang terasa berubah:**
- Sistem mulai mengawasi tanpa membuat user terkunci
- Cocok untuk kebutuhan sekarang yang masih ingin fleksibel

---

### A7. Endpoint dan Nama Aksi Dirapikan

- **Before (setelah Rekap 1):**
  - Ada naming yang membingungkan di settlement
  - Contohnya aksi `completeSettlement()` masih menembak endpoint approval lama

- **After (Revisi 2):**
  - Aksi settlement dipisah jelas:
    - `submit`
    - `approve`
    - `complete`
    - `reject`
  - Ditambahkan endpoint baru untuk:
    - `start_revision`
    - `create_settlement`

**Yang terasa berubah:**
- Kode lebih konsisten
- Risiko logic error karena salah endpoint berkurang

---

## B. File yang Tersentuh di Revisi 2

### Backend

| File | Perubahan |
|------|-----------|
| `backend/models.py` | Menambah field revisi kasbon, linkage expense ke advance item, summary dana vs realisasi, dan warning policy ringan |
| `backend/app.py` | Menambah auto schema patch untuk database lama agar kolom revisi baru ikut tersedia |
| `backend/routes/advances.py` | Menambah flow revisi, create settlement dari kasbon, locking item approved, sinkronisasi item revisi ke settlement |
| `backend/routes/settlements.py` | Memisahkan approve dan complete, merapikan status settlement, dan sinkron status advance-settlement |

### Frontend

| File | Perubahan |
|------|-----------|
| `frontend/lib/services/api_service.dart` | Menambah endpoint revisi dan create settlement, serta merapikan endpoint settlement |
| `frontend/lib/providers/advance_provider.dart` | Menambah action `startRevision()` dan `createSettlementFromAdvance()` |
| `frontend/lib/providers/settlement_provider.dart` | Menambah action `approveSettlement()` dan sinkron ke endpoint baru |
| `frontend/lib/screens/advance/advance_detail_screen.dart` | Menambah tombol revisi, tombol buat settlement, grouping item per revisi, summary dana vs realisasi, dan warning ringan |
| `frontend/lib/screens/advance/my_advances_screen.dart` | Menambah filter status baru seperti `in_settlement` dan `revision_submitted` |
| `frontend/lib/screens/settlement_detail_screen.dart` | Menambah ringkasan dana kasbon vs realisasi dan memisahkan approve vs complete |
| `frontend/lib/screens/manager/manager_dashboard_screen.dart` | Membersihkan referensi field/status lama yang salah |

---

## C. Perubahan yang Paling Terasa

Kalau ditanya “apa yang paling terasa setelah Revisi 2?”, jawabannya ada 4:

1. **Kasbon sekarang benar-benar menjadi sumber dana settlement**, bukan cuma catatan permintaan uang.
2. **Revisi tambahan dana sekarang resmi dan rapi**, tidak perlu edit item approved lama.
3. **Manager bisa membaca selisih dana dengan cepat**, apakah uang masih sisa atau justru kurang.
4. **Kode backend dan frontend jadi lebih sinkron**, terutama di status dan action endpoint.

---

## D. Status Uji Coba Revisi 2

**Status akhir Revisi 2:** Sudah diverifikasi di level kode

- `flutter analyze` — `No issues found`
- Backend `create_app()` — berhasil load
- Python compile check file backend utama — lolos
- Schema database aktif sudah otomatis bertambah kolom revisi baru

---

## E. Kesimpulan Singkat

Revisi 2 ini bisa dianggap sebagai:

**“pondasi operasional kasbon-settlement yang sudah jauh lebih matang, lebih aman untuk audit, dan lebih enak dipakai manager untuk memantau penggunaan dana.”**
