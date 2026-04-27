# Goal
Membangun sistem Notifikasi dan Aturan Tenggat Waktu (Deadline Rules Engine) yang dinamis. Admin dapat mengatur berbagai macam aturan waktu (jam, hari) untuk memicu notifikasi spesifik kepada pengguna (misal: "Kasbon belum di-settlement selama X hari", "Settlement belum di-approve selama X hari").

Sesuai saran Anda, fitur ini akan dibuatkan **halaman khusus** agar pengaturannya lebih luas dan mudah dikelola, karena nantinya bisa ada 10-20 jenis aturan yang berbeda.

> [!IMPORTANT]
> **User Review Required**
> Silakan tinjau rencana implementasi di bawah ini. Jika ada logika atau alur yang kurang sesuai dengan visi Anda, beri tahu saya agar bisa disesuaikan sebelum saya mulai membuat kodenya.

## Open Questions
1. **Metode Pengiriman:** Apakah notifikasi ini cukup muncul di dalam aplikasi saja (berupa ikon Lonceng di sudut kanan atas menu Dashboard), atau Anda butuh dikirim via WhatsApp/Email juga nantinya? *(Untuk tahap awal, saya sarankan in-app notification / Lonceng saja agar cepat diimplementasikan).*
2. **Pemicu Notifikasi (Trigger):** Apakah pengecekan deadline ini cukup dijalankan satu kali setiap malam (Daily Background Job), atau dievaluasi secara *real-time* setiap kali *user* membuka aplikasi?
3. **Kondisi Awal:** Selain (1) Kasbon belum di-settlement dan (2) Settlement belum di-approve, apakah ada kondisi spesifik lain yang ingin langsung dimasukkan di awal?

---

## Proposed Changes

### 1. Backend / Database (Python & PostgreSQL)
Kita perlu membuat tabel baru untuk menyimpan "Aturan" dan "Isi Notifikasi".

#### [NEW] `backend/models.py` (Tabel Baru)
- **`notification_rules`**: Menyimpan aturan dinamis.
  - Kolom: `id`, `rule_code` (misal: `ADVANCE_NOT_SETTLED`), `name`, `description`, `threshold_value` (angka: 20), `threshold_unit` (hari/jam), `is_active`.
- **`notifications`**: Menyimpan riwayat notifikasi yang dikirim ke user.
  - Kolom: `id`, `user_id`, `title`, `message`, `is_read`, `created_at`.

#### [NEW] `backend/routes/notifications.py`
- Endpoint untuk CRUD aturan notifikasi (`GET`, `POST`, `PUT`, `DELETE` ke `/api/notifications/rules`).
- Endpoint untuk mengambil notifikasi user yang sedang login (`GET /api/notifications/my`).
- Endpoint untuk menandai notifikasi sudah dibaca (`PUT /api/notifications/read/{id}`).

#### [MODIFY] `backend/main.py`
- Menambahkan sistem *scheduler* atau *background task* sederhana yang secara otomatis mengecek database secara berkala (misal: setiap jam 12 malam) untuk mencari Kasbon/Settlement yang melanggar aturan (`threshold_value`), lalu mengirimkan notifikasi ke tabel `notifications`.

---

### 2. Frontend (Flutter)
Membuat halaman khusus untuk mengatur aturan-aturan ini, dan menambahkan fitur Lonceng Notifikasi di aplikasi.

#### [NEW] `frontend/lib/screens/settings/notification_rules_screen.dart`
- **Halaman Baru:** Halaman khusus (tabel/list) untuk melihat, menambah, mengubah, dan mematikan aturan notifikasi.
- Dilengkapi dengan *Dialog* untuk mengatur `threshold_value` (angka) dan `threshold_unit` (jam/hari).

#### [MODIFY] `frontend/lib/screens/dashboard/dashboard_screen.dart`
- Menambahkan ikon Lonceng (🔔) dengan *badge* angka merah di AppBar atas.
- Jika ikon ditekan, akan muncul *Dropdown/Drawer* berisi daftar notifikasi (misal: *"Kasbon Anda (PDP-123) sudah lewat 3 hari, harap buat settlement!"*).

#### [NEW] `frontend/lib/providers/notification_provider.dart`
- Provider baru untuk menangani logika pemanggilan API notifikasi (mengambil aturan, mengambil jumlah notifikasi belum dibaca, dsb).

#### [MODIFY] `frontend/lib/widgets/app_sidebar.dart`
- Menambahkan menu baru di bawah **Settings / User Management** yang bernama **"Notification Rules"** untuk membuka halaman baru tersebut.

---

## Verification Plan

### Automated / Backend Tests
- Mengeksekusi *script* pengecekan deadline secara manual untuk memastikan Notifikasi masuk ke database jika ada Kasbon yang berumur lebih dari target hari.

### Manual Verification
- Login sebagai Superadmin -> Buka halaman Notification Rules -> Ubah batas hari "Kasbon belum settlement" menjadi 1 hari.
- Login sebagai user biasa -> Cek apakah lonceng notifikasi di pojok kanan atas memunculkan peringatan.
