# Rencana Implementasi - Sinkronisasi UI (Kasbon & Settlement)

Rencana ini bertujuan untuk menyelaraskan "Adaptive Compact Mode" di kedua layar, memastikan baris tombol aksi Kasbon se-ringkas Settlement, sambil mempertahankan metadata penting dan meningkatkan desain saat data kosong di Settlement.

## Butuh Review Pengguna

> [!IMPORTANT]
> - **Action Bar Kasbon**: Saya akan memindahkan badge "DRAFT" ke **AppBar** (kanan atas) dan mengubah tombol menjadi **Ikon Saja** (pensil/pesawat kertas) agar persis dengan gaya Settlement yang Anda sukai.
> - **Metadata**: Baris "Dibuat oleh" dan "Tanggal" di Kasbon akan **tetap ditampilkan**, sesuai permintaan Anda.
> - **State Kosong**: Saya akan menambahkan desain tombol tengah "Tambah Item Sekarang" ke **Settlement**, agar kedua layar terlihat konsisten saat belum ada item yang ditambahkan.

## Perubahan yang Diusulkan

### [Advance Detail Screen](file:///D:/2. Organize/1. Projects/MiniProjectKPI_EWI/frontend/lib/screens/advance/advance_detail_screen.dart)

#### [MODIFY] `advance_detail_screen.dart`
- **AppBar**: Pindahkan badge status (Draft/Approved/dll) ke dalam array `actions` (kanan atas).
- **Mobile Action Bar**: Update `_buildMobileAdvanceActionBar` untuk menghapus badge dari baris tersebut dan mengubah tombol menjadi mode ikon-saja menggunakan `SettlementActionButton`.
- **Visibilitas Metadata**: Update `_buildContent` agar baris "Dibuat oleh" dan "Tanggal" tetap muncul meskipun dalam mode compact.

---

### [Settlement Detail Screen](file:///D:/2. Organize/1. Projects/MiniProjectKPI_EWI/frontend/lib/screens/settlement/settlement_detail_screen.dart)

#### [MODIFY] `settlement_detail_screen.dart`
- **State Kosong**: Ganti teks "Belum ada expense" yang sederhana dengan desain `_buildEmptyState` yang terstruktur dari Kasbon (Ikon Besar + Teks + Tombol "Tambah Item Sekarang").

## Rencana Verifikasi

### Verifikasi Manual
- **Layar Kasbon**: Pastikan badge status ada di kanan atas dan tombol berupa ikon saja. Cek apakah "Dibuat oleh" masih muncul.
- **Layar Settlement**: Pastikan saat tabel kosong, muncul desain state kosong yang baru dengan tombol biru di tengah.
- **Side-by-Side**: Bandingkan kedua layar untuk memastikan keduanya berbagi bahasa visual yang sama untuk header dan aksi.
