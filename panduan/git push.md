# Panduan Git Push & Kelola Repository

Panduan ini membantu Anda melakukan pembaharuan kode ke repository (GitHub/GitLab) dengan aman dan menjelaskan beberapa pesan yang sering muncul di Windows.

## 1. Alur Kerja Standar (Workflow)

Ikuti langkah-langkah ini setiap kali Anda ingin menyimpan perubahan:

1. **Cek Status**: Lihat file apa saja yang berubah.
   ```powershell
   git status
   ```
2. **Tambah File**: Siapkan file untuk disimpan (Staging).
   ```powershell
   git add .
   ```
3. **Simpan (Commit)**: Berikan catatan singkat tentang apa yang Anda ubah.
   ```powershell
   git commit -m "Deskripsi perubahan Anda di sini"
   ```
4. **Kirim (Push)**: Kirim perubahan ke server online.
   ```powershell
   git push origin main
   ```

---

## 2. Penjelasan Pesan Peringatan

### LF akan diganti CRLF (`LF will be replaced by CRLF`)
> [!NOTE]
> **Ini BUKAN Error.** Ini adalah pesan informasi normal di sistem Windows.

**Apa artinya?**
*   **LF (Line Feed)** adalah cara sistem Linux/Mac menandai akhir baris teks.
*   **CRLF (Carriage Return Line Feed)** adalah cara sistem Windows menandai akhir baris teks.

Git secara otomatis mendeteksi bahwa kode Anda mungkin ditulis dengan format Linux (LF) dan akan menyesuaikannya agar kompatibel dengan sistem Windows (CRLF) saat file tersebut disentuh/diedit kembali. Anda bisa mengabaikan peringatan ini dengan aman.

---

## 3. Tips Menjaga Kebersihan Repository

### File Sementara Excel (`~$...`)
Saat Anda membuka file Excel (seperti laporan pengeluaran), Windows otomatis membuat file sementara yang dimulai dengan simbol `~$`. 
*   **Jangan masukkan file ini ke Git.**
*   Saya sudah memperbarui `.gitignore` agar file-file sampah ini tidak lagi muncul saat Anda mengetik `git status`.

### File Untracked Lainnya
Jika ada file hasil export (seperti `.xlsx` di folder `data/`) yang tidak ingin Anda simpan selamanya di Git, Anda bisa menghapusnya secara manual atau menambahkannya ke daftar `.gitignore`.

---

## 4. Cara Membatalkan Perintah
*   Jika salah mengetik `git add .`, gunakan: `git reset`
*   Jika ingin membatalkan perubahan di satu file: `git restore nama_file.dart`



Oke! Mari kita lakukan **Git Push** untuk semua perubahan yang sudah kita fix hari ini.

## 🚀 Langkah Git Push

Jalankan command ini di terminal:

### 1. **Cek Status**
```powershell
cd D:\2. Organize\1. Projects\MiniProjectKPI_EWI
git status
```

### 2. **Tambah Semua File yang Berubah**
```powershell
git add .
```

### 3. **Commit dengan Pesan Lengkap**
```powershell
git commit -m "Fix: Konsistensi style Excel & empty state handling

- Fix font Arial Narrow (clone style dari template, bukan Font() baru)
- Fix empty state messages untuk Table 1, 2, 3 (visible dengan D:E merged)
- Fix Currency Exchange format (#,##0, center aligned)
- Fix Date format (dd-mmm-yy)
- Fix Expense items font (normal, tidak bold seperti subcategory header)
- Fix Business Summary Deviden (center align, consistent row height)
- Fix Remark column (hapus inc.PPN11%, keep Pemungut)
- Add template example 'con: inc.PPN11%' di Q7
- Fix Table 2 column # (tidak ada angka 1 saat kosong)
- Fix filter year untuk revenue & tax (Python filter, bukan db.extract)"
```

### 4. **Push ke Repository**
```powershell
git push origin main
```

---

## 📝 Summary Perubahan Hari Ini

| Table | Fix |
|-------|-----|
| **Table 1 (Revenue)** | ✅ Font Arial Narrow, D:E merged saat kosong, "Belum ada data" visible |
| **Table 2 (Pajak)** | ✅ Font Arial Narrow, D:E merged, "Belum ada data" visible, kolom # kosong |
| **Table 3 (Expenses)** | ✅ Font Arial Narrow, expense items normal (tidak bold), "Belum ada data" visible |
| **Business Summary** | ✅ Deviden center align, row height konsisten |
| **General** | ✅ Date format dd-mmm-yy, Currency Exchange #,##0 center |

Silakan jalankan command di atas! 🎯