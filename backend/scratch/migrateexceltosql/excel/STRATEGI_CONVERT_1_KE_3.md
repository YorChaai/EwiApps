# 🎯 Strategi Konversi: Dari Data Perusahaan (1) ke Data Indah (3)

## 🧐 Perbandingan Tampilan Data
Berikut adalah perbandingan 5 baris pertama dari masing-masing file setelah dibersihkan dari baris kosong:

### 🟥 FILE 1: ASLI PERUSAHAAN (Kotor)
> **Masalah:** Banyak kolom 'Unnamed', format tanggal tidak konsisten.

|    |   Unnamed: 0 | Invoice Date        |   # | Detail/Description                                           |   Unnamed: 4 |   INVOICE VALUE | Currency   |   Currency | INVOICE Number   | Client        |
|    |              |                     |     |                                                              |              |                 |            |   Exchange |                  |               |
|---:|-------------:|:--------------------|----:|:-------------------------------------------------------------|-------------:|----------------:|:-----------|-----------:|:-----------------|:--------------|
|  0 |          nan | nan                 | nan | nan                                                          |          nan |    nan          | nan        |        nan | nan              | nan           |
|  1 |          nan | 2024-01-11 00:00:00 |   2 | ALFA Service PDP-075 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV017           | SI Jak        |
|  2 |          nan | 2024-01-10 00:00:00 |   3 | Revenue data procesing MTD_Tomori                            |          nan |      1.5e+08    | IDR        |          1 | INV015           | TGE           |
|  3 |          nan | 2024-01-11 00:00:00 |   4 | ALFA Service PDS-01ST Pertamina Zona#4                       |          nan |      3.5421e+08 | IDR        |          1 | INV019           | SI Jak        |
|  4 |          nan | 2024-01-11 00:00:00 |   5 | ALFA Service JRK-254 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV018           | SI Jak        |
|  5 |          nan | 2024-06-03 00:00:00 |   6 | ALFA Service TLJ-58 Pertamina Zona#4                         |          nan |      3.5421e+08 | IDR        |          1 | INV020           | SI Jak        |
|  6 |          nan | 2024-06-04 00:00:00 |   7 | ALFA Service JRK-193 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV021           | SI Jak        |
|  7 |          nan | 2024-09-04 00:00:00 |   8 | Revenue Repair Electric Assisted Stimulation Machine (no 23) |          nan |      8.9e+07    | IDR        |          1 | INV023           | LBU           |
|  8 |          nan | 2024-09-02 00:00:00 |   9 | ALFA Service JRK-163 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV022           | SI Jak        |
|  9 |          nan | 2024-10-11 00:00:00 |  10 | Revenue Project TIS (no 28 )                                 |          nan |      8.192e+08  | IDR        |          1 | INV028           | Barikin Sakti |

### 🟨 FILE 2: HASIL BERSIH LAMA (SQLite)
> **Masalah:** Sudah lumayan, tapi subkategori masih belum sempurna.

|    |   Unnamed: 0 | Invoice Date        |   # | Detail/Description                                           |   Unnamed: 4 |   INVOICE VALUE | Currency   |   Currency | INVOICE Number   | Client        |
|    |              |                     |     |                                                              |              |                 |            |   Exchange |                  |               |
|---:|-------------:|:--------------------|----:|:-------------------------------------------------------------|-------------:|----------------:|:-----------|-----------:|:-----------------|:--------------|
|  0 |          nan | nan                 | nan | nan                                                          |          nan |    nan          | nan        |        nan | nan              | nan           |
|  1 |          nan | 2024-01-11 00:00:00 |   2 | ALFA Service PDP-075 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV017           | SI Jak        |
|  2 |          nan | 2024-01-10 00:00:00 |   3 | Revenue data procesing MTD_Tomori                            |          nan |      1.5e+08    | IDR        |          1 | INV015           | TGE           |
|  3 |          nan | 2024-01-11 00:00:00 |   4 | ALFA Service PDS-01ST Pertamina Zona#4                       |          nan |      3.5421e+08 | IDR        |          1 | INV019           | SI Jak        |
|  4 |          nan | 2024-01-11 00:00:00 |   5 | ALFA Service JRK-254 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV018           | SI Jak        |
|  5 |          nan | 2024-06-03 00:00:00 |   6 | ALFA Service TLJ-58 Pertamina Zona#4                         |          nan |      3.5421e+08 | IDR        |          1 | INV020           | SI Jak        |
|  6 |          nan | 2024-06-04 00:00:00 |   7 | ALFA Service JRK-193 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV021           | SI Jak        |
|  7 |          nan | 2024-09-04 00:00:00 |   8 | Revenue Repair Electric Assisted Stimulation Machine (no 23) |          nan |      8.9e+07    | IDR        |          1 | INV023           | LBU           |
|  8 |          nan | 2024-09-02 00:00:00 |   9 | ALFA Service JRK-163 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV022           | SI Jak        |
|  9 |          nan | 2024-10-11 00:00:00 |  10 | Revenue Project TIS (no 28 )                                 |          nan |      8.192e+08  | IDR        |          1 | INV028           | Barikin Sakti |

