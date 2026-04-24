# Roadmap Belajar PostgreSQL: Dari Pemula ke Profesional

Panduan ini dirancang untuk Anda yang sudah paham Python dan MySQL, namun ingin menguasai PostgreSQL untuk standar industri besar (Enterprise).

---

## 🟢 Fase 1: Fondasi & Perbedaan (Minggu 1-2)
*Tujuan: Memahami mengapa Postgres berbeda dari MySQL dan mulai menggunakannya secara lokal.*

1. **Fundamental PostgreSQL:**
   - Arsitektur Client-Server (apa itu `postgres` user, apa itu `pgAdmin`).
   - Tipe data unik di Postgres (Array, JSONB, Range, UUID).
   - Skema (Schema) vs Database: Cara mengatur tabel agar lebih rapi.
2. **Postgres Tools:**
   - Menguasai **pgAdmin 4** (GUI) dan **psql** (Terminal).
   - Cara backup dan restore database secara manual.

## 🟡 Fase 2: Query Tingkat Lanjut & Integritas Data (Minggu 3-4)
*Tujuan: Menulis query yang lebih efisien dan memastikan data tidak rusak.*

1. **Relasi & Constraints:**
   - Deep dive ke Foreign Keys, Unique constraints, dan Check constraints.
   - Mengatur "Cascade Delete/Update" (apa yang terjadi jika data induk dihapus).
2. **Intermediate SQL:**
   - **CTE (Common Table Expressions):** Menggunakan `WITH` (Sangat penting di Postgres).
   - **Window Functions:** `ROW_NUMBER()`, `RANK()`, `LEAD()`, `LAG()` (Sangat berguna untuk analisis data).
   - Subqueries vs Joins: Kapan harus pakai yang mana.

## 🟠 Fase 3: Otomatisasi & Logika Database (Minggu 5-6)
*Tujuan: Membuat database bekerja sendiri tanpa bantuan Python.*

1. **Views & Materialized Views:** Menyimpan query kompleks agar bisa dipanggil seperti tabel.
2. **Stored Procedures & Functions:** Menulis logika (seperti fungsi Python) langsung di dalam database menggunakan bahasa PL/pgSQL.
3. **Triggers:** Menjalankan aksi otomatis saat ada data yang masuk/berubah (misal: otomatis kirim notifikasi saat ada transaksi baru).

## 🔴 Fase 4: Optimasi & Skalabilitas (Minggu 7-8)
*Tujuan: Menangani jutaan data tanpa lemot.*

1. **Indexing:** Memahami B-Tree, GIN (untuk JSON), dan GiST.
2. **Performance Tuning:** Menggunakan `EXPLAIN ANALYZE` untuk mencari tahu query mana yang lambat.
3. **Vacuum & Maintenance:** Cara Postgres mengelola memori dan menghapus data sampah (Dead Tuples).

## 🚀 Fase 5: "The Gen-AI / Data Science Level" (Post-Week 8)
*Tujuan: Mengintegrasikan Postgres dengan Machine Learning & Big Data.*

1. **JSONB (NoSQL in SQL):** Cara menyimpan data tidak terstruktur tapi tetap bisa diquery dengan sangat cepat.
2. **PostGIS:** Modul untuk data lokasi/geospasial (Peta/GPS).
3. **pgvector:** (Ini adalah "LLM Level" nya Postgres). Menggunakan Postgres sebagai **Vector Database** untuk menyimpan data dari AI/LLM.
4. **TimescaleDB:** Ekstensi untuk data deret waktu (*time-series*).

---

## 🛠️ Alat & Sumber Belajar Rekomendasi
1. **Interactive Learning:** [SQLBolt](https://sqlbolt.com/) (Basic) atau [Postgresqltutorial.com](https://www.postgresqltutorial.com/) (Lengkap).
2. **YouTube:** Cari channel *"Hussein Nasser"* (untuk backend & database) atau *"The Art of PostgreSQL"*.
3. **Buku:** *"The Art of PostgreSQL"* oleh Dimitri Fontaine.
4. **Praktek:** Gunakan aplikasi **MiniProjectKPI_EWI** Anda sebagai laboratorium. Cobalah buat laporan kompleks langsung di SQL, bukan di Python.

---
**Tips untuk Anda:**
Sebagai Data Scientist, fokuslah lebih dalam pada **Window Functions** dan **JSONB**. Itu adalah dua senjata terkuat PostgreSQL yang akan sangat membantu Anda saat mengolah data mentah menjadi laporan yang siap dipakai.
