# CHECKLIST UJI MANUAL - REVISI TERAKHIR

> **Tanggal:** 12 April 2026  
> **Update:** Restrukturisasi folder + Fix 4 Bug Critical  
> **Status:** Siap testing manual

---

## 📋 Panduan Testing

| Field | Keterangan |
|-------|-----------|
| **Status** | ✅ OK / ❌ BUG / ⚠️ IMPROVE |
| **Prioritas** | 🔴 TINGGI (data/alur utama) / 🟡 SEDANG (UI/UX) / 🟢 RENDAH (kosmetik) |
| **Tester** | Nama siapa yang test |
| **Tanggal** | Tanggal testing |

---

## 🔥 1. PENGHAPUSAN FILE SAMPAH

### 1.1 Frontend - File Dihapus
| Test | Detail | Status |
|------|--------|--------|
| `change_icon.bat` tidak ada lagi | Cek `frontend/` root | |
| `repair.py` tidak ada lagi | Cek `frontend/` root | |
| `analyze_output.txt` tidak ada lagi | Cek `frontend/` root | |
| `settings_screen_backup.dart` tidak ada lagi | Cek `frontend/lib/screens/` | |

### 1.2 Backend - File Dihapus
| Test | Detail | Status |
|------|--------|--------|
| Debug scripts tidak ada (6 files) | `debug_titles.py`, `fix_*.py`, `test_*.py` | |
| Migration scripts tidak ada (9 files) | `migrate_add_*.py`, `migrate_sort_order*.py`, `migrate_evidence.py` | |
| Folder `scripts/` tidak ada | 18 debug Excel files | |
| Folder `_archive/` tidak ada | 7 archive files | |
| Folder `backup/` di routes tidak ada | 3 backup files | |
| `CODE_ANALYSIS_REPORT.md` tidak ada | Cek `backend/routes/reports/` | |
| Database tidak terpakai tidak ada | `app.db`, `database_import_dividen.db`, `ewi.db` | |
| Backend masih bisa jalan | Run `python app.py` tanpa error | |

**Prioritas:** 🟢 RENDAH - Tidak mempengaruhi fitur

---

## 📁 2. RESTRUKTURISASI FOLDER FRONTEND

### 2.1 Struktur Folder Baru
| Test | Detail | Status |
|------|--------|--------|
| Folder `screens/auth/` ada | `login_screen.dart`, `register_screen.dart` | |
| Folder `screens/management/` ada | 5 management screens | |
| Folder `screens/reports/` ada | `report_screen.dart`, `annual_report_screen.dart` | |
| Folder `screens/settings/` ada | `settings_screen.dart`, `balance_sheet_settings_screen.dart` | |
| Folder `screens/settlement/` ada | `settlement_detail_screen.dart` | |
| Tidak ada file berantakan di `screens/` root | Hanya `dashboard_screen.dart` | |

### 2.2 Navigasi Aplikasi
| Test | Detail | Status |
|------|--------|--------|
| Login screen terbuka normal | Dari `main.dart` | |
| Dashboard screen terbuka normal | Navigasi dari login | |
| Klik "Kasbon" → halaman advance | Buka `advances_screen.dart` | |
| Klik "Settlement" → halaman settlement | Buka `settlement_detail_screen.dart` | |
| Klik "Laporan" → halaman report | Buka `report_screen.dart` | |
| Klik "Kategori" → halaman management | Buka `category_management_screen.dart` | |
| Klik "Pengaturan" → halaman settings | Buka `settings_screen.dart` | |
| Klik "Input Revenue" → revenue management | Dari annual report | |
| Klik "Input Pajak" → tax management | Dari annual report | |
| Klik "Input Dividen" → dividend management | Dari annual report | |
| Klik "Input Neraca" → balance sheet settings | Dari annual report | |