### 🟩 FILE 3: HASIL APLIKASI (Ideal/Tujuan)
> **Kelebihan:** Sangat rapi, kolom jelas, data flat, siap masuk SQL.

|    |   Unnamed: 0 | Invoice Date        |   # | Detail/Description                                           |   Unnamed: 4 |   INVOICE VALUE | Currency   |   Currency | INVOICE Number   | Client        |
|    |              |                     |     |                                                              |              |                 |            |   Exchange |                  |               |
|---:|-------------:|:--------------------|----:|:-------------------------------------------------------------|-------------:|----------------:|:-----------|-----------:|:-----------------|:--------------|
|  0 |          nan | nan                 | nan | nan                                                          |          nan |    nan          | nan        |        nan | nan              | nan           |
|  1 |          nan | 2024-01-11 00:00:00 |   1 | ALFA Service PDP-075 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV017           | SI Jak        |
|  2 |          nan | 2024-01-10 00:00:00 |   2 | Revenue data procesing MTD_Tomori                            |          nan |      1.5e+08    | IDR        |          1 | INV015           | TGE           |
|  3 |          nan | 2024-01-11 00:00:00 |   3 | ALFA Service PDS-01ST Pertamina Zona#4                       |          nan |      3.5421e+08 | IDR        |          1 | INV019           | SI Jak        |
|  4 |          nan | 2024-01-11 00:00:00 |   4 | ALFA Service JRK-254 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV018           | SI Jak        |
|  5 |          nan | 2024-06-03 00:00:00 |   5 | ALFA Service TLJ-58 Pertamina Zona#4                         |          nan |      3.5421e+08 | IDR        |          1 | INV020           | SI Jak        |
|  6 |          nan | 2024-06-04 00:00:00 |   6 | ALFA Service JRK-193 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV021           | SI Jak        |
|  7 |          nan | 2024-09-04 00:00:00 |   7 | Revenue Repair Electric Assisted Stimulation Machine (no 23) |          nan |      8.9e+07    | IDR        |          1 | INV023           | LBU           |
|  8 |          nan | 2024-09-02 00:00:00 |   8 | ALFA Service JRK-163 Pertamina Zona#4                        |          nan |      3.5421e+08 | IDR        |          1 | INV022           | SI Jak        |
|  9 |          nan | 2024-10-11 00:00:00 |   9 | Revenue Project TIS (no 28 )                                 |          nan |      8.192e+08  | IDR        |          1 | INV028           | Barikin Sakti |

## 🛠️ Cara Mengubah 1 Langsung ke 3
Kita akan membuat script `migrate_1_to_sql.py` yang melakukan:
1. **Header Remapping**: Menentukan bahwa kolom 'Unnamed: 2' di File 1 sebenarnya adalah 'Tanggal'.
2. **Data Type Correction**: Memaksa kolom uang menjadi angka (integer), bukan teks.
3. **Category Auto-Matching**: Mencari kata kunci di deskripsi untuk menentukan ID Kategori di Postgres.
4. **Postgres Sync**: Data dikirim ke tabel `revenues`, `expenses`, dan `taxes` di Postgres.
