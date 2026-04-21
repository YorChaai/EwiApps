# Panduan Frontend EWI (Revisi Menyeluruh)

Dokumen ini menjelaskan frontend aktif pada folder `frontend/lib/` setelah revisi terbaru (notifikasi role-based, deep-link notifikasi, perbaikan sinkron kasbon, dan perbaikan tema light/dark).

Tujuan:
- Menjelaskan peran setiap `class` dan fungsi utama (`void/Future/...`) secara kontekstual.
- Menjelaskan alur data dari UI -> Provider -> ApiService -> Backend.
- Menjadi acuan pengembangan tanpa menebak-nebak.

## 1. Arsitektur Frontend Saat Ini

Lapisan utama:
- `screens/`: halaman dan alur UI.
- `providers/`: state management + orkestrasi request.
- `services/`: HTTP client (`ApiService`) + service notifikasi.
- `models/`: model data typed untuk objek tertentu.
- `theme/`: tema aplikasi (light/dark).
- `utils/` dan `widgets/`: helper utilitas dan komponen reusable.

Pola alur:
1. UI memanggil method provider.
2. Provider memanggil `ApiService`.
3. Provider update state (`loading`, `error`, data list/detail).
4. `notifyListeners()` memicu rebuild UI.

## 2. Entry Point dan Tema

### `main.dart`
Class/fungsi:
- `class MyCustomScrollBehavior`: mengatur perilaku scroll lintas platform.
- `buildScrollbar(...)`: membungkus scrollable agar konsisten.
- `main()`: inisialisasi app + provider global.
- `class ExpenseApp`: root widget.
- `build(...)`: `MultiProvider` + `MaterialApp`.

Peran dalam sistem:
- Menentukan provider mana yang global.
- Menentukan tema aktif dari `ThemeProvider`.
- Menentukan `home` awal berdasarkan status login.

### `theme/app_theme.dart`
`class AppTheme`:
- Mendefinisikan palet dark (`surface/card/text`) dan light (`lightSurface/lightCard/lightText...`).
- Menyediakan `darkTheme` dan `lightTheme` lengkap (buttons, inputs, snackbar, scrollbar).

Kapan dipakai:
- Setiap screen/widget membaca `Theme.of(context).brightness` + warna AppTheme agar adaptif.

### `providers/theme_provider.dart`
`class ThemeProvider`:
- Menyimpan mode tema (`light/dark/system`) ke local storage.
Method penting:
- `_loadThemeMode()`: restore mode saat aplikasi start.
- `setThemeMode(mode)`: ganti mode + persist.
- `_parseThemeMode()`: parsing string storage -> enum.

## 3. Autentikasi dan Session

### `providers/auth_provider.dart`
`class AuthProvider`:
- Menyimpan token, user profile, status login, role flags (`isManager`).
Method:
- `_loadToken()`: load token dari storage saat app start.
- `login(username,password)`: request login, set token ke ApiService dan state.
- `logout()`: clear token + reset state.

Kenapa penting:
- Semua keputusan menu/akses UI bergantung pada role dari provider ini.

## 4. Service Layer

### `services/api_service.dart`
`class ApiService`:
- Satu pintu HTTP untuk semua endpoint backend.
- Menangani token auth header, timeout, mapping error message.

Kelompok fungsi:
- Konfigurasi base URL: `loadSavedBaseUrl`, `saveBaseUrl`.
- Token lifecycle: `_loadTokenFromStorage`, `ensureTokenLoaded`, `setToken`.
- CRUD domain: settlement, advance, expense, kategori, revenue, tax, dividen, settings, notifikasi.
- Export: summary/annual/receipt/bulk pdf/excel.
- Utility response: `_handleResponse`, `_networkHint`, `getEvidenceUrl`.

Kapan method dipakai:
- Setiap provider memanggil method spesifik domain dari kelas ini.

### `services/notification_service.dart`
`class NotificationService`:
- Abstraksi pemanggilan API notifikasi (fetch, mark read, count, delete).

## 5. Provider Domain Bisnis

### `providers/settlement_provider.dart`
`class SettlementProvider`:
- Sumber state settlement + expense + kategori.
Method inti:
- List/detail/filter: `loadSettlements`, `loadSettlement`, `clearFilters`.
- Workflow settlement: `createSettlement`, `submitSettlement`, `approveSettlement`, `rejectAllSettlement`, `completeSettlement`, `moveSettlementToDraft`.
- Expense item: `addExpense`, `updateExpense`, `updateExpensePartial`, `deleteExpense`, `bulkDeleteExpenses`, `approveExpense`.
- Kategori: `loadCategories`, `loadPendingCategories`, `createCategory`, `updateCategory`, `deleteCategory`, `approveCategory`.
- Export/report helper: `exportExcel`, `getSummaryPdf`, `getBulkPdf`, `getReceipt`, `getEvidenceUrl`.

