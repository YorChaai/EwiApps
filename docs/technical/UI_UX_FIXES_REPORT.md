# Dokumentasi Perbaikan UI/UX & Layout Flutter

Dokumen ini mencatat berbagai kasus (kasus penggunaan) terkait antarmuka pengguna (UI) dan pengalaman pengguna (UX) yang sering bermasalah pada aplikasi Flutter, terutama ketika berhadapan dengan responsivitas (Desktop vs Mobile) dan pergantian tema (Light vs Dark Mode).

Berikut adalah daftar masalah yang telah kita temukan dan selesaikan, yang bisa dijadikan acuan untuk pengembangan ke depannya:

## 1. Teks Terpotong (Text Overflow & Ellipsis)
**Kasus:** Pada daftar *Kasbon* atau *Settlement*, judul yang panjang terpotong menjadi titik-titik (`...`) seperti "ALFA Service JRK...". Pada dialog perhitungan Dividen, teks terpotong dan patah ke baris baru secara tidak rapi.
*   **Penyebab:** Penggunaan parameter `maxLines: 1` (atau 2) dipadukan dengan `overflow: TextOverflow.ellipsis` di dalam widget yang ruang horizontalnya terbatas (seperti `Expanded` di dalam `Row`).
*   **Solusi:** 
    *   **Wrap Text:** Menghapus parameter `maxLines` dan `overflow` agar teks secara alami turun ke baris baru (membungkus) tanpa memotong informasi penting.
    *   **LayoutBuilder / Wrap:** Untuk kotak metrik (seperti perhitungan dividen), daripada memaksakannya sejajar di dalam `Row`, kita menggunakan `LayoutBuilder` untuk mengecek lebar layar (`constraints.maxWidth < 500`). Jika sempit, ubah susunannya menjadi vertikal (`Column`); jika lebar, susun horizontal (`Row`).

## 2. Warna Teks Menghilang (Teks Putih di Light Mode)
**Kasus:** Saat tema aplikasi diubah ke *Light Mode*, teks pada nama penerima dividen, atau input field (Tanggal, Mata Uang) menjadi warna putih sehingga tidak terbaca karena menyatu dengan *background* yang juga terang.
*   **Penyebab:** Penggunaan warna statis secara langsung (seperti `Colors.white`) atau menggunakan variabel tema yang dikhususkan untuk *Dark Mode* (seperti `AppTheme.textPrimary` yang bernilai putih kusam) tanpa mengecek tema aktif.
*   **Solusi:** Menggunakan *helper function* yang mengecek `Theme.of(context).brightness`.
    ```dart
    Color _primaryText(BuildContext context) =>
        Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.textPrimary 
            : Colors.black87; // Paksa jadi hitam/gelap saat Light Mode
    ```

## 3. Label Input Terlalu Cepat Naik (Floating Label Behavior)
**Kasus:** Pada form tambah *Expense* atau *Kasbon*, label seperti "Mata Uang" atau "Kategori" sudah langsung melayang di atas garis kotak, padahal kotak inputannya belum dipilih dan masih kosong. Ini membuat *form* terlihat sudah terisi atau berantakan.
*   **Penyebab:** Penggunaan properti `floatingLabelBehavior: FloatingLabelBehavior.always` pada `InputDecoration`.
*   **Solusi:** Menghapus properti tersebut (membiarkannya ke mode *default* / *auto*). Dengan begitu, label akan bertindak sebagai *placeholder* (berada di tengah kotak) saat kosong, dan baru melayang naik ke atas saat *field* tersebut diklik atau sudah berisi data.

## 4. Judul Halaman Menabrak Tombol (AppBar Overflow)
**Kasus:** Di HP (layar sempit), tulisan "Laporan Tahunan" atau "Input Pajak" di sudut kiri atas bertabrakan dengan deretan tombol filter dan tombol *Export* di sudut kanan atas.
*   **Penyebab:** `AppBar` memiliki lebar absolut yang tidak mencukupi untuk memuat `title` dan `actions` secara bersamaan tanpa membungkus teks.
*   **Solusi:** Menyembunyikan judul dari `AppBar` jika layarnya sempit, dan memindahkannya ke dalam konten yang bisa di-scroll (`body`).
    ```dart
    // Di AppBar
    title: useCompact ? const SizedBox.shrink() : const Text('Judul'),
    
    // Di dalam Body (SingleChildScrollView)
    if (useCompact) Text('Judul', style: TextStyle(fontSize: 22, ...)),
    ```

## 5. Error Layar Merah (ScrollController Exception)
**Kasus:** Muncul error merah di konsol *The Scrollbar's ScrollController has no ScrollPosition attached* saat melakukan *Hot Restart* atau membuka *dialog*.
*   **Penyebab:** Menggunakan widget kustom `AppScrollbar` tanpa memberikan/menyambungkan `ScrollController` yang sama ke dalam `ListView` atau `SingleChildScrollView` di bawahnya. Flutter wajib tahu komponen mana yang posisi gulirnya (*scroll position*) sedang diukur oleh scrollbar tersebut.
*   **Solusi:** Membungkus area tersebut dengan `Builder`, membuat `ScrollController` baru, dan memasukkannya ke parameter `controller` di *kedua* widget tersebut (`AppScrollbar` dan `SingleChildScrollView`/`ListView`).

---
*Dokumen ini dibuat otomatis sebagai panduan resolusi masalah UI/UX di expense_app.*


Di dalam dokumen tersebut, saya telah merangkum 5 kasus utama berserta penyebab dan solusinya, yaitu:
1. **Teks Terpotong (Text Overflow & Ellipsis)**: Solusi menggunakan `Wrap Text` dan `LayoutBuilder`.
2. **Warna Teks Menghilang di Light Mode**: Solusi menggunakan fungsi pengecekan tema dinamis (`_primaryText`).
3. **Label Input Melayang (Floating Label Behavior)**: Solusi menonaktifkan mode `always` agar label kembali berfungsi ganda sebagai *hint/placeholder*.
4. **Judul Halaman Menabrak Tombol (AppBar Overflow)**: Solusi memindahkan judul dari atas (AppBar) ke bagian body (Scroll) khusus pada layar HP.
5. **Error Layar Merah (ScrollController Exception)**: Solusi penambahan `Builder` dan `ScrollController` pada setiap widget *Scrollbar* kustom.

Dokumen ini bisa Anda jadikan contekan atau *cheat sheet* jika di masa depan Anda menemui masalah atau error yang mirip di halaman Flutter yang lain!