### 2.3 Import Paths (Critical!)
| Test | Detail | Status |
|------|--------|--------|
| Tidak ada error merah di VS Code | Cek semua file Dart | |
| `flutter analyze` bersih | Run di terminal | |
| App bisa build tanpa error | `flutter build apk` atau run | |
| Hot reload tidak error | Ubah text di screen manapun | |

**Prioritas:** 🔴 TINGGI - Kalau import salah, app tidak jalan

---

## 🐛 3. BUG FIX: REVENUE COMBINE LOGIC

### 3.1 Combine Manual Revenue
| Test | Detail | Status |
|------|--------|--------|
| Pilih 2 baris dengan Receive Date sama → combine berhasil | Baris berurutan | |
| Pilih 3 baris dengan Receive Date sama → combine berhasil | Baris berurutan | |
| Pilih baris dengan Receive Date berbeda → ERROR | Pesan: "Receive Date harus sama" | |
| Pilih baris tidak berurutan (skip 1 baris di tengah) → ERROR | Pesan: "Baris harus berurutan" | |
| Combine group sudah ada → tidak bisa combine lagi | Pesan: "Lepas combine lama dulu" | |

### 3.2 Consistency UI vs Backend
| Test | Detail | Status |
|------|--------|--------|
| Urutan di UI sama dengan backend | Sort berdasarkan `receive_date` | |
| Pilih baris 1, 2 di UI → backend validasi benar | Tidak ada mismatch | |
| Lepas combine berhasil | Group dihapus | |

**Prioritas:** 🔴 TINGGI - Bug critical, data bisa salah

---

## 🐛 4. BUG FIX: TAX INPUT ANGKA

### 4.1 Parsing Angka Indonesia
| Test | Detail | Status |
|------|--------|--------|
| Input `1.500.000,50` → jadi `1500000.50` | Format Indonesia benar | |
| Input `1500000` → jadi `1500000` | Tanpa separator | |
| Input `1,50` → jadi `1.50` | Desimal saja | |
| Input kosong → jadi `null` | Valid | |
| Input `abc` → ERROR | Pesan: "Angka tidak valid" | |

### 4.2 Format Angka di Dialog
| Test | Detail | Status |
|------|--------|--------|
| Edit tax → angka tampil `1.500.000,00` | Format Indonesia | |
| Edit tax → angka tampil `15.000.000,50` | Dengan desimal | |
| Edit tax → angka tampil `0` | Zero value | |
| Edit tax → angka tampil `-500.000,00` | Negatif | |

### 4.3 Simpan Tax
| Test | Detail | Status |
|------|--------|--------|
| Simpan tax dengan angka format Indonesia | Data tersimpan benar | |
| Cek database → angka benar | Tidak ada corruption | |
| Tampil di list → angka benar | Format konsisten | |

**Prioritas:** 🔴 TINGGI - Uang bisa salah hitung

---

## 🐛 5. BUG FIX: CASCADE DELETE COMBINE GROUP

### 5.1 Delete Row dalam Group (2 rows)
| Test | Detail | Status |
|------|--------|--------|
| Combine 2 rows → jadi group C1 | Buat group | |
| Hapus 1 row dari group | Delete row | |
| Group C1 otomatis terhapus | Tidak ada dangling group | |
| Row lain tetap ada | Data tidak hilang | |

### 5.2 Delete Row dalam Group (3+ rows)
| Test | Detail | Status |
|------|--------|--------|
| Combine 3 rows → jadi group C1 | Buat group | |
| Hapus 1 row dari group | Delete row | |
| Group C1 tetap ada (dengan 2 rows) | Row dihapus dari group | |
| Cek `row_ids_json` → hanya 2 IDs | Data konsisten | |
| 2 rows lain masih bisa di-combine | Tidak error | |

### 5.3 Delete Row Bukan dalam Group
| Test | Detail | Status |
|------|--------|--------|
| Delete row yang tidak di-combine | Normal delete | |
| Group lain tidak terpengaruh | Tidak ada side effect | |
| Data lain tetap utuh | Tidak ada corruption | |

**Prioritas:** 🟡 SEDANG - Data bisa inconsistent