Kapan dipakai:
- Dashboard settlement list, settlement detail, kategori, report summary.

### `providers/advance_provider.dart`
`class AdvanceProvider`:
- State kasbon + item kasbon + revisi.
Method inti:
- List/detail: `loadAdvances`, `loadAdvance`.
- Workflow: `createAdvance`, `submitAdvance`, `approveAdvance`, `rejectAdvance`, `startRevision`, `moveAdvanceToDraft`.
- Item kasbon: `addAdvanceItem`, `updateAdvanceItem`, `updateItemPartial`, `deleteAdvanceItem`, `bulkDeleteAdvanceItems`, `approveAdvanceItem`.
- Integrasi: `createSettlementFromAdvance`.
- Export: `exportExcel`, `getBulkPdf`, `getAdvanceReceipt`.

### `providers/revenue_provider.dart`, `tax_provider.dart`
Peran:
- CRUD revenue dan tax dengan pola provider standar (`fetch/create/update/delete`).

### `providers/dividend_provider.dart`
Peran:
- Mengelola payload tahunan dividen+setting neraca.
Method:
- `fetchDividends`, `createDividend`, `updateDividend`, `deleteDividend`, `updateDividendSetting`.

### `providers/notification_provider.dart`
Peran:
- State notifikasi real-time semu (polling interval).
Method:
- `startPolling`, `stopPolling`, `fetchNotifications`, `fetchUnreadNotifications`.
- Aksi: `markAsRead`, `markAllAsRead`, `deleteNotification`, `getUnreadCount`.
- `dispose()`: pastikan timer polling berhenti saat provider dibuang.

## 6. Model Data

### `models/notification_model.dart`
`class NotificationModel`:
- Representasi typed notifikasi dari backend.
Method:
- `fromJson`: parse payload API ke objek.
- `copyWith`: update field tertentu tanpa mutasi langsung.
- `toJson` (jika ada): serialisasi balik saat perlu.

## 7. Screen Utama dan Flow Pengguna

### `screens/login_screen.dart`
Peran:
- Form login dan pemanggilan `AuthProvider.login`.
- Menampilkan error kredensial dan transisi ke dashboard.

### `screens/dashboard_screen.dart`
Peran:
- Shell utama aplikasi manager/staff.
- Menentukan tab/halaman aktif (Settlement, Kasbon, Laporan, Kategori, Pengaturan).
Method penting:
- `_setupNotificationListener` dan `_onNotificationUpdate`: snackbar saat notifikasi baru.
- `_handleNotificationTap(path)`: deep-link notifikasi ke detail settlement/kasbon atau halaman terkait.
- `_fetchBadgeCounts`: update badge sidebar.

Perubahan penting terbaru:
- Perbaikan sinkron kasbon: tidak lagi override filter provider saat pindah menu.
- Warna light/dark dibuat adaptif agar teks tetap terbaca.

### `screens/settlement_detail_screen.dart`
Peran:
- Detail settlement: edit header draft, CRUD expense, approval item/checklist, submit/approve/reject/complete.
Method `void/Future` di kelas ini dipakai untuk:
- Dialog input/edit.
- Validasi form.
- Trigger action workflow via provider.

### `screens/advance/advance_detail_screen.dart`
Peran:
- Detail kasbon: edit header/item, submit, approve/reject, start revisi, generate settlement.
Method penting:
- `_canEditCurrentRevision`, `_canSubmitAdvanceItems`, `_canApproveAdvanceItems`: rule gating tombol aksi.
- `_startRevision`, `_submitAdvance`, `_approveAdvance`: transisi status utama.
- `_showAddItemDialog`, `_showEditAdvanceDialog`: input flow.

### `screens/advance/my_advances_screen.dart`
Peran:
- List kasbon dengan filter status, tahun laporan, rentang tanggal, dan export.
Perubahan terbaru:
- Perbaikan warna light theme.
- Komponen kartu/filter adaptif light/dark.

### `screens/report_screen.dart`
Peran:
- Laporan summary per kategori per bulan.
- Filter tahun + rentang tanggal.
- Export summary PDF/Excel.
Perubahan terbaru:
- Warna tabel, card, dan heading adaptif light theme agar kontras tetap bagus.

