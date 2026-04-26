# Penjelasan Koding Frontend - MiniProjectKPI_EWI (Format Kolom Lengkap)

Dokumen ini memuat `class` serta fungsi `void/def` frontend yang terdeteksi dari source `frontend/lib`.

Legenda prioritas file:
- `???` wajib dibaca (inti alur sistem).
- `??` penting dibaca (modul operasional pendukung).
- `?` opsional (helper/utility/script).

---

## File: `frontend/lib/main.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `MyCustomScrollBehavior` | (baris 17) Class frontend yang menjadi kontainer utama struktur data/logic MyCustomScrollBehavior; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `main` | (baris 44) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | Class | `ExpenseApp` | (baris 48) Class frontend yang menjadi kontainer utama struktur data/logic ExpenseApp; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `build` | (baris 52) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/models/notification_model.dart` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `NotificationModel` | (baris 1) Class frontend yang menjadi kontainer utama struktur data/logic NotificationModel; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `toJson` | (baris 44) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/providers/advance_provider.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AdvanceProvider` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic AdvanceProvider; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `updateToken` | (baris 23) Fungsi utama untuk memperbarui state/data di layer frontend; dipakai agar perubahan user tersimpan dan sinkron. |
| 3 | def | `getBulkPdf` | (baris 328) Fungsi utama untuk membaca/mengambil data di layer frontend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |

---

## File: `frontend/lib/providers/auth_provider.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AuthProvider` | (baris 5) Class frontend yang menjadi kontainer utama struktur data/logic AuthProvider; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `AuthProvider` | (baris 37) Constructor untuk inisialisasi instance AuthProvider; dipakai saat widget/provider dibuat oleh Flutter runtime. |

---

## File: `frontend/lib/providers/dividend_provider.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `DividendProvider` | (baris 5) Class frontend yang menjadi kontainer utama struktur data/logic DividendProvider; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/providers/notification_provider.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `NotificationProvider` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic NotificationProvider; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `NotificationProvider` | (baris 23) Constructor untuk inisialisasi instance NotificationProvider; dipakai saat widget/provider dibuat oleh Flutter runtime. |
| 3 | void | `startPolling` | (baris 28) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 4 | void | `stopPolling` | (baris 42) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 179) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/providers/revenue_provider.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `RevenueProvider` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic RevenueProvider; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/providers/settlement_provider.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `SettlementProvider` | (baris 5) Class frontend yang menjadi kontainer utama struktur data/logic SettlementProvider; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `updateToken` | (baris 59) Fungsi utama untuk memperbarui state/data di layer frontend; dipakai agar perubahan user tersimpan dan sinkron. |
| 3 | void | `clearFilters` | (baris 101) Fungsi utama untuk menghapus atau membersihkan data di layer frontend; dipakai saat koreksi data atau cleanup proses. |
| 4 | def | `getEvidenceUrl` | (baris 480) Fungsi utama untuk membaca/mengambil data di layer frontend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 5 | def | `getReceipt` | (baris 524) Fungsi utama untuk membaca/mengambil data di layer frontend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |

---