---

## 🐛 6. BUG FIX: TAX DIALOG NUMERIC FORMATTING

### 6.1 Tampilan Dialog Tax
| Test | Detail | Status |
|------|--------|--------|
| Buka dialog tambah tax → field kosong | Clean state | |
| Edit tax existing → Transaction Value terformat | `1.500.000,00` | |
| Edit tax existing → PPN terformat | `165.000.000,00` | |
| Edit tax existing → PPh21 terformat | `3.000.000,00` | |
| Edit tax existing → Currency Exchange terformat | `1,00` atau `15000,00` | |

### 6.2 Input di Dialog
| Test | Detail | Status |
|------|--------|--------|
| Ketik `1500000` → tampil `1.500.000` | Auto-format saat ketik | |
| Ketik `1500000,50` → tampil `1.500.000,50` | Dengan desimal | |
| Hapus semua → field kosong | Valid | |
| Submit dengan format benar | Data tersimpan | |

**Prioritas:** 🟢 RENDAH - UX improvement

---

## 📊 7. EXCEL REPORT - CONSISTENCY CHECK

### 7.1 Revenue Ordering di Excel
| Test | Detail | Status |
|------|--------|--------|
| Export Excel annual report | File terdownload | |
| Buka Excel → revenue urut berdasarkan `Receive Date` | Bukan `Invoice Date` | |
| Urutan di Excel SAMA dengan UI | Konsisten | |
| Merge cell di kolom K (Receive Date) benar | Tidak berantakan | |
| Merge cell di kolom L (Amt Received) benar | Tidak berantakan | |
| Total row benar | Jumlah akurat | |

### 7.2 Tax Ordering di Excel
| Test | Detail | Status |
|------|--------|--------|
| Export Excel annual report | File terdownload | |
| Buka Excel → tax urut berdasarkan `Date` | Konsisten | |
| Merge cell di kolom B (Date) benar | Tidak berantakan | |
| Merge cell di kolom F-Q (nilai pajak) benar | Tidak berantakan | |
| Total row benar | Jumlah akurat | |

### 7.3 Combine Groups di Excel
| Test | Detail | Status |
|------|--------|--------|
| Buat combine group di UI | Group C1 | |
| Export Excel → group C1 ter-merge dengan benar | Cell merge tepat | |
| Nilai di-merge benar (total) | Bukan salah satu nilai | |
| Tanggal di-merge benar | Semua tanggal sama | |

**Prioritas:** 🔴 TINGGI - Report untuk management

---

## 📂 8. RENAME FILE

### 8.1 Frontend File Rename
| Test | Detail | Status |
|------|--------|--------|
| `my_advances_screen.dart` → `advances_screen.dart` | File renamed | |
| Class `MyAdvancesScreen` → `AdvancesScreen` | Class renamed | |
| Import di `dashboard_screen.dart` update | `advance/advances_screen.dart` | |
| App tidak error saat buka halaman Kasbon | Navigation works | |

### 8.2 Widget Rename
| Test | Detail | Status |
|------|--------|--------|
| `settlement_widgets.dart` → `common_widgets.dart` | File renamed | |
| Import di `dashboard_screen.dart` update | `widgets/common_widgets.dart` | |
| Widget tetap berfungsi normal | UI tidak broken | |

**Prioritas:** 🟡 SEDANG - Konsistensi nama

---

## ✅ 9. REGRESSION TEST - FITUR LAMA

### 9.1 Login & Autentikasi
| Test | Detail | Status |
|------|--------|--------|
| Login manager berhasil | Token tersimpan | |
| Login staff berhasil | Token tersimpan | |
| Password salah → error message | Valid | |
| Logout → sesi bersih | Redirect ke login | |
| Re-login setelah logout | Berhasil | |

### 9.2 Kasbon (Advance)
| Test | Detail | Status |
|------|--------|--------|
| Buat kasbon draft | Form valid | |
| Tambah item kasbon | Item tersimpan | |
| Submit kasbon | Status → submitted | |
| Manager approve kasbon | Status → approved | |
| Manager reject kasbon | Status → rejected | |
| Notifikasi terkirim | Bell icon update | |

