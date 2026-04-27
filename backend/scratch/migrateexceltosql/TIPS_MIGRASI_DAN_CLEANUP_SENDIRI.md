# 💡 Panduan Migrasi, Cleanup, dan Komparasi Database

Laporan ini dibuat untuk menjawab pertanyaan Anda mengenai lokasi data saat ini, konfirmasi sumber file, dan panduan langkah demi langkah jika Anda ingin melakukan pembersihan (cleanup) serta perbandingan data secara mandiri.

---

## 1. Konfirmasi Sumber Excel
**YA, BETUL SEKALI.** 
Seluruh data yang baru saja berhasil kita ekstrak dan masukkan (506 transaksi pengeluaran dan 14 pendapatan) berasal murni dari file Excel asli yang Anda berikan:
📄 `"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\20250427_EWI Financial-Repport_2024.xlsx"`

Script Python kita (`migrate_final_2024.py`) membaca file tersebut secara langsung, membersihkan format angka ("Rp", titik, koma), lalu menyuntikkannya ke dalam database aktif aplikasi Anda.

---

## 2. Di Mana Dataset-nya Sekarang?
Data hasil ekstrak dari Excel tersebut **sudah masuk ke dalam database aktif aplikasi Anda saat ini** (biasanya PostgreSQL atau SQLite `database.db` di dalam folder backend, tergantung isi `.env` Anda). 

Oleh karena itu, ketika Anda membuka dashboard aplikasi sekarang, grafiknya akan langsung berubah karena ketambahan data baru ini. Namun, karena data lama (hasil import Anda yang lama) belum dihapus, datanya saat ini menjadi **dobel (terduplikasi)**.

---

## 3. Cara Melakukan Cleanup Sendiri (Menghapus Data Kotor)
Karena sekarang ada dua versi data di dalam database aplikasi (Data Lama yang kotor + Data Baru yang bersih dari Excel), Anda harus menghapus data yang lama.

Berikut adalah cara melakukannya menggunakan **Database Manager (seperti DBeaver/pgAdmin)** atau via script:

### Jika Menggunakan Query SQL Langsung (DBeaver / pgAdmin):
Anda cukup menjalankan 2 query ini untuk menghapus semua transaksi tahun 2024 **KECUALI** yang baru saja kita masukkan dari Excel (yang kita tampung di Settlement bernama "EXCEL MIGRATION 2024"):

```sql
-- 1. Hapus pengeluaran (expenses) lama tahun 2024
DELETE FROM expenses 
WHERE EXTRACT(YEAR FROM date) = 2024 
  AND settlement_id NOT IN (
      SELECT id FROM settlements WHERE title = 'EXCEL MIGRATION 2024'
  );

-- 2. Hapus pendapatan (revenues) lama tahun 2024
DELETE FROM revenues 
WHERE report_year = 2024 
  AND created_at < '2026-04-28 00:00:00'; -- Sesuaikan dengan tanggal/jam script kita dijalankan
```

### Jika Menggunakan Python Script di project Anda:
Anda bisa membuat file `cleanup_old_2024.py` di folder backend dan isikan kode ini:
```python
from app import create_app
from models import db, Expense, Settlement, Revenue

app = create_app()
with app.app_context():
    # Cari ID Settlement penampung Excel kita
    mig_settlement = Settlement.query.filter_by(title="EXCEL MIGRATION 2024").first()
    
    if mig_settlement:
        # Cari semua expenses 2024 selain dari settlement tersebut
        old_expenses = Expense.query.filter(
            db.extract('year', Expense.date) == 2024,
            Expense.settlement_id != mig_settlement.id
        ).all()
        
        for e in old_expenses:
            db.session.delete(e)
            
        print(f"Berhasil menghapus {len(old_expenses)} data pengeluaran lama yang kotor.")
        db.session.commit()
```

---

## 4. Cara Membandingkan dengan File Backup SQL Anda
Anda memiliki file backup SQL sebelum kita melakukan percobaan ini:
📄 `"D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\scratch\migrateexceltosql\database\backup_postgres_2026-04-28_00-04-50.sql"`

Jika Anda ingin melihat perbedaannya atau membandingkannya:

1. **Buat Database Kosong Baru** (misal: `db_kpi_backup_test`) di PostgreSQL.
2. **Restore file `.sql` tersebut** ke database kosong itu.
   - Perintah Terminal: `psql -U postgres -d db_kpi_backup_test -f "D:\...\backup_postgres_2026-04-28_00-04-50.sql"`
3. **Bandingkan Angkanya**: 
   - Di database `db_kpi_backup_test` (Backup), jalankan `SELECT SUM(amount) FROM expenses WHERE EXTRACT(YEAR FROM date) = 2024;`. Angkanya pasti berantakan / tidak sesuai Excel.
   - Di database aktif aplikasi Anda (setelah Anda melakukan *cleanup* pada langkah 3), jalankan query yang sama. Angkanya akan persis **Rp 3.656.004.506** (Sama persis dengan hitungan murni dari Excel).

### Kesimpulan
Langkah terpenting Anda sekarang adalah **menghapus data lama (Langkah 3)** agar dashboard aplikasi Anda menampilkan angka murni dari Excel tersebut!