### `screens/annual_report_screen.dart`
Peran:
- Menampilkan annual report komprehensif (Revenue, Tax, Expense, Dividend, Neraca ringkas).
- Tombol navigasi ke input revenue/pajak/dividen/neraca.
- Export annual PDF/Excel.
Method internal penting:
- Builder tabel dan formatter nilai/tanggal.
- Grouping expense single/batch dan subkategori.
Perubahan terbaru:
- Tema light/dark adaptif menyeluruh pada card, tabel, appbar, dan teks.

### `screens/dividend_management_screen.dart`
Peran:
- Input daftar penerima dividen + retained profit.
- Menampilkan kalkulasi hasil distribusi otomatis dari backend.

### `screens/balance_sheet_settings_screen.dart`
Peran:
- Input field neraca tahunan (aset, kewajiban, modal, laba ditahan awal).

### `screens/category_management_screen.dart`
Peran:
- Kelola kategori approved + antrian kategori pending.
- Approve/reject kategori pending oleh manager.
Perubahan terbaru:
- Kontras teks light mode diperbaiki dan dialog adaptif tema.

### `screens/settings_screen.dart`
Peran:
- Pengaturan tema aplikasi.
- Default tahun laporan.
- Direktori penyimpanan lampiran.

### `screens/revenue_management_screen.dart` dan `tax_management_screen.dart`
Peran:
- Form CRUD data revenue/pajak.
- Validasi input angka/tanggal dan refresh list.

## 8. Widget Reusable yang Mengikat Alur

### `widgets/notification_bell_icon.dart`
Peran:
- Panel notifikasi overlay.
- Tombol mark all read (centang) dan tombol tutup (X).
- Tombol deep-link per notifikasi (`Buka Settlement/Buka Kasbon`).
Method penting:
- `_showNotificationPanel`: render overlay.
- `_openNotificationTarget`: mark-read + kirim path ke callback dashboard.
- `_buildNotificationItem`: item notifikasi termasuk aksi popup.
Perubahan terbaru:
- Kontras light theme diperbaiki agar teks notifikasi tidak pudar.

### `screens/widgets/sidebar.dart`
Peran:
- Sidebar menu + panel user + badge + tombol notifikasi.
Perubahan terbaru:
- Warna panel/nav/user section adaptif light/dark.

### `screens/widgets/settlement_widgets.dart`
Peran:
- Komponen kartu settlement dan status chip.
Perubahan terbaru:
- Kartu/chip sekarang adaptif tema; teks tetap jelas di light mode.

### `screens/widgets/settlement_detail_widgets.dart`, `page_selector.dart`
Peran:
- Komponen UI pendukung detail dan selector halaman yang dipakai berulang.

## 9. Utility Layer

### `utils/file_helper.dart`
Peran:
- Menentukan lokasi simpan file export.
- Menyimpan bytes -> file -> buka file/folder.
Method penting:
- `saveAndOpenFile`, `saveAndOpenFolder`, `saveFile`, `openFile`, `openExportFolder`.

### `utils/responsive_layout.dart`
Peran:
- Helper breakpoint, spacing, ukuran font, dan wrapper responsive.
Dipakai:
- Hampir semua screen agar tampilan stabil di ukuran window berbeda.

### `utils/app_snackbar.dart`
Peran:
- Standarisasi snackbar success/error/info.

### `utils/currency_formatter.dart`
Peran:
- Format input angka mata uang saat user mengetik.

## 10. Ringkasan Perubahan Krusial Terbaru

1. Notifikasi:
- Manager mendapat notifikasi lintas aktivitas yang relevan.
- Staff/mitra hanya notifikasi milik sendiri.
- Deep-link notifikasi ke settlement/kasbon aktif.
- Panel notifikasi pakai ikon centang + tombol X.

2. Kasbon/Settlement:
- Perbaikan sinkron data list saat filter tahun/status berubah.
- Rule draft vs submitted tetap: draft bisa edit, submitted hanya lihat.

3. Tema:
- Perbaikan kontras menyeluruh di light mode pada screen utama yang sebelumnya masih gelap.
- Warna status alert tetap semantik (success/danger/warning) seperti diminta.

## 11. Protokol Update Dokumentasi Ke Depan

Setiap ada perubahan fitur:
- Update section "Ringkasan Perubahan Krusial".
- Tambahkan perubahan kontrak endpoint di bagian `ApiService`.
- Tambahkan perubahan state di provider terkait.
- Tambahkan skenario uji manual baru di checklist.

