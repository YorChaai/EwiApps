# Analisis Menyeluruh Aplikasi MiniProjectKPI_EWI

## Pemahaman Konteks

Aplikasi ini dibuat **sendiri** untuk perusahaan papa (Exspan Wireline Indonesia), **bukan** menggunakan Mekari Expense. Meeting transcript yang ada adalah pertemuan dengan Mekari Expense sebagai **referensi** — untuk mempelajari bagaimana produk profesional menangani expense management. Jadi ada **perbedaan** antara apa yang ditawarkan Mekari dan apa yang sudah dibangun di aplikasi kamu.

---

## 🏗️ Arsitektur Aplikasi Saat Ini

| Komponen | Teknologi | LOC | Files |
|----------|-----------|-----|-------|
| **Backend** | Python (Flask) + SQLite + JWT | ~5,882 | 17 files |
| **Frontend** | Flutter (Dart) | ~10,576 | 25 files |
| **Total** | | **~16,458** | **42 files** |

### Modul yang Sudah Ada:
1. ✅ **Settlement** (realisasi pengeluaran) — CRUD + workflow (draft → submitted → approved → completed)
2. ✅ **Expense** (detail nota) — CRUD + upload evidence + approve/reject per item
3. ✅ **Advance/Kasbon** (cash advance) — CRUD + item + workflow + evidence
4. ✅ **Kategori** — parent-child hierarchy + approval pending untuk staff
5. ✅ **Revenue** (pemasukan) — CRUD dengan filter tanggal
6. ✅ **Tax** (pajak) — CRUD dengan field PPN, PPh 21/23/26
7. ✅ **Laporan Summary** — per kategori per bulan → JSON/PDF/Excel
8. ✅ **Laporan Tahunan** — revenue + tax + expense → PDF/Excel (dari template)
9. ✅ **Role-based access** — Manager, Staff, Mitra Eks
10. ✅ **Settings** — tema, folder storage, tahun laporan default
11. ✅ **Excel Import** — script konversi Excel template → database

---

## 🔄 Perbandingan: Aplikasi Kamu vs Fitur Mekari Expense

| Fitur Mekari Expense | Aplikasi Kamu | Status |
|----------------------|---------------|--------|
| Reimbursement claim | ✅ Settlement + Expense | **Sudah ada** |
| Cash Advance request | ✅ Advance/Kasbon | **Sudah ada** |
| Upload evidence/receipt | ✅ Evidence upload di expense & advance item | **Sudah ada** |
| Kategori + sub-kategori | ✅ Parent-child category | **Sudah ada** |
| Multi-level approval | ⚠️ Hanya 1 level (Manager approve) | **Partial** |
| Policy limitation (limit per bulan/transaksi) | ❌ Tidak ada | **Belum** |
| Auto-disbursement | ❌ Tidak ada (dan tidak perlu) | **Tidak relevan** |
| Business Trip (itinerary, destinasi, tanggal) | ❌ Tidak ada | **Belum** (Pak Nevi bilang tidak perlu) |
| Custom field / additional details | ❌ Tidak ada | **Belum** |
| Settlement report setelah cash advance | ⚠️ Ada link advance→settlement, tapi flow belum jelas | **Partial** |
| CSV/Excel export per kategori terpisah | ✅ Summary per kategori per bulan sudah ada | **Sudah ada** (lebih baik dari Mekari default!) |
| Annual report (pajak) | ✅ Revenue + Tax + Expense ke Excel/PDF | **Sudah ada** |
| Mobile app | ✅ Flutter (Android + Web + Desktop) | **Sudah ada** |
| Backup approver | ❌ Tidak ada | **Belum** |
| Notifikasi email | ❌ Tidak ada | **Belum** |
| Accessible per divisi | ❌ Tidak ada pembatasan per divisi | **Belum** |

---

## ⚠️ Masalah & Kekurangan yang Ditemukan

### 🔴 Masalah Kritis

1. **File `advance_request_screen.dart` KOSONG (0 baris)**
   - File ada tapi tidak ada isinya. Placeholder yang tidak terpakai.
   - **Solusi:** Hapus file ini atau implementasi jika memang direncanakan.

2. **File `dashboard_screen.dart` terlalu besar (1,953 baris)**
   - Menggabungkan sidebar, settlement list, kategori management, dan banyak widget.
   - **Solusi:** Pecah ke beberapa file terpisah (misal: `sidebar.dart`, `settlement_list_view.dart`, `category_management_view.dart`).