### 9.3 Settlement
| Test | Detail | Status |
|------|--------|--------|
| Buat settlement draft | Form valid | |
| Tambah expense | Upload bukti | |
| Submit settlement | Status → submitted | |
| Manager approve settlement | Status → approved | |
| Manager reject settlement | Status → rejected | |
| Complete settlement | Status → completed | |

### 9.4 Kategori
| Test | Detail | Status |
|------|--------|--------|
| Manager tambah kategori | Kategori pending | |
| Manager approve kategori | Kategori approved | |
| Staff lihat kategori approved | Hanya approved | |
| Manager edit kategori | Update berhasil | |
| Manager hapus kategori | Cascade delete | |

### 9.5 Dividen
| Test | Detail | Status |
|------|--------|--------|
| Input dividen | Form valid | |
| Hitung profit after tax | Formula benar | |
| Distribusi dividen | Persentase benar | |
| Export PDF dividen | File tergenerate | |

### 9.6 Notifikasi
| Test | Detail | Status |
|------|--------|--------|
| Bell icon ada di header | Visible | |
| Badge unread count benar | Angka akurat | |
| Klik notifikasi → deep link | Navigasi benar | |
| Mark all read → badge hilang | Update UI | |
| Polling berjalan | Real-time update | |

### 9.7 Tema
| Test | Detail | Status |
|------|--------|--------|
| Dark theme → UI gelap | Konsisten | |
| Light theme → UI terang | Konsisten | |
| Toggle theme → update instant | No lag | |
| Restart app → tema tersimpan | Persistent | |

### 9.8 Laporan Summary
| Test | Detail | Status |
|------|--------|--------|
| Filter tahun → data update | Valid | |
| Export PDF summary | File tergenerate | |
| Export Excel summary | File tergenerate | |
| Angka di report akurat | Sesuai database | |

---

## 🚀 10. SMOKE TEST CEPAT (10 MENIT)

Jalankan ini untuk quick check sebelum release:

```
✅ 1. Login manager
✅ 2. Buat kasbon → submit → approve
✅ 3. Buat settlement → submit → approve
✅ 4. Cek notifikasi → deep link bekerja
✅ 5. Combine 2 revenue (Receive Date sama) → berhasil
✅ 6. Combine revenue (Receive Date beda) → ERROR (benar!)
✅ 7. Input tax `1.500.000,50` → tampil `1.500.000,50`
✅ 8. Edit tax → angka terformat benar
✅ 9. Delete row dalam combine group → group update/hapus
✅ 10. Export Excel annual → urutan revenue benar
✅ 11. Toggle dark/light theme → update
✅ 12. flutter analyze → no issues
```

**Semua harus ✅ OK sebelum release!**

---

## 📝 CATATAN PENTING

### Yang TIDAK Berubah (Tetap Sama):
- ✅ Database schema tidak berubah
- ✅ API endpoints tidak berubah
- ✅ Logic dividen tidak berubah
- ✅ Logic settlement tidak berubah
- ✅ Tax combine logic sudah benar dari awal

### Yang Berubah (Hati-hati):
- 🔴 Urutan revenue di Excel (dari `invoice_date` → `receive_date`)
- 🔴 Parsing angka di tax input (format Indonesia)
- 🟡 Cascade delete untuk combine groups
- 🟢 Numeric formatting di tax dialog

### Potensi Side Effects:
- ⚠️ Excel report urutan baris berubah (tapi data tetap sama)
- ⚠️ User terbiasa urutan lama mungkin bingung sebentar
- ✅ Tidak ada data loss
- ✅ Tidak ada API breaking change

---

**Tester:** ___________________  
**Tanggal:** ___________________  
**Status Akhir:** ☐ PASS / ☐ FAIL / ☐ NEED REVIEW
