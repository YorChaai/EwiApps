# Database Overview & Security Standard - MiniProjectKPI_EWI

Dokumen ini menjelaskan struktur database, langkah keamanan yang diterapkan, serta panduan pengisian data untuk menjaga kejelasan laporan.

## 1. Isi Database (`database.db`)

Database proyek ini menggunakan SQLite dan terdiri dari beberapa tabel utama:

| Tabel | Deskripsi |
|---|---|
| `users` | Menyimpan data pengguna, peran (manager/staff), dan login. |
| `categories` | Pohon kategori biaya (misal: Biaya Operasi > Transportation). |
| `advances` | Header pengajuan Kasbon (Kasbon Single atau Batch). |
| `advance_items` | Detail item di dalam Kasbon (estimasi biaya, kategori). |
| `settlements` | Header Realisasi (Settlement) yang menautkan Kasbon ke biaya riil. |
| `expenses` | Item biaya riil yang sudah terjadi (Settlement Item). |
| `revenues` | Data Invoice/Pendapatan dari klien. |
| `taxes` | Data pembayaran pajak (PPh 21, 23, 26, PPN). |
| `dividends` | Data pembagian laba/dividen ke pemegang saham. |
| `notifications` | Log aktivitas untuk sistem approval (notifikasi). |
| `report_entry_tags` | Pemetaan data impor dari Excel ke database aplikasi. |

## 2. Kesamaan Struktur (Advance vs Settlement)

Kedua sistem ini sebenarnya memiliki alur yang **identik** (sama), hanya berbeda waktu penggunaannya (sebelum vs sesudah pengeluaran).

| Fitur | Advance (Kasbon) | Settlement (Realisasi) |
|---|---|---|
| **Header (Induk)** | `advances` | `settlements` |
| **Item (Anak)** | `advance_items` | `expenses` |
| **User ID** | Menyimpan siapa yang meminta dana. | Menyimpan siapa yang melaporkan dana. |
| **Status Flow** | Ada status `draft`, `submitted`, `approved`, `rejected`. | Ada status `draft`, `submitted`, `approved`, `rejected`. |
| **Tipe** | Pilihan `single` atau `batch`. | Pilihan `single` atau `batch`. |
| **Kaitan** | - | Punya `advance_id` untuk terhubung ke Kasbon asal. |

## 3. Keamanan & Enkripsi data

Berdasarkan analisis sistem saat ini:

*   **Password**: **SUDAH DIHASH** (Aman). Sistem menggunakan algoritma `PBKDF2` atau `Scrypt` melalui library `werkzeug.security`. Password tidak disimpan dalam bentuk teks biasa, sehingga admin pun tidak bisa melihat password asli Anda.
*   **Expense & Kasbon**: **BELUM DIENKRIPSI** (Teks Biasa). Data nominal dan deskripsi disimpan apa adanya di dalam file database.
    *   *Rekomendasi*: Untuk proyek skala internal/lokal, ini umumnya cukup selama akses ke PC database dibatasi. Jika membutuhkan kerahasiaan tinggi, enkripsi kolom (AES-256) bisa ditambahkan di level aplikasi.

## 3. Detail Kolom per Tabel

Berikut adalah rincian kolom penting untuk setiap tabel utama:

### 1. `users` (Data Pengguna)
- `id`: ID unik user.
- `username`: Nama login.
- `password_hash`: Password terenkripsi.
- `full_name`: Nama lengkap.
- `role`: Peran (`manager` atau `staff`).
- `created_at`: Waktu pendaftaran.

### 2. `advances` (Pengajuan Kasbon)
- `id`: ID unik pengajuan.
- `title`: Judul pengajuan (misal: "Project A").
- `description`: Penjelasan detail kasbon.
- `advance_type`: Tipe (`single` atau `batch`).
- `user_id`: ID staff yang mengajukan.
- `status`: Status approval (`draft`, `submitted`, `approved`, `rejected`, dll).
- `notes`: Catatan dari Manager.
- `approved_revision_no`: Nomor revisi terakhir yang disetujui.
- `active_revision_no`: Nomor revisi yang sedang diedit.

