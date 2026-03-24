# CHECKLIST UJI MANUAL REVISI 2 (Versi Sinkron Sistem Terbaru)

Dokumen ini dipakai untuk regression test setelah perubahan besar backend/frontend:
- notifikasi role-based + deep-link.
- workflow kasbon/settlement draft vs submitted.
- laporan annual/dividen/neraca.
- perbaikan tema light mode dan keterbacaan font.

Gunakan status hasil:
- `OK`
- `BUG`
- `PERLU IMPROVE`

Gunakan prioritas:
- `TINGGI`: merusak data/alur utama.
- `SEDANG`: alur jalan tapi membingungkan/berisiko.
- `RENDAH`: kosmetik/non-blocking.

---

## 1. Login, Sesi, Role, dan Akses Data

### 1.1 Login
- [ ] Login manager berhasil.
- [ ] Login staff berhasil.
- [ ] Login mitra (jika role aktif) berhasil.
- [ ] Login dengan password salah ditolak dengan pesan jelas.
- [ ] Logout membersihkan sesi.
- [ ] Tutup-buka aplikasi, sesi valid tetap masuk otomatis.

### 1.2 Otorisasi role
- [ ] Manager melihat menu admin (Laporan, Kategori, Pengaturan).
- [ ] Staff tidak melihat menu admin.
- [ ] Staff tidak bisa buka data milik staff lain via UI.
- [ ] Coba akses direct URL/path detail data user lain, backend tetap menolak.

### 1.3 Integritas identitas
- [ ] Nama dan role di sidebar sesuai user login.
- [ ] Badge notifikasi dan pending mengikuti role aktif.

---

## 2. Notifikasi (Wajib diuji detail)

### 2.1 Distribusi notifikasi per role
- [ ] Manager menerima notifikasi aktivitas penting dari semua staff/mitra yang relevan.
- [ ] Staff hanya menerima notifikasi aktivitas miliknya.
- [ ] Mitra hanya menerima notifikasi aktivitas miliknya.

### 2.2 Tampilan panel notifikasi
- [ ] Klik icon bell membuka panel.
- [ ] Ada tombol centang (`mark all read`).
- [ ] Ada tombol silang `X` di kanan atas untuk menutup panel.
- [ ] Teks notifikasi terbaca jelas di dark dan light theme.
- [ ] Badge unread count turun setelah mark read.

### 2.3 Aksi notifikasi
- [ ] Tombol `Buka Settlement` mengarahkan ke detail settlement yang benar.
- [ ] Tombol `Buka Kasbon` mengarahkan ke detail kasbon yang benar.
- [ ] Klik item notifikasi juga menjalankan deep-link.
- [ ] Hapus notifikasi menghilangkan item dari list.

---

## 3. Kasbon (Advance) - Flow Inti

### 3.1 Draft state
- [ ] Saat status `draft`, header kasbon bisa diedit.
- [ ] Saat status `draft`, item bisa tambah/edit/hapus.
- [ ] Validasi form item berjalan (kategori, deskripsi, nominal).

### 3.2 Submit/Approve/Reject
- [ ] Submit draft mengubah status ke `submitted`.
- [ ] Setelah submit, mode edit terkunci untuk staff.
- [ ] Manager bisa approve.
- [ ] Manager bisa reject dengan catatan.
- [ ] Notifikasi terkirim ke pihak yang tepat.

### 3.3 Revisi
- [ ] Start revisi membuat status revisi yang benar.
- [ ] Item revisi bisa dikelola pada revision draft.
- [ ] Submit revisi -> manager approve/reject.
- [ ] Hitungan total approved/base/revision konsisten.

### 3.4 Sinkron list/filter
- [ ] Ubah filter status/tahun/range tidak membuat data hilang semu.
- [ ] Pindah menu lalu balik lagi, data list tetap sinkron.

---

## 4. Settlement - Flow Inti

### 4.1 Draft state
- [ ] Saat `draft`, settlement bisa edit header.
- [ ] Saat `draft`, item expense bisa tambah/edit/hapus.
- [ ] Checklist reject bisa diisi/diupdate.

### 4.2 Submit/Approve/Reject/Complete
- [ ] Submit mengubah status settlement ke `submitted`.
- [ ] Manager approve settlement berhasil.
- [ ] Manager reject all dengan alasan berhasil.
- [ ] Complete settlement hanya aktif saat syarat terpenuhi.
- [ ] Setelah complete, data tidak bisa diubah sembarangan.

