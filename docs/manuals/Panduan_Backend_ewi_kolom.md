# Penjelasan Koding Backend - MiniProjectKPI_EWI (Format Kolom Lengkap)

Dokumen ini memuat semua `class` dan `def` backend yang terdeteksi dari source aktif (di luar `venv`, `migrations`, `__pycache__`, `_archive`).

Legenda prioritas file:
- `???` wajib dibaca (inti alur sistem).
- `??` penting dibaca (modul operasional pendukung).
- `?` opsional (helper/utility/script).

---

## File: `backend/app.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `create_app` | (baris 14) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 2 | def | `_extract_sqlite_path` | (baris 77) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_looks_hashed` | (baris 84) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `ensure_advance_type_column` | (baris 91) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 5 | def | `_ensure_column` | (baris 113) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `ensure_advance_revision_schema` | (baris 123) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 7 | def | `ensure_expense_advance_link_schema` | (baris 144) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 8 | def | `ensure_settlement_status_compatibility` | (baris 158) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 9 | def | `ensure_bank_subcategory` | (baris 179) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 10 | def | `ensure_rental_tool_subcategory` | (baris 237) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 11 | def | `ensure_dividends_table` | (baris 294) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 12 | def | `bootstrap_from_database_new` | (baris 365) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 13 | def | `seed_data` | (baris 729) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |

---

## File: `backend/config.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `Config` | (baris 9) Class backend yang menjadi kontainer utama struktur data/logic Config; dipakai sebagai pusat perilaku pada modul terkait. |

---

## File: `backend/fix_existing_titles.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `fix_all_titles` | (baris 7) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/migrate_evidence.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `upgrade` | (baris 3) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/models.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | Class | `User` | (baris 9) Class backend yang menjadi kontainer utama struktur data/logic User; dipakai sebagai pusat perilaku pada modul terkait. |
| 2 | def | `set_password` | (baris 21) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 3 | def | `check_password` | (baris 24) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `to_dict` | (baris 27) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 5 | Class | `Category` | (baris 37) Class backend yang menjadi kontainer utama struktur data/logic Category; dipakai sebagai pusat perilaku pada modul terkait. |
| 6 | def | `full_name` | (baris 50) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `to_dict` | (baris 55) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 8 | Class | `Advance` | (baris 70) Class backend yang menjadi kontainer utama struktur data/logic Advance; dipakai sebagai pusat perilaku pada modul terkait. |
| 9 | def | `total_amount` | (baris 89) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `approved_amount` | (baris 93) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 11 | def | `base_amount` | (baris 101) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `revision_amount` | (baris 109) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `max_revision_no` | (baris 113) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `to_dict` | (baris 117) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 15 | Class | `AdvanceItem` | (baris 187) Class backend yang menjadi kontainer utama struktur data/logic AdvanceItem; dipakai sebagai pusat perilaku pada modul terkait. |
| 16 | def | `to_dict` | (baris 207) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 17 | Class | `Settlement` | (baris 236) Class backend yang menjadi kontainer utama struktur data/logic Settlement; dipakai sebagai pusat perilaku pada modul terkait. |
| 18 | def | `total_amount` | (baris 255) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `approved_amount` | (baris 259) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 20 | def | `to_dict` | (baris 262) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 21 | Class | `Expense` | (baris 312) Class backend yang menjadi kontainer utama struktur data/logic Expense; dipakai sebagai pusat perilaku pada modul terkait. |
| 22 | def | `idr_amount` | (baris 334) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `idr_amount` | (baris 341) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `to_dict` | (baris 347) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 25 | Class | `Revenue` | (baris 378) Class backend yang menjadi kontainer utama struktur data/logic Revenue; dipakai sebagai pusat perilaku pada modul terkait. |
| 26 | def | `idr_invoice_value` | (baris 397) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | def | `idr_amount_received` | (baris 403) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `to_dict` | (baris 410) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 29 | Class | `Tax` | (baris 430) Class backend yang menjadi kontainer utama struktur data/logic Tax; dipakai sebagai pusat perilaku pada modul terkait. |
| 30 | def | `idr_transaction_value` | (baris 448) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 31 | def | `to_dict` | (baris 453) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 32 | Class | `Dividend` | (baris 469) Class backend yang menjadi kontainer utama struktur data/logic Dividend; dipakai sebagai pusat perilaku pada modul terkait. |
| 33 | def | `to_dict` | (baris 479) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 34 | Class | `DividendSetting` | (baris 491) Class backend yang menjadi kontainer utama struktur data/logic DividendSetting; dipakai sebagai pusat perilaku pada modul terkait. |
| 35 | def | `to_dict` | (baris 511) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 36 | Class | `Notification` | (baris 533) Class backend yang menjadi kontainer utama struktur data/logic Notification; dipakai sebagai pusat perilaku pada modul terkait. |
| 37 | def | `to_dict` | (baris 549) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |

