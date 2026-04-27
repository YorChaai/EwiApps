# Rencana Implementasi: Sistem Notifikasi Deadline Dinamis

Sesuai diskusi terbaru, sistem ini akan menghitung tenggat waktu secara otomatis setelah aksi tertentu (Submit/Approve) dilakukan.

## Logika Bisnis (Aturan Deadline)

Terdapat 2 jenis aturan utama yang bisa diatur hari-nya secara dinamis (misal: 2, 10, 20 hari):

### 1. Deadline Kasbon -> Settlement (Untuk Staff)
*   **Pemicu:** Kasbon yang sudah **APPROVED** (disetujui).
*   **Titik Awal:** Tanggal persetujuan kasbon (`approved_at`).
*   **Aturan:** Jika sudah lewat X hari tapi user **belum submit** Settlement.
*   **Berhenti:** Jika status dokumen sudah bukan approved saja (sudah ada settlement terkait).
*   **Notifikasi:** Muncul di lonceng untuk Staff yang memegang kasbon.
*   **Pesan:** *"Kasbon [Judul] Anda sudah lewat [X] hari, mohon segera buat settlement!"*

### 2. Deadline Settlement -> Approval (Untuk Manajer)
*   **Pemicu:** Settlement yang sudah **SUBMITTED** (dikirim).
*   **Titik Awal:** Tanggal pengiriman dokumen.
*   **Aturan:** Jika sudah lewat X hari tapi manajer **belum approve/reject**.
*   **Berhenti:** Jika status sudah menjadi **APPROVED** atau **REJECTED**.
*   **Notifikasi:** Muncul di lonceng untuk Manajer/Admin.
*   **Pesan:** *"Settlement [Judul] dari [Nama] sudah menunggu selama [X] hari, mohon segera ditinjau!"*

---

## Fitur di Panel Manajer (Settings)

Akan ada halaman khusus untuk mengatur kapan notifikasi ini muncul:
*   **Input Dinamis:** Tersedia 3-5 kotak input hari (misal: kotak 1 = 2 hari, kotak 2 = 10 hari, kotak 3 = 20 hari).
*   **Fleksibilitas:** Manajer bisa mengubah angka-angka ini kapan saja.
*   **Waktu Muncul:** Notifikasi akan muncul setiap **Jam 12 Malam** (perubahan tanggal) untuk efisiensi sistem.

---

## Detail Teknis

1.  **Backend:** Membuat tabel `deadline_settings` untuk simpan angka hari.
2.  **Worker:** Script harian yang mengecek database: `Tanggal_Sekarang - Tanggal_Awal = X hari`.
3.  **Frontend:** 
    *   Halaman baru di Manager Panel untuk setting.
    *   Integrasi ke ikon Lonceng yang sudah ada di Dashboard (sesuai gambar yang Anda berikan).

---

## Verifikasi
*   Mengubah tanggal data di database secara manual untuk testing.
*   Memastikan notifikasi hilang otomatis saat dokumen disetujui (Approved).


dan ringkasannya

Rencana Implementasi: Sistem Notifikasi Deadline Dinamis
Sistem ini dirancang untuk memberikan peringatan otomatis jika Kasbon belum dibuatkan Settlement atau jika Settlement belum disetujui dalam jangka waktu tertentu.

Logika Bisnis (Aturan Deadline)
Terdapat dua jenis utama aturan deadline yang dapat diatur melalui Panel Manajer:

1. Deadline Pembuatan Settlement (Untuk Staff)
Pemicu: Kasbon yang statusnya sudah APPROVED namun belum ada Settlement yang dibuat/dikirim.
Titik Awal Waktu: approved_at dari Kasbon tersebut (saat dana cair/disetujui).
Ambang Batas (Threshold): Dinamis (bisa diatur hingga 5 angka, misal: hari ke-2, ke-10, ke-20).
Berhenti Jika: Dokumen Settlement sudah dikirim (SUBMITTED).
Penerima: Staff yang mengajukan kasbon.
Pesan: "Kasbon [Judul] Anda sudah disetujui selama [X] hari, harap segera selesaikan settlement."
2. Deadline Persetujuan Settlement (Untuk Manajer/Admin)
Pemicu: Settlement yang statusnya SUBMITTED namun belum di-APPROVED atau REJECTED.
Titik Awal Waktu: Tanggal pengiriman (updated_at saat status berubah menjadi submitted).
Ambang Batas (Threshold): Dinamis (misal: hari ke-2, ke-5, ke-10).
Berhenti Jika: Status berubah menjadi APPROVED atau REJECTED.
Penerima: Manajer yang bertanggung jawab atau Admin.
Pesan: "Settlement [Judul] dari [Nama Staff] sudah menunggu persetujuan selama [X] hari."
Proposed Changes
1. Database (Python - models.py)
[NEW] Tabel deadline_settings:
id: Primary Key.
rule_key: Identitas aturan (SETTLEMENT_SUBMISSION atau SETTLEMENT_APPROVAL).
days: Angka hari (threshold).
is_active: Untuk mengaktifkan/mematikan peringatan tertentu.
2. Backend Logic (Background Job)
[NEW] backend/utils/deadline_worker.py:
Script yang dijalankan setiap jam 00:00 (Tengah Malam).
Mengecek database menggunakan datetime.now().date() - trigger_date.
Jika selisih hari tepat sama dengan angka di deadline_settings, buat entri di tabel notifications.
Menggunakan Notification model yang sudah ada agar otomatis muncul di aplikasi.
3. Frontend UI (Flutter)
[NEW] frontend/lib/screens/settings/deadline_manager_screen.dart:
Halaman di dalam Manager Panel untuk mengatur hari-hari deadline.
Input field (3-5 kotak) untuk masing-masing jenis aturan.
[MODIFY] frontend/lib/widgets/notification_bell_icon.dart:
Menambahkan ikon khusus (misal: jam pasir atau tanda seru) untuk notifikasi jenis deadline.
Rencana Verifikasi
Manual Verification
Buka Manager Panel, atur deadline Kasbon ke "1 hari".
Buka Database, ubah approved_at sebuah Kasbon menjadi 1 hari yang lalu.
Jalankan fungsi pengecekan deadline.
Pastikan ikon Lonceng di Dashboard memunculkan notifikasi merah dan pesan yang sesuai.


Cara Kerjanya Nanti:
Setiap jam 12 malam, sistem akan otomatis mengecek data.
Jika ada yang lewat deadline (misal: sudah 10 hari belum submit settlement), sistem akan mengirimkan notifikasi.
Lonceng merah tersebut akan bertambah angkanya (misal dari 75 jadi 76).
Saat Bapak klik loncengnya, akan muncul pesan baru di sana, contohnya:
"Kasbon 'Perjalanan Dinas' Anda sudah lewat 10 hari, mohon segera buat settlement."
