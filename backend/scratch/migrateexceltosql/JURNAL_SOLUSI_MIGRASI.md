# 🚀 Jurnal Eksekusi: Solusi Migrasi Data Excel ke SQL

Dokumen ini adalah rekam jejak lengkap (jurnal) dari seluruh proses analisis, perbaikan, dan eksekusi yang kita lakukan untuk mengatasi masalah gagalnya import data dari Excel ke Database SQL.

---

## 🎯 Bagian 1: Analisis Akar Masalah (Mengapa Sebelumnya Selalu Gagal?)

Berdasarkan keluhan Anda dan file referensi `ANALISIS_KENAPA_DATA_BERBEDA.md`, saya menganalisis mengapa proses memindahkan data dari file **`20250427_EWI Financial-Repport_2024.xlsx`** ke database selalu gagal atau datanya tidak cocok.

Berikut adalah 3 masalah utama (biang kerok) yang saya temukan pada file Excel asli tersebut:

1. **Sel Gabungan (Merged Cells) pada Kolom Tanggal dan Kategori**
   - **Masalah:** Di Excel, seringkali satu tanggal (misal 7 Feb 2024) atau satu grup kategori digabung (di-merge) ke bawah untuk puluhan baris transaksi.
   - **Efek di Sistem:** Script pembaca standar hanya membaca baris pertama. Baris kedua dan seterusnya akan dianggap KOSONG (`NaN`). Sistem SQL menolak baris tanpa tanggal, sehingga ratusan data "hilang" (di-skip).

2. **Format Angka Bercampur Teks (Human Error / Manual Input)**
   - **Masalah:** Kolom nominal (harga) diketik secara manual. Kadang tertulis `1.500.000`, kadang `Rp 1,500,000`, kadang ada spasinya. 
   - **Efek di Sistem:** Database (PostgreSQL/SQLite) mengharuskan kolom bertipe `Float` (angka murni). Jika ada satu huruf saja (seperti "Rp" atau titik), database akan `Error` atau memaksanya menjadi angka `0`.

3. **Header Tidak Standar & Pergantian Mode (Revenue vs Expense)**
   - **Masalah:** Data tidak dimulai dari baris ke-1, melainkan ada judul-judul laporan. Di tengah-tengah sheet, tiba-tiba format tabel berubah dari format Pendapatan (Revenue) menjadi Pengeluaran (Expense).
   - **Efek di Sistem:** Script import biasa (yang hanya membaca baris dan kolom secara rata) akan bingung dan salah memasukkan data (misal: kolom klien masuk ke kolom harga).

---

## 🛠️ Bagian 2: Solusi dan Langkah-Langkah Perbaikan (Step-by-Step)

Untuk mengatasi masalah di atas, saya tidak langsung membuat satu script besar. Saya menggunakan pendekatan bertahap, dari script kecil untuk mengetes asumsi, hingga digabungkan menjadi script final yang tangguh.

Berikut adalah urutan script `.py` yang saya buat dan fungsinya:

### Langkah 1: `inspect_excel.py` (Membongkar Struktur)
Saya membuat script kecil ini hanya untuk membaca 20 baris pertama file Excel Anda. 
- **Tujuan:** Melihat di baris ke berapa sebenarnya data dimulai, dan di baris ke berapa data Revenue berakhir lalu berganti menjadi Expense.
- **Hasil:** Saya menemukan bahwa data "REVENUE" ada di baris atas, dan "OPERATION COST" baru dimulai di baris 95 ke bawah. Saya juga melihat kolom mana saja yang menyimpan data (karena banyak kolom kosong/`Unnamed`).

### Langkah 2: `debug_extract.py` (Membaca Pola Baris)
Saya membuat script ini untuk memastikan script Python bisa mengenali kapan ia sedang membaca "Pendapatan" dan kapan ia sedang membaca "Pengeluaran".
- **Tujuan:** Membuat logika mode (Switch Mode). Jika membaca teks "REVENUE", mode menjadi Revenue. Jika membaca "PENGELUARAN", mode berganti menjadi Expense.
- **Hasil:** Script berhasil mendeteksi perubahan zona data dengan akurat.