---

## File: `backend/routes/advances.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `allowed_file` | (baris 16) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_advance_view_status_filter` | (baris 24) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_editable_revision_no` | (baris 32) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `_items_for_revision` | (baris 40) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_settlement_blocks_revision` | (baris 47) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_sync_revision_items_to_settlement` | (baris 52) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_next_revision_no` | (baris 85) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_status_after_approval` | (baris 89) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_parse_checklist_notes` | (baris 93) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_has_unchecked_checklist` | (baris 117) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `list_advances` | (baris 124) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 12 | def | `create_advance` | (baris 180) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 13 | def | `get_advance` | (baris 212) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 14 | def | `update_advance` | (baris 225) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 15 | def | `delete_advance` | (baris 249) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 16 | def | `start_revision` | (baris 265) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 17 | def | `add_advance_item` | (baris 287) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 18 | def | `update_advance_item` | (baris 378) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 19 | def | `delete_advance_item` | (baris 461) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 20 | def | `submit_advance` | (baris 485) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 21 | def | `approve_advance` | (baris 533) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 22 | def | `reject_advance` | (baris 592) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 23 | def | `create_settlement_from_advance` | (baris 624) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 24 | def | `approve_advance_item` | (baris 679) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 25 | def | `_merge_rejection_notes_advance` | (baris 695) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `reject_advance_item` | (baris 740) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 27 | def | `bulk_delete_advance_items` | (baris 767) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `move_advance_to_draft` | (baris 803) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |

---

## File: `backend/routes/auth.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `login` | (baris 9) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `me` | (baris 30) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `list_users` | (baris 40) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 4 | def | `create_user` | (baris 51) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |

---

## File: `backend/routes/categories.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `list_categories` | (baris 11) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 2 | def | `list_pending` | (baris 29) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 3 | def | `create_category` | (baris 43) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 4 | def | `update_category` | (baris 112) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 5 | def | `delete_category` | (baris 132) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 6 | def | `approve_category` | (baris 158) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |

---

## File: `backend/routes/dashboard.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `get_summary` | (baris 15) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |

---

## File: `backend/routes/dividends.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_parse_date` | (baris 11) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_compute_profit_after_tax` | (baris 20) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_build_dividend_payload` | (baris 57) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `get_dividends` | (baris 94) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 5 | def | `get_dividend` | (baris 104) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 6 | def | `create_dividend` | (baris 111) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 7 | def | `update_dividend` | (baris 150) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 8 | def | `update_dividend_setting` | (baris 179) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 9 | def | `delete_dividend` | (baris 205) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |

---

## File: `backend/routes/expenses.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `allowed_file` | (baris 13) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_parse_checklist_notes` | (baris 18) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `create_expense` | (baris 44) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 4 | def | `update_expense` | (baris 126) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 5 | def | `bulk_delete_expenses` | (baris 208) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `delete_expense` | (baris 247) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 7 | def | `approve_expense` | (baris 270) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 8 | def | `_merge_rejection_notes` | (baris 301) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `reject_expense` | (baris 346) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 10 | def | `serve_evidence` | (baris 369) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `list_categories` | (baris 376) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |

---