### 4.3 Rule visibility sesuai status
- [ ] Untuk status non-draft, aksi edit tidak muncul bagi staff.
- [ ] Pada status submitted, user hanya bisa lihat detail.

---

## 5. Kategori

### 5.1 CRUD kategori
- [ ] Manager bisa tambah kategori utama.
- [ ] Manager bisa tambah subkategori.
- [ ] Edit/hapus kategori berjalan sesuai aturan.

### 5.2 Approval kategori pending
- [ ] Kategori baru masuk antrian pending.
- [ ] Manager approve/reject kategori pending berhasil.
- [ ] Jika parent belum approved, subkategori pending ditangani dengan pesan yang jelas.

---

## 6. Laporan Summary

### 6.1 Data dan filter
- [ ] Tahun laporan bisa diganti.
- [ ] Date range berfungsi.
- [ ] Tabel summary menampilkan angka sesuai data approved.

### 6.2 Export
- [ ] Export PDF summary berhasil.
- [ ] Export Excel summary berhasil.
- [ ] File terbuka dan isi konsisten.

---

## 7. Laporan Tahunan, Dividen, Neraca

### 7.1 Annual report screen
- [ ] Halaman memuat data tahunan terbaru saat dibuka.
- [ ] Tabel Revenue/Tax/Operation tampil tanpa crash.
- [ ] Grouping single/batch expense masuk ke section yang benar.

### 7.2 Input turunan annual
- [ ] Tombol `Input Revenue` membuka layar revenue management.
- [ ] Tombol `Input Pajak` membuka layar tax management.
- [ ] Tombol `Input Dividen` membuka layar dividend management.
- [ ] Tombol `Input Neraca` membuka layar balance sheet settings.
- [ ] Setelah kembali dari input screen, annual report refresh data.

### 7.3 Export annual
- [ ] Export annual PDF berhasil.
- [ ] Export annual Excel berhasil.
- [ ] Sheet utama + summary sheet terisi sesuai mapping terbaru.

---

## 8. Tema dan Keterbacaan UI

### 8.1 Light theme consistency
- [ ] Sidebar, card, tabel, dialog tidak menyisakan warna dark hardcoded.
- [ ] Font utama terlihat jelas (gelap di background terang).
- [ ] Halaman Settlement/Kasbon/Laporan/Kategori/Annual konsisten dengan style light theme.

### 8.2 Dark theme consistency
- [ ] Kontras di dark tetap baik.
- [ ] Komponen status badge tetap terbaca.

### 8.3 Warna semantik
- [ ] Alert success tetap hijau.
- [ ] Alert error tetap merah.
- [ ] Warning tetap kuning/oranye.

---

## 9. Pengaturan Sistem

### 9.1 Tema
- [ ] Toggle Light/Dark/System bekerja.
- [ ] Pilihan tema tersimpan setelah restart app.

### 9.2 Default tahun laporan
- [ ] Ubah default tahun berhasil disimpan.
- [ ] Screen report/annual membaca default tahun dengan benar.

### 9.3 Folder lampiran
- [ ] Ubah direktori penyimpanan berhasil.
- [ ] Data lama dipindahkan dengan aman (jika fitur aktif).

---

## 10. Error Handling dan Stabilitas

### 10.1 Error API/network
- [ ] Saat backend mati, UI menampilkan pesan koneksi yang jelas.
- [ ] Aplikasi tidak freeze saat request timeout.

### 10.2 Error asset/font Flutter
- [ ] Hot restart tidak memunculkan error `AssetManifest.bin` pada kondisi normal project.
- [ ] Font fallback tetap menampilkan teks (tidak blank).

### 10.3 Polling notifikasi
- [ ] Polling berhenti saat logout/keluar halaman yang dispose provider.
- [ ] Tidak ada lonjakan request berulang tak terkendali.

---

## 11. Skenario Smoke Test Cepat (15 Menit)

1. Login manager.
2. Buat kasbon draft, submit, approve.
3. Buat settlement dari kasbon, submit, approve.
4. Cek notifikasi manager/staff + deep-link tombol.
5. Ganti ke light theme dan cek keterbacaan halaman utama.
6. Export summary PDF/Excel.
7. Buka annual report, export PDF/Excel.

Semua langkah di atas harus `OK` sebelum release internal.