3. **File `settlement_detail_screen.dart` juga besar (1,745 baris)**
   - **Solusi:** Pisahkan dialog-dialog (add expense, edit expense, evidence viewer) ke file terpisah.

4. **File `reports.py` sangat besar (1,977 baris, 56 function)**
   - **Solusi:** Pecah per jenis report (summary, annual, advance, receipt).

### 🟡 Kekurangan Fungsional

5. **Tidak ada link jelas antara Advance → Settlement (settlement report)**
   - Mekari mewajibkan karyawan submit settlement report setelah cash advance.
   - Aplikasi kamu sudah punya field `advance_id` di Settlement, tapi **flow-nya belum enforced** di UI.

6. **Approval hanya 1 level**
   - Mekari support multi-level (approval 1 → 2 → 3).
   - Untuk perusahaan kecil mungkin cukup, tapi jika berkembang perlu multi-level.

7. **Tidak ada policy limitation**
   - Tidak ada batas berapa karyawan bisa claim per bulan/tahun.
   - Untuk saat ini mungkin OK karena Pak Nevi approve manual.

8. **Tidak ada notifikasi**
   - Karyawan/manager tidak tahu ada pengajuan baru kecuali buka app.
   - Minimal bisa tambah notifikasi in-app.

9. **Tidak ada custom field**
   - Mekari bisa tambah field seperti "trip name" sebagai additional details.
   - Berguna untuk tracking tujuan perjalanan.

10. **Mata uang asing ada tapi belum sempurna**
    - Ada field `currency` dan `currency_exchange` di expense.
    - Tapi Revenue juga butuh handling mata uang asing — sudah ada `currency_exchange` di model.

### 🟢 Keunggulan Aplikasi Kamu vs Mekari Default

1. **Custom Excel report per kategori per bulan** — Mekari hanya bisa CSV default!
2. **Annual report lengkap** (Revenue + Tax + Expense + Laba Rugi) — Mekari perlu add-on Rp 10-20 juta/bulan!
3. **Template-based Excel export** — bisa langsung cocok format pelaporan pajak
4. **Gratis & self-hosted** — tidak ada biaya per transaksi atau langganan
5. **Mendukung import dari Excel lama** — script `excel_to_app_db.py` untuk migrasi data

---

## 📋 Rencana Kerja yang Diusulkan

### Prioritas 1: Perbaikan Cepat (Quick Fixes)
- [ ] Hapus atau isi `advance_request_screen.dart` yang kosong
- [ ] Perbaiki link advance → settlement di UI (tombol "Buat Settlement Report" di advance detail)
- [ ] Tambah validasi — tidak bisa submit settlement/advance tanpa expense/item

### Prioritas 2: Refactoring (Kualitas Kode)
- [ ] Pecah `dashboard_screen.dart` → 3-4 file
- [ ] Pecah `settlement_detail_screen.dart` → pisahkan dialog ke file sendiri
- [ ] Pecah `reports.py` → beberapa modul (summary, annual, receipt, bulk)
- [ ] Bersihkan script ad-hoc yang tidak didokumentasi (`read_excel.py`, `temp_check.py`, dll)

### Prioritas 3: Fitur Baru Penting
- [ ] **Trip Name / Custom Field** — tambah field "tujuan perjalanan" di settlement
- [ ] **Dashboard ringkasan** — total expense bulan ini, pending approval, dst
- [ ] **Notifikasi in-app** — badge/counter untuk manager saat ada pengajuan baru
- [ ] **Filter & search** — cari settlement/expense berdasarkan keyword

### Prioritas 4: Fitur Lanjutan (Jika Dibutuhkan)
- [ ] Multi-level approval
- [ ] Policy limitation (batas claim per karyawan per bulan)
- [ ] Role pembatasan per divisi
- [ ] Backup approver
- [ ] Email notifikasi

---

## ❓ Pertanyaan untuk Kamu

1. **Apakah fitur business trip/itinerary perlu ditambahkan?** (Dari meeting, Pak Nevi bilang tidak perlu karena jarang terencana — jadi mungkin skip dulu?)

2. **Apakah multi-level approval penting?** Saat ini hanya Pak Nevi yang approve — apakah akan ada orang lain yang perlu approve juga?

3. **Prioritas mana yang mau dikerjakan duluan?** Quick fixes? Refactoring? Atau fitur baru?

4. **Apakah ada bug/masalah spesifik yang kamu alami saat menggunakan aplikasi ini?**