## File: `backend/routes/notifications.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `get_notifications` | (baris 11) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 2 | def | `_can_access_notification` | (baris 56) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `mark_notification_as_read` | (baris 67) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 4 | def | `mark_all_notifications_as_read` | (baris 96) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 5 | def | `delete_notification` | (baris 118) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 6 | def | `get_unread_count` | (baris 146) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 7 | def | `create_notification` | (baris 165) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 8 | def | `notify_managers` | (baris 187) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `notify_staff` | (baris 202) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/routes/reports/annual.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_extract_expense_subcategory` | (baris 65) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_normalize_subtitle` | (baris 75) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_mapped_expense_subcategory_from_text` | (baris 83) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `_single_summary_subcategory` | (baris 120) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_expense_column_mapping_name` | (baris 147) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_clone_row_format` | (baris 161) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_is_true` | (baris 178) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_annual_cache_paths` | (baris 184) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_load_annual_payload_cache` | (baris 195) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_save_annual_payload_cache` | (baris 203) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_save_annual_pdf_cache` | (baris 212) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_tagged_ids_for_year` | (baris 219) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_has_any_report_tags` | (baris 231) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_compute_dividend_distribution` | (baris 239) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_build_annual_payload_from_db` | (baris 262) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `_build_annual_pdf_bytes` | (baris 374) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `_sheet_ref` | (baris 487) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | def | `_write_secondary_summary_sheets` | (baris 491) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_operation_cost_totals_by_column` | (baris 565) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_sync_formatted_secondary_sheets` | (baris 582) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `_clone_sheet_from_template` | (baris 715) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `_ensure_formatted_secondary_sheets` | (baris 737) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `get_annual_report` | (baris 757) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 24 | def | `get_annual_report_pdf` | (baris 769) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 25 | def | `get_annual_report_excel` | (baris 780) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |

---

## File: `backend/routes/reports/helpers.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_default_report_year` | (baris 9) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_safe_set_cell` | (baris 13) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_safe_set_number` | (baris 21) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `_normalize_external_formula_refs` | (baris 30) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 5 | def | `_clear_range` | (baris 46) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 6 | def | `_clear_data_keep_formulas` | (baris 55) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 7 | def | `_set_rows_hidden` | (baris 66) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `_safe_text` | (baris 73) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 9 | def | `_extract_imported_row` | (baris 79) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 10 | def | `_extract_imported_sheet_row` | (baris 90) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 11 | def | `_is_date_like` | (baris 101) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 12 | def | `_is_template_detail_data_row` | (baris 118) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 13 | def | `_map_expense_category_index` | (baris 122) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `_map_expense_category_index_from_name` | (baris 147) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 15 | def | `_pick_template_formula_col` | (baris 170) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 16 | def | `_write_expense_line` | (baris 178) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `_write_expense_detail_line` | (baris 192) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 18 | def | `_get_expense_blocks` | (baris 203) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `_parse_iso_date` | (baris 222) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `_to_float` | (baris 231) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `_as_iso_date` | (baris 242) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `_idr_from_currency` | (baris 249) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 23 | def | `_shorten` | (baris 258) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `_map_expense_column` | (baris 263) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | def | `_extract_batch_number` | (baris 286) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `_is_batch_settlement` | (baris 297) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 27 | def | `_clean_settlement_title` | (baris 306) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 28 | def | `_group_annual_expenses` | (baris 317) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/routes/reports/summary.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_display_settlement_status` | (baris 20) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_get_summary_approved_expenses` | (baris 24) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_build_summary_payload` | (baris 35) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `get_summary_report` | (baris 55) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 5 | def | `export_summary_pdf` | (baris 71) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 6 | def | `generate_excel_report` | (baris 120) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 7 | def | `generate_excel_advance_report` | (baris 175) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 8 | def | `generate_pdf_advance_report` | (baris 218) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 9 | def | `generate_settlement_receipt` | (baris 246) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 10 | def | `generate_bulk_settlements_pdf` | (baris 278) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 11 | def | `generate_bulk_advances_pdf` | (baris 314) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |

---

## File: `backend/routes/revenues.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_parse_date` | (baris 8) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `get_revenues` | (baris 18) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 3 | def | `get_revenue` | (baris 42) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 4 | def | `create_revenue` | (baris 48) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 5 | def | `update_revenue` | (baris 89) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 6 | def | `delete_revenue` | (baris 133) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |

---

