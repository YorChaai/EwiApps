# Rencana UI Mobile Bertahap

Dokumen ini dipakai sebagai checklist kerja bertahap agar perubahan UI mobile tidak saling tabrak.

## Istilah Untuk Permintaan Baru

Permintaan tambahan tentang bagian atas yang tetap, sementara konten bawah bisa scroll, paling dekat dengan pola berikut:

- `Collapsing Header`
- `Collapsing Toolbar`
- `Scroll Behavior / Hide on Scroll`
- Di Android biasanya terkait dengan:
  - `CollapsingToolbarLayout`
  - `AppBarLayout + scroll flags`
  - Di Flutter pendekatannya biasanya memakai `NestedScrollView`, `CustomScrollView`, `SliverAppBar`, atau `SliverPersistentHeader`

## Checklist Progres

- [x] Tahap 1: Ubah nav Android jadi dropdown overlay di area profil
- [x] Tahap 1: Sembunyikan tab besar mobile yang makan ruang di Android
- [x] Tahap 2: Rapikan struktur scroll list mobile agar app bar tetap fixed dan blok header/filter bisa collapse saat list di-scroll
- [x] Tahap 3: Samakan action bar mobile di halaman detail dengan logic desktop
- [x] Tahap 4: Tambahkan tombol kecil `scroll to top` di list settlement dan kasbon
- [x] Tahap 5: Tambahkan mode pilih manual untuk delete multiple item
- [x] Tahap 6: Rapikan posisi tombol agar mode delete, scroll-to-top, dan action lain tidak saling bentrok
- [x] Tahap 7: Verifikasi hasil akhir di Android dan desktop

## Ringkasan Kebutuhan Dari User

### 1. UI Android

- Navigasi Android harus muncul secara vertikal seperti dropdown `PopupMenu` atau `PopupWindow`
- Dropdown harus berbentuk overlay
- Dropdown tidak boleh menggeser layout atau mengambil ruang permanen
- Dropdown hanya untuk Android
- Tampilan PC tidak perlu mengikuti pola ini
- Isi menu mengikuti fitur aplikasi yang sudah ada: `Settlements`, `Kasbon`, `Laporan`, dan jika ada menu lain yang memang aktif di mobile maka ikut logic existing

### 2. Detail Mobile Harus Ikut Logic Desktop

- Di halaman detail mobile, tombol aksi tidak boleh dibuat dengan rule baru
- Yang harus dipakai adalah logic yang sudah benar di PC
- Setiap halaman bisa punya kombinasi tombol berbeda sesuai status dan role
- Contoh:
  - settlement: kadang hanya `Draft` dan `Submit`
  - setelah submit bisa muncul `Approve` dan `Move to Draft`
  - kasbon: bisa muncul `IN_SETTLEMENT`, `Lihat Settlement`, `Tambah Revisi`, dan lain-lain sesuai kondisi
  - laporan: tombol seperti `PDF` harus ikut tampil jika memang ada di versi PC
  - kategori: jika ada action di PC dan memang relevan di mobile, ikutkan sesuai logic existing

### 3. Scroll Behavior Untuk List Mobile

- Yang diinginkan adalah pola bagian atas tetap rapi sementara konten bawah tetap bisa scroll normal
- App bar Android boleh tetap fixed
- Area judul, tombol buat, summary, search, dan filter tidak boleh membuat area daftar terasa macet
- Perilaku yang dicari dekat dengan `Collapsing Header` atau `Hide on Scroll`

### 4. Scroll To Top

- Tambahkan ikon kecil panah ke atas
- Ikon jangan terlalu besar agar tidak mudah terpencet
- Muncul hanya di halaman list settlement dan list kasbon
- Tidak muncul di halaman detail
- Berlaku untuk Android dan PC

### 5. Delete Manual Multiple

- Tetap mulai dari tombol sampah
- Saat tombol sampah ditekan, baru masuk mode pilih manual
- Checklist muncul di sebelah kanan item
- User bisa pilih banyak item secara manual
- Setelah item dipilih, baru bisa dilakukan hapus
- Berlaku untuk Android dan PC
- Posisi tombol lain seperti `scroll to top` harus diatur supaya tidak tabrakan dengan mode delete

## Catatan Implementasi

- Fokus utama sekarang bukan membuat logic baru, tetapi memperbaiki perilaku mobile agar konsisten dengan versi desktop.
- Untuk list mobile, target perilakunya:
  - app bar Android tetap terlihat
  - bagian judul, tombol buat, summary, search, dan filter tidak mengunci layout
  - daftar item di bawah tetap bisa di-scroll normal
- Untuk detail mobile, tombol action harus mengikuti role dan status yang sudah ada di aplikasi desktop.