## File: `frontend/lib/providers/tax_provider.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `TaxProvider` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic TaxProvider; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/providers/theme_provider.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ThemeProvider` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic ThemeProvider; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `ThemeProvider` | (baris 11) Constructor untuk inisialisasi instance ThemeProvider; dipakai saat widget/provider dibuat oleh Flutter runtime. |
| 3 | def | `_parseThemeMode` | (baris 33) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/advance/advance_detail_screen.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AdvanceDetailScreen` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic AdvanceDetailScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 21) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_AdvanceDetailScreenState` | (baris 24) Class frontend yang menjadi kontainer utama struktur data/logic _AdvanceDetailScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `dispose` | (baris 34) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `initState` | (baris 41) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_statusColor` | (baris 55) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_buildWarningBox` | (baris 142) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_displayAdvanceTitle` | (baris 156) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_hasUncheckedChecklist` | (baris 174) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_canSubmitAdvanceItems` | (baris 180) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_canApproveAdvanceItems` | (baris 185) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | void | `_showAddItemDialog` | (baris 340) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `build` | (baris 762) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 14 | def | `_buildEmptyState` | (baris 1139) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | void | `_displayEvidence` | (baris 1561) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | void | `_deleteItem` | (baris 1693) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | void | `_showChecklistDialog` | (baris 1824) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | def | `_buildChecklistTile` | (baris 1898) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_buildAddCommentButton` | (baris 1917) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_buildSaveChecklistButton` | (baris 1928) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | void | `_showGlobalSnackBar` | (baris 1957) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | Class | `_SummaryCard` | (baris 1966) Class frontend yang menjadi kontainer utama struktur data/logic _SummaryCard; dipakai sebagai pusat perilaku pada modul terkait. |
| 23 | def | `build` | (baris 1980) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/advance/my_advances_screen.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `MyAdvancesScreen` | (baris 10) Class frontend yang menjadi kontainer utama struktur data/logic MyAdvancesScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 14) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_MyAdvancesScreenState` | (baris 17) Class frontend yang menjadi kontainer utama struktur data/logic _MyAdvancesScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 22) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_cardColor` | (baris 24) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_surfaceColor` | (baris 26) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_dividerColor` | (baris 28) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_titleColor` | (baris 30) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_bodyColor` | (baris 32) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_primaryText` | (baris 34) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | void | `_clearDateRange` | (baris 57) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | void | `_reloadAdvances` | (baris 65) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | void | `initState` | (baris 170) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | void | `_showCreateDialog` | (baris 177) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `build` | (baris 360) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 16 | Class | `_FilterChip` | (baris 723) Class frontend yang menjadi kontainer utama struktur data/logic _FilterChip; dipakai sebagai pusat perilaku pada modul terkait. |
| 17 | def | `build` | (baris 735) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 18 | Class | `_AdvanceCard` | (baris 767) Class frontend yang menjadi kontainer utama struktur data/logic _AdvanceCard; dipakai sebagai pusat perilaku pada modul terkait. |
| 19 | def | `createState` | (baris 779) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 20 | Class | `_AdvanceCardState` | (baris 782) Class frontend yang menjadi kontainer utama struktur data/logic _AdvanceCardState; dipakai sebagai pusat perilaku pada modul terkait. |
| 21 | def | `_isDark` | (baris 784) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `_cardColor` | (baris 786) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `_hoverColor` | (baris 788) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `_dividerColor` | (baris 790) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | def | `_titleColor` | (baris 792) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `_primaryText` | (baris 794) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | def | `_bodyColor` | (baris 796) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `_statusColor` | (baris 799) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 29 | def | `build` | (baris 825) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 30 | Class | `_StatusBadge` | (baris 945) Class frontend yang menjadi kontainer utama struktur data/logic _StatusBadge; dipakai sebagai pusat perilaku pada modul terkait. |
| 31 | def | `build` | (baris 952) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 32 | def | `_formatNumber` | (baris 971) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/annual_report_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AnnualReportScreen` | (baris 11) Class frontend yang menjadi kontainer utama struktur data/logic AnnualReportScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 15) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_AnnualReportScreenState` | (baris 18) Class frontend yang menjadi kontainer utama struktur data/logic _AnnualReportScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 39) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_cardColor` | (baris 41) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_surfaceColor` | (baris 43) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_dividerColor` | (baris 45) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_titleColor` | (baris 47) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_bodyColor` | (baris 49) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | void | `initState` | (baris 53) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_toDouble` | (baris 159) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_fmtNumber` | (baris 164) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_fmtMoney` | (baris 169) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_fmtDate` | (baris 184) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_parseDate` | (baris 190) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `_extractImportedRow` | (baris 196) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `_extractImportedSheetRow` | (baris 207) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | def | `_extractBatchNumber` | (baris 218) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_isBatchSettlement` | (baris 227) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_cleanSettlementTitle` | (baris 238) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `_expenseCategoryIndex` | (baris 341) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `_expenseSubcategoryLabel` | (baris 391) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `_isNumericHeader` | (baris 428) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `_isCenterColumn` | (baris 443) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | def | `_columnAlignment` | (baris 448) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `_buildCacheInfo` | (baris 560) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | def | `_buildInputButtons` | (baris 586) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `_buildDisplayTables` | (baris 664) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 29 | def | `build` | (baris 1023) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 30 | def | `_buildSummaryCards` | (baris 1089) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 31 | def | `_buildCard` | (baris 1134) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/balance_sheet_settings_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `BalanceSheetSettingsScreen` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic BalanceSheetSettingsScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_BalanceSheetSettingsScreenState` | (baris 17) Class frontend yang menjadi kontainer utama struktur data/logic _BalanceSheetSettingsScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 34) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 41) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_toDouble` | (baris 93) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_formatPlain` | (baris 113) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_field` | (baris 159) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `build` | (baris 171) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/category_management_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `CategoryManagementView` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic CategoryManagementView; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 11) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_CategoryManagementViewState` | (baris 14) Class frontend yang menjadi kontainer utama struktur data/logic _CategoryManagementViewState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 15) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_surfaceColor` | (baris 17) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_cardColor` | (baris 19) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_dividerColor` | (baris 21) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_titleColor` | (baris 23) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_primaryText` | (baris 25) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_bodyText` | (baris 27) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | void | `initState` | (baris 31) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `build` | (baris 39) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 13 | def | `_buildCategoryTile` | (baris 222) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_buildPendingItem` | (baris 304) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | void | `_showAddCategoryDialog` | (baris 404) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | void | `_showEditCategoryDialog` | (baris 550) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/dashboard_screen.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `DashboardScreen` | (baris 22) Class frontend yang menjadi kontainer utama struktur data/logic DashboardScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 26) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_DashboardScreenState` | (baris 29) Class frontend yang menjadi kontainer utama struktur data/logic _DashboardScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 35) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_surfaceColor` | (baris 37) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_dividerColor` | (baris 39) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_bodyText` | (baris 41) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | void | `initState` | (baris 45) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | void | `_setupNotificationListener` | (baris 59) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | void | `_onNotificationUpdate` | (baris 64) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | void | `_showNotificationSnackBar` | (baris 78) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | void | `dispose` | (baris 87) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_extractIdFromPath` | (baris 105) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `build` | (baris 159) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 15 | Class | `_SettlementListView` | (baris 265) Class frontend yang menjadi kontainer utama struktur data/logic _SettlementListView; dipakai sebagai pusat perilaku pada modul terkait. |
| 16 | def | `createState` | (baris 269) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 17 | Class | `_SettlementListViewState` | (baris 272) Class frontend yang menjadi kontainer utama struktur data/logic _SettlementListViewState; dipakai sebagai pusat perilaku pada modul terkait. |
| 18 | def | `_isDark` | (baris 279) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_cardColor` | (baris 281) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_surfaceColor` | (baris 283) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `_dividerColor` | (baris 285) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `_titleColor` | (baris 287) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `_bodyColor` | (baris 289) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `_primaryText` | (baris 291) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | void | `initState` | (baris 295) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | void | `_clearDateRange` | (baris 355) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | void | `_reloadSettlements` | (baris 363) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `build` | (baris 456) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 29 | void | `_showCreateDialog` | (baris 952) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 30 | def | `_buildSummaryCards` | (baris 1148) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/dividend_management_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `DividendManagementScreen` | (baris 8) Class frontend yang menjadi kontainer utama struktur data/logic DividendManagementScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 14) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_DividendManagementScreenState` | (baris 18) Class frontend yang menjadi kontainer utama struktur data/logic _DividendManagementScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 24) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 31) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_toDouble` | (baris 49) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_fmtMoney` | (baris 70) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_formatPlain` | (baris 84) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_buildCalculationCard` | (baris 309) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `metric` | (baris 321) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `build` | (baris 403) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/login_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `LoginScreen` | (baris 9) Class frontend yang menjadi kontainer utama struktur data/logic LoginScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_LoginScreenState` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic _LoginScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 28) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 43) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `build` | (baris 127) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 7 | Class | `_PortraitLoginContent` | (baris 222) Class frontend yang menjadi kontainer utama struktur data/logic _PortraitLoginContent; dipakai sebagai pusat perilaku pada modul terkait. |
| 8 | def | `build` | (baris 246) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 9 | Class | `_LandscapeLoginContent` | (baris 316) Class frontend yang menjadi kontainer utama struktur data/logic _LandscapeLoginContent; dipakai sebagai pusat perilaku pada modul terkait. |
| 10 | def | `build` | (baris 338) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 11 | Class | `_LandscapeIntroPanel` | (baris 388) Class frontend yang menjadi kontainer utama struktur data/logic _LandscapeIntroPanel; dipakai sebagai pusat perilaku pada modul terkait. |
| 12 | def | `build` | (baris 398) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 13 | def | `_serverLabel` | (baris 443) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | Class | `_LoginBrandIcon` | (baris 445) Class frontend yang menjadi kontainer utama struktur data/logic _LoginBrandIcon; dipakai sebagai pusat perilaku pada modul terkait. |
| 15 | def | `build` | (baris 455) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 16 | Class | `_UsernameField` | (baris 474) Class frontend yang menjadi kontainer utama struktur data/logic _UsernameField; dipakai sebagai pusat perilaku pada modul terkait. |
| 17 | def | `build` | (baris 480) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 18 | Class | `_PasswordField` | (baris 497) Class frontend yang menjadi kontainer utama struktur data/logic _PasswordField; dipakai sebagai pusat perilaku pada modul terkait. |
| 19 | def | `build` | (baris 511) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 20 | Class | `_LoginButton` | (baris 537) Class frontend yang menjadi kontainer utama struktur data/logic _LoginButton; dipakai sebagai pusat perilaku pada modul terkait. |
| 21 | def | `build` | (baris 547) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 22 | Class | `_LoginHintCard` | (baris 568) Class frontend yang menjadi kontainer utama struktur data/logic _LoginHintCard; dipakai sebagai pusat perilaku pada modul terkait. |
| 23 | def | `build` | (baris 574) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/manager/manager_dashboard_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ManagerDashboardScreen` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic ManagerDashboardScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 11) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_ManagerDashboardScreenState` | (baris 14) Class frontend yang menjadi kontainer utama struktur data/logic _ManagerDashboardScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 19) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 29) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `build` | (baris 35) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 7 | def | `_buildSettlementsForApproval` | (baris 67) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_buildAdvancesForApproval` | (baris 127) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/manager/manager_settlement_detail_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ManagerSettlementDetailScreen` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic ManagerSettlementDetailScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_ManagerSettlementDetailScreenState` | (baris 17) Class frontend yang menjadi kontainer utama struktur data/logic _ManagerSettlementDetailScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_toDouble` | (baris 27) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_formatExpenseAmount` | (baris 32) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | void | `initState` | (baris 44) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `build` | (baris 52) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 8 | def | `_buildSettlementInfo` | (baris 119) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_buildExpensesList` | (baris 160) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_buildApprovalActions` | (baris 291) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_getStatusColor` | (baris 353) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_getIconForStatus` | (baris 367) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/report_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ReportScreen` | (baris 9) Class frontend yang menjadi kontainer utama struktur data/logic ReportScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_ReportScreenState` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic _ReportScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 39) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_cardColor` | (baris 41) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_surfaceColor` | (baris 43) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_dividerColor` | (baris 45) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_titleColor` | (baris 47) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_bodyColor` | (baris 49) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_primaryText` | (baris 51) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | void | `dispose` | (baris 55) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | void | `initState` | (baris 62) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | void | `_clearDateRange` | (baris 112) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `build` | (baris 121) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 15 | def | `_buildHeaderInfo` | (baris 169) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `_buildActions` | (baris 197) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `_buildSummaryTable` | (baris 263) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/revenue_management_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `RevenueManagementScreen` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic RevenueManagementScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_RevenueManagementScreenState` | (baris 17) Class frontend yang menjadi kontainer utama struktur data/logic _RevenueManagementScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 22) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_toDouble` | (baris 59) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `build` | (baris 337) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/settings_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `SettingsScreen` | (baris 8) Class frontend yang menjadi kontainer utama struktur data/logic SettingsScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 12) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_SettingsScreenState` | (baris 15) Class frontend yang menjadi kontainer utama struktur data/logic _SettingsScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 23) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 130) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_themeLabel` | (baris 135) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_isDark` | (baris 146) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_cardColor` | (baris 149) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_surfaceColor` | (baris 152) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_dividerColor` | (baris 155) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_titleColor` | (baris 158) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_bodyColor` | (baris 161) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_buildThemeSettingsCard` | (baris 164) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_buildStorageSettingsCard` | (baris 241) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_buildReportYearSettingsCard` | (baris 336) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `build` | (baris 417) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/settlement_detail_screen.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `SettlementDetailScreen` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic SettlementDetailScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 21) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_SettlementDetailScreenState` | (baris 24) Class frontend yang menjadi kontainer utama struktur data/logic _SettlementDetailScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 32) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | void | `dispose` | (baris 43) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_statusColor` | (baris 49) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_toDouble` | (baris 68) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_formatExpenseAmount` | (baris 73) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_displaySettlementStatus` | (baris 84) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_displaySettlementTitle` | (baris 88) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_hasUncheckedChecklist` | (baris 113) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_canSubmitSettlementItems` | (baris 119) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_canApproveSettlementItems` | (baris 124) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `build` | (baris 133) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 15 | void | `_showAddExpenseDialog` | (baris 739) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | void | `_showEvidence` | (baris 1225) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | void | `_showEditSettlementDialog` | (baris 1810) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | void | `_showEditExpenseDialog` | (baris 1884) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_buildChecklistTile` | (baris 2497) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_buildAddCommentButton` | (baris 2516) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `_buildSaveChecklistButton` | (baris 2527) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/tax_management_screen.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `TaxManagementScreen` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic TaxManagementScreen; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_TaxManagementScreenState` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic _TaxManagementScreenState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | void | `initState` | (baris 21) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_toDouble` | (baris 37) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `build` | (baris 311) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/widgets/page_selector.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `PageSelector` | (baris 5) Class frontend yang menjadi kontainer utama struktur data/logic PageSelector; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `_getPageName` | (baris 17) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `build` | (baris 27) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 4 | def | `_buildItem` | (baris 82) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/screens/widgets/settlement_detail_widgets.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `SummaryCard` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic SummaryCard; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `build` | (baris 19) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 3 | Class | `SettlementActionButton` | (baris 74) Class frontend yang menjadi kontainer utama struktur data/logic SettlementActionButton; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `build` | (baris 91) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/widgets/settlement_widgets.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `formatNumber` | (baris 4) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | Class | `StatusFilterChip` | (baris 15) Class frontend yang menjadi kontainer utama struktur data/logic StatusFilterChip; dipakai sebagai pusat perilaku pada modul terkait. |
| 3 | def | `build` | (baris 28) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 4 | Class | `SettlementCard` | (baris 60) Class frontend yang menjadi kontainer utama struktur data/logic SettlementCard; dipakai sebagai pusat perilaku pada modul terkait. |
| 5 | def | `createState` | (baris 75) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 6 | Class | `_SettlementCardState` | (baris 78) Class frontend yang menjadi kontainer utama struktur data/logic _SettlementCardState; dipakai sebagai pusat perilaku pada modul terkait. |
| 7 | def | `_isDark` | (baris 80) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_cardColor` | (baris 82) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_hoverColor` | (baris 84) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_dividerColor` | (baris 86) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_titleColor` | (baris 88) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_primaryText` | (baris 90) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_bodyText` | (baris 92) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_getDisplayTitle` | (baris 95) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_statusColor` | (baris 120) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `build` | (baris 138) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 17 | Class | `StatusBadge` | (baris 272) Class frontend yang menjadi kontainer utama struktur data/logic StatusBadge; dipakai sebagai pusat perilaku pada modul terkait. |
| 18 | def | `build` | (baris 279) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/screens/widgets/sidebar.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `DashboardSidebar` | (baris 6) Class frontend yang menjadi kontainer utama struktur data/logic DashboardSidebar; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `build` | (baris 39) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 3 | Class | `_SidebarNavItem` | (baris 219) Class frontend yang menjadi kontainer utama struktur data/logic _SidebarNavItem; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `createState` | (baris 239) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 5 | Class | `_SidebarNavItemState` | (baris 242) Class frontend yang menjadi kontainer utama struktur data/logic _SidebarNavItemState; dipakai sebagai pusat perilaku pada modul terkait. |
| 6 | def | `build` | (baris 246) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 7 | Class | `_ExpandedUserPanel` | (baris 371) Class frontend yang menjadi kontainer utama struktur data/logic _ExpandedUserPanel; dipakai sebagai pusat perilaku pada modul terkait. |
| 8 | def | `build` | (baris 387) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 9 | Class | `_MiniUserPanel` | (baris 479) Class frontend yang menjadi kontainer utama struktur data/logic _MiniUserPanel; dipakai sebagai pusat perilaku pada modul terkait. |
| 10 | def | `build` | (baris 495) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 11 | Class | `_BadgePill` | (baris 550) Class frontend yang menjadi kontainer utama struktur data/logic _BadgePill; dipakai sebagai pusat perilaku pada modul terkait. |
| 12 | def | `build` | (baris 556) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 13 | Class | `_BadgeDot` | (baris 575) Class frontend yang menjadi kontainer utama struktur data/logic _BadgeDot; dipakai sebagai pusat perilaku pada modul terkait. |
| 14 | def | `build` | (baris 577) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 15 | Class | `_SquareIconBtn` | (baris 595) Class frontend yang menjadi kontainer utama struktur data/logic _SquareIconBtn; dipakai sebagai pusat perilaku pada modul terkait. |
| 16 | def | `build` | (baris 607) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/services/api_service.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ApiService` | (baris 8) Class frontend yang menjadi kontainer utama struktur data/logic ApiService; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `ApiService` | (baris 60) Constructor untuk inisialisasi instance ApiService; dipakai saat widget/provider dibuat oleh Flutter runtime. |
| 3 | void | `setToken` | (baris 82) Fungsi utama untuk memperbarui state/data di layer frontend; dipakai agar perubahan user tersimpan dan sinkron. |
| 4 | def | `getAuthHeaders` | (baris 96) Fungsi utama untuk membaca/mengambil data di layer frontend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 5 | def | `getEvidenceUrl` | (baris 854) Fungsi utama untuk membaca/mengambil data di layer frontend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 6 | def | `_handleResponse` | (baris 1079) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_networkHint` | (baris 1103) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/services/notification_service.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `NotificationService` | (baris 6) Class frontend yang menjadi kontainer utama struktur data/logic NotificationService; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/theme/app_theme.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AppTheme` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic AppTheme; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/utils/app_snackbar.dart` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AppSnackbar` | (baris 12) Class frontend yang menjadi kontainer utama struktur data/logic AppSnackbar; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | void | `success` | (baris 36) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | void | `error` | (baris 37) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/utils/currency_formatter.dart` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `CurrencyInputFormatter` | (baris 4) Class frontend yang menjadi kontainer utama struktur data/logic CurrencyInputFormatter; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `frontend/lib/utils/file_helper.dart` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `FileHelper` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic FileHelper; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `_ensureTimestampedFilename` | (baris 130) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `formatTimestamp` | (baris 166) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `frontend/lib/utils/responsive_layout.dart` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `ResponsiveLayout` | (baris 11) Class frontend yang menjadi kontainer utama struktur data/logic ResponsiveLayout; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `mq` | (baris 28) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `screenSize` | (baris 30) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `width` | (baris 32) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `height` | (baris 34) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `orientation` | (baris 36) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `isPortrait` | (baris 38) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `isLandscape` | (baris 41) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `isCompactPhone` | (baris 44) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `isMobile` | (baris 47) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `isTablet` | (baris 50) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `isDesktop` | (baris 53) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `isPhoneLandscape` | (baris 58) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `isWide` | (baris 63) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `isShortHeight` | (baris 66) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `isVeryShortHeight` | (baris 68) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `safeWidth` | (baris 70) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | def | `safeHeight` | (baris 75) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `horizontalPadding` | (baris 83) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `verticalPadding` | (baris 94) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `gapXS` | (baris 102) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `gapS` | (baris 107) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `gapM` | (baris 113) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `gapL` | (baris 119) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | def | `sidePanelWidth` | (baris 125) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `pagePadding` | (baris 179) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | def | `shouldUseCompactControls` | (baris 186) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `shouldStackHeaderActions` | (baris 190) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 29 | def | `build` | (baris 195) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 30 | Class | `ResponsivePage` | (baris 216) Class frontend yang menjadi kontainer utama struktur data/logic ResponsivePage; dipakai sebagai pusat perilaku pada modul terkait. |
| 31 | def | `build` | (baris 233) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |
| 32 | Class | `ResponsiveScrollView` | (baris 257) Class frontend yang menjadi kontainer utama struktur data/logic ResponsiveScrollView; dipakai sebagai pusat perilaku pada modul terkait. |
| 33 | def | `build` | (baris 272) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/widgets/app_brand_logo.dart` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `AppBrandLogo` | (baris 3) Class frontend yang menjadi kontainer utama struktur data/logic AppBrandLogo; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `build` | (baris 20) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---

## File: `frontend/lib/widgets/notification_bell_icon.dart` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `NotificationBellIcon` | (baris 7) Class frontend yang menjadi kontainer utama struktur data/logic NotificationBellIcon; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `createState` | (baris 13) Fungsi utama untuk membuat data/proses baru di layer frontend; dipakai saat user memulai dokumen/alur baru. |
| 3 | Class | `_NotificationBellIconState` | (baris 16) Class frontend yang menjadi kontainer utama struktur data/logic _NotificationBellIconState; dipakai sebagai pusat perilaku pada modul terkait. |
| 4 | def | `_isDark` | (baris 20) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_cardColor` | (baris 22) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_dividerColor` | (baris 24) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_titleColor` | (baris 26) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_bodyColor` | (baris 28) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | void | `_closeNotificationPanel` | (baris 31) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | void | `initState` | (baris 40) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | void | `dispose` | (baris 53) Fungsi utama pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | void | `_toggleNotificationPanel` | (baris 59) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | void | `_showNotificationPanel` | (baris 68) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_hasNavigablePath` | (baris 235) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_openButtonLabel` | (baris 241) Helper internal pada layer frontend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `build` | (baris 387) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer frontend; dipakai agar format data dan hasil export konsisten. |

---