## File: `backend/routes/settings.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `manage_storage` | (baris 10) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `manage_report_year` | (baris 77) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/routes/settlements.py` [???]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_sync_advance_after_settlement` | (baris 13) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `_parse_checklist_notes` | (baris 20) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `_has_unchecked_checklist` | (baris 44) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 4 | def | `list_settlements` | (baris 51) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 5 | def | `create_settlement` | (baris 126) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 6 | def | `get_settlement` | (baris 195) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 7 | def | `update_settlement` | (baris 208) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 8 | def | `update_expense` | (baris 228) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 9 | def | `delete_settlement` | (baris 255) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 10 | def | `submit_settlement` | (baris 282) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 11 | def | `approve_settlement` | (baris 320) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 12 | def | `complete_settlement` | (baris 350) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 13 | def | `_merge_rejection_notes_settlement` | (baris 379) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `reject_all_expenses` | (baris 424) Fungsi utama untuk transisi workflow approval di layer backend; dipakai untuk kontrol status bisnis antar role. |
| 15 | def | `move_to_draft` | (baris 455) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |

---

## File: `backend/routes/taxes.py` [??]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `_parse_date` | (baris 8) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 2 | def | `get_taxes` | (baris 18) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 3 | def | `get_tax` | (baris 41) Fungsi utama untuk membaca/mengambil data di layer backend; dipakai saat halaman atau proses butuh state terbaru dari database/API. |
| 4 | def | `create_tax` | (baris 47) Fungsi utama untuk membuat data/proses baru di layer backend; dipakai saat user memulai dokumen/alur baru. |
| 5 | def | `update_tax` | (baris 84) Fungsi utama untuk memperbarui state/data di layer backend; dipakai agar perubahan user tersimpan dan sinkron. |
| 6 | def | `delete_tax` | (baris 120) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |

---

## File: `backend/scripts/clean_subcategory.py` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `parse_args` | (baris 121) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 2 | def | `clean_subcategories` | (baris 133) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `main` | (baris 186) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---

## File: `backend/scripts/excel_to_app_db.py` [?]

| No | Tipe | Nama | Penjelasan Detil |
|---|---|---|---|
| 1 | def | `parse_args` | (baris 137) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 2 | def | `default_output_dir` | (baris 169) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 3 | def | `build_output_db_path` | (baris 176) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 4 | def | `to_iso_datetime` | (baris 192) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 5 | def | `to_iso_date` | (baris 211) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 6 | def | `to_num` | (baris 230) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 7 | def | `_eval_formula_expr` | (baris 259) Helper internal pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 8 | def | `to_num_cell` | (baris 307) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 9 | def | `to_text` | (baris 333) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 10 | def | `build_subcategory_alias_map` | (baris 339) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 11 | def | `normalize_subcategory` | (baris 347) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 12 | def | `ensure_schema` | (baris 367) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 13 | def | `tag_report_row` | (baris 573) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 14 | def | `ensure_reference_data` | (baris 596) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 15 | def | `purge_year_data` | (baris 709) Fungsi utama untuk menghapus atau membersihkan data di layer backend; dipakai saat koreksi data atau cleanup proses. |
| 16 | def | `store_excel_structure` | (baris 815) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 17 | def | `extract_year_from_header` | (baris 871) Fungsi utama untuk transformasi/normalisasi data pada layer backend; dipakai agar input berbagai format tetap aman diproses. |
| 18 | def | `tag_cell_mapping` | (baris 890) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 19 | def | `import_revenues` | (baris 911) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 20 | def | `import_taxes` | (baris 977) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 21 | def | `import_dividends` | (baris 1034) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 22 | def | `build_expense_blocks` | (baris 1046) Fungsi utama untuk menyusun output/kompatibilitas sistem di layer backend; dipakai agar format data dan hasil export konsisten. |
| 23 | def | `detect_category_id` | (baris 1075) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 24 | def | `detect_expense_value_column` | (baris 1120) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 25 | def | `import_expenses` | (baris 1128) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |
| 26 | def | `main` | (baris 1337) Fungsi utama pada layer backend; dipanggil sebagai bagian alur operasional modul agar proses bisnis berjalan end-to-end. |

---
