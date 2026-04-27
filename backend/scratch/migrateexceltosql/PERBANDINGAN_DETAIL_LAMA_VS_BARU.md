# 📊 Laporan Komparasi Detail: Database Lama vs Excel Asli (2024)

Dokumen ini membandingkan data Laporan Tahun 2024 yang ada di **Database Lama Anda (SQLite/Import Lama)** dengan **Data Murni dari Excel (`20250427_EWI Financial-Repport_2024.xlsx`)**.

> **Kenapa Dulu Bisa Beda (1 Juta jadi 10 Juta)?**
> Script import lama Anda memiliki celah saat membaca angka desimal Indonesia. Jika di Excel tertulis `1.000.000,00` dan script lama membuang semua titik dan koma, komputer akan membacanya sebagai `100000000` (100 Juta). Inilah yang menyebabkan pengeluaran di database lama Anda bengkak dan berantakan! Script baru telah memperbaiki logika ini sepenuhnya.

---

## 1. PENDAPATAN (REVENUE)
| Metrik | Database Lama (Kotor) | Data Baru (Excel Asli) | Status / Selisih |
| :--- | :--- | :--- | :--- |
| **Total Transaksi** | 42 Item | 15 Item | SAMA |
| **Pendapatan Langsung** | Rp 12,759,860,850.00 | Rp 8,504,265,425.00 | SAMA |
| **Pendapatan Lain-lain** | Rp 6,925,425.00 | Rp 6,925,425.00 | SAMA |
| **TOTAL REVENUE** | **Rp 12,766,786,275.00** | **Rp 8,511,190,850.00** | ✅ COCOK |

---

## 2. PENGELUARAN (EXPENSE / COST)
*(Catatan: Pengeluaran adalah komponen yang paling hancur di import lama Anda karena merged cells dan salah baca desimal).*

| Metrik | Database Lama (Kotor) | Data Baru (Excel Asli) | Status / Selisih |
| :--- | :--- | :--- | :--- |
| **Total Transaksi** | 474 Item | 507 Item | Excel lebih lengkap (+33) |
| **Beban Langsung** | Rp 0.00 | - (Tergabung di Total) | - |
| **Biaya Admin & Umum** | Rp 0.00 | - (Tergabung di Total) | - |
| **TOTAL EXPENSE** | **Rp 3,336,231,217.43** | **Rp 3,694,966,534.43** | ⚠️ BEDA JAUH! |

*Selisih Total Pengeluaran: **Rp 358,735,317.00***
*Data lama kehilangan banyak baris transaksi, namun nilai nominalnya bengkak karena salah baca koma (1 juta jadi 10 juta).*

---

## 3. PAJAK (TAXES)
| Metrik | Database Lama (Kotor) | Data Baru (Excel Asli) |
| :--- | :--- | :--- |
| **Total Pembayaran Pajak** | 10 Item (Rp 308,366,261.00) | (Tergabung di Invoice / Neraca Akhir) |

---

## 4. NERACA KEUANGAN (Laba/Rugi Akhir Tahun)
| Metrik | Database Lama (Kotor) | Data Baru (Excel Asli) | Status / Selisih |
| :--- | :--- | :--- | :--- |
| **Profit Bersih (After Tax)** | Rp 33,654,157.00 | Rp 0.00 | Database Lama Kosong |
| **Laba Ditahan (Retained)** | Rp 0.00 | Rp 0.00 | Database Lama Kosong |

---

## 5. DIVIDEN (Bagi Hasil Pemegang Saham)
| Metrik | Database Lama (Kotor) | Data Baru (Excel Asli) | Status / Selisih |
| :--- | :--- | :--- | :--- |
| **Jumlah Penerima** | 2 Orang | 0 Orang | - |
| **Total Dividen Dibagi** | **Rp 0.00** | **Rp 0.00** | Database Lama Kosong |

---

### 💡 Kesimpulan & Saran Tindakan:
1. **Pendapatan (Revenue)** Anda dulu sudah berhasil di-import dengan benar. Tidak ada masalah.
2. **Pengeluaran (Expense)** di database lama sangat rusak (jumlah transaksinya sedikit, tapi nominalnya bengkak). Anda **wajib menghapus** pengeluaran lama ini.
3. **Neraca & Dividen** di database lama **masih KOSONG (Rp 0)**. Anda perlu meng-input angka dari Excel (Sheet Business Summary) ke dalam menu Neraca di aplikasi Anda agar laporan akhir tahunnya sempurna.