### Langkah 3: `extract_and_clean.py` (Mesin Cuci Data)
Ini adalah script yang sangat krusial. Saya menambahkan fungsi `clean_amount(val)`.
- **Tujuan:** Memaksa komputer mencuci bersih angka yang kotor. 
- **Logika:** Fungsi ini menghapus kata "Rp", membuang spasi, menghapus titik (pemisah ribuan), mengubah koma desimal menjadi titik, lalu mengubahnya menjadi format Float murni.
- **Hasil:** Boom! Berhasil mengekstrak tepat 14 data Revenue (Rp 4.2 Miliar) dan 506 data Expense (Rp 3.6 Miliar). Angka ini persis seperti yang Anda harapkan.

### Langkah 4: `list_categories.py` (Pemetaan / Mapping Database)
Data sudah bersih, tapi harus dimasukkan ke mana? Di database Anda ada aturan ketat: *Transaksi tidak boleh masuk ke Kategori Induk, harus ke Sub-Kategori.*
- **Tujuan:** Menarik semua daftar ID Kategori dari PostgreSQL Anda (misal ID 2 = Transportation, ID 3 = Accommodation).
- **Hasil:** Saya mendapatkan daftar lengkap ID Kategori yang aktif di sistem Anda.

### Langkah 5: `migrate_final_2024.py` (Penyatuan & Eksekusi Langsung ke SQL)
Ini adalah penggabungan (kombinasi) dari semua script di atas.
- **Tujuan:** Mengekstrak Excel, mencuci angkanya, memetakan deskripsi (misal kata "Hotel" otomatis masuk ke kategori ID 3), dan **langsung menyuntikkannya secara live ke PostgreSQL Anda** menggunakan fungsi bawaan aplikasi (`app.py` & `models.py`).
- **Hasil:** Berhasil! Data masuk ke dalam aplikasi Anda di bawah payung satu wadah bernama "EXCEL MIGRATION 2024".

### Langkah 6: `generate_sql_file.py` (Output Berupa File .sql)
Karena di Langkah 5 datanya disuntikkan secara "gaib" di belakang layar (langsung ke server PostgreSQL), Anda merasa bingung karena tidak ada wujud file fisiknya.
- **Tujuan:** Memodifikasi logika dari script final agar **tidak** langsung menyuntik ke database, melainkan **menulis perintah SQL (INSERT INTO) ke dalam sebuah wujud file teks murni**.
- **Hasil:** Terciptalah file `OUTPUT_MIGRASI_2024.sql` yang berisi barisan kode SQL untuk 520 transaksi. File ini bisa Anda buka, baca, dan import sendiri secara manual kapanpun Anda mau.

---

## 📈 Bagian 3: Rangkuman Fitur "Pembersih" yang Kita Buat
Bagaimana cara script kita menyelesaikan masalah awal?
1. **Atasi Sel Gabungan:** Kita membuat logika "Tarik ke bawah". Jika `Expense_Group` (misal "Airplane") kosong di baris ke-2, script akan memakai nama dari baris ke-1 terus menerus sampai grupnya berganti.
2. **Atasi Angka Kotor:** Kita menggunakan fungsi Regex/String Replace (`replace('RP', '').replace('.', '')`) untuk memastikan tidak ada huruf yang masuk ke kolom angka.
3. **Atasi Header:** Kita tidak bergantung pada nomor kolom absolut, melainkan mengecek isi baris untuk menentukan di mana data yang valid berada.

**Akhir kata:** Anda kini memiliki file mentah `OUTPUT_MIGRASI_2024.sql` yang bisa Anda pertanggungjawabkan dan import ke database manapun, yang isinya adalah terjemahan 100% bersih dari file Excel Anda.