### 3. `advance_items` (Item Kasbon)
- `id`: ID unik item.
- `advance_id`: ID pengajuan induk (menghubungkan ke tabel `advances`).
- `category_id`: ID kategori pengeluaran.
- `description`: Deskripsi barang/jasa yang diminta.
- `estimated_amount`: Nominal perkiraan.
- `revision_no`: Nomor revisi item ini.
- `date`, `source`, `currency`, `currency_exchange`: Info tanggal dan mata uang.
- `status`: Status item (`pending`, `approved`, `rejected`).
- `evidence_path`: Lokasi file bukti.

### 4. `settlements` (Realisasi/Laporan Selesai)
- `id`: ID unik realisasi.
- `advance_id`: ID Kasbon asal (menghubungkan ke `advances`).
- `user_id`: ID pembuat laporan.
- `title`, `description`: Judul dan penjelasan laporan.
- `status`: Status (`draft`, `submitted`, `approved`).

### 5. `expenses` (Item Pengeluaran Riil)
- `id`: ID unik pengeluaran.
- `settlement_id`: ID laporan induk (menghubungkan ke `settlements`).
- `category_id`: ID kategori.
- `advance_item_id`: Link ke item kasbon asal (jika ada).
- `description`: Deskripsi biaya riil.
- `amount`: Nominal riil.
- `date`, `source`, `currency`, `currency_exchange`: Info transaksi.
- `evidence_path`, `evidence_filename`: Data lampiran nota/bukti.

### 6. `revenues` (Pendapatan/Invoice)
- `id`, `invoice_date`, `description`, `invoice_number`, `client`.
- `invoice_value`, `amount_received`: Nilai tagihan vs nilai diterima.
- `ppn`, `pph_23`, `transfer_fee`: Pajak dan biaya admin.

### 7. `taxes` (Data Pajak)
- `id`, `date`, `description`.
- `transaction_value`: Nilai transaksi dasar.
- `ppn`, `pph_21`, `pph_23`, `pph_26`: Nilai nominal masing-masing jenis pajak.

### 8. `dividends` (Pembagian Laba)
- `id`, `date`, `name`: Tanggal dan Nama penerima dividen.
- `amount`: Jumlah dividen yang dibagikan.
- `recipient_count`: Jumlah penerima.
- `tax_percentage`: Persentase pajak dividen.

### 9. `dividend_settings` (Setting Keuangan Tahunan)
- `year`: Tahun laporan.
- `profit_retained`: Laba ditahan.
- `opening_cash_balance`, `accounts_receivable`, dll: Saldo awal untuk neraca tahunan.

### 10. `notifications` (Notifikasi Sistem)
- `id`, `user_id`, `actor_id`: Target user dan pelaku aktivitas.
- `action_type`: Jenis aksi (`submit`, `approve`, `reject`).
- `target_type`, `target_id`: Objek yang dikomentari.
- `message`: Isi pesan notifikasi.
- `read_status`: Sudah dibaca atau belum.

### 11. `report_entry_tags` (Tag Laporan Excel)
- `id`: ID unik tag.
- `table_name`: Nama tabel (misal: `revenues`).
- `row_id`: ID baris dari tabel tersebut.
- `report_year`: Tahun laporan.
- `source_excel`: Nama file excel asal.
- `imported_at`: Waktu impor data.

## 4. Standar Penulisan Deskripsi

Agar laporan (Excel/PDF) lebih jelas dan mudah dianalisis, disarankan mengikuti format standar berikut:

**Format: `[Kategori] Vendor/Toko - Barang/Jasa - Keperluan/Project`**

*Contoh Buruk:* "Makan siang"
*Contoh Baik:* `[Meal] RM Ayam Bakar - Makan Siang Crew - Project Wireline Prabumulih`

*Manfaat:*
1. Memudahkan pencarian (search) di database.
2. Laporan akhir tidak perlu diedit manual lagi.
3. Mempercepat proses approval oleh Manager.

---
> [!TIP]
> **Tips Keamanan**: Lakukan backup file `database.db` secara berkala ke folder yang aman (cloud/drive eksternal) untuk mencegah kehilangan data akibat kerusakan hardware.
