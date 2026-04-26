# Panduan Rilis ExspanApp

Laporan status build release untuk aplikasi **ExspanApp** pada tanggal **23 April 2026**.

## 📱 Android (APK)
Aplikasi versi Android telah berhasil di-build.
- **File**: `frontend\build\app\outputs\flutter-apk\app-release.apk`
- **Ukuran**: ~60.9 MB
- **Cara Install**:
  1. Copy file `.apk` ke HP Android.
  2. Buka file tersebut dan berikan izin "Install from unknown sources" jika diminta.

## 💻 Windows (EXE)
Aplikasi versi Windows Desktop telah berhasil di-build.
- **Folder**: `frontend\build\windows\x64\runner\Release\`
- **File Utama**: `ExspanApp.exe`
- **Cara Menjalankan**:
  1. Masuk ke folder release tersebut.
  2. Jalankan `ExspanApp.exe`.
  3. **Catatan**: Jika ingin dipindahkan ke komputer lain, kamu harus meng-copy **seluruh isi folder** tersebut (termasuk file `.dll` didalamnya), bukan hanya file `.exe` saja.

## 🛠️ Langkah Lanjutan (Opsional)
- **Installer Windows**: Jika ingin membuat satu file installer (seperti `.msi` atau `setup.exe`), kamu bisa menggunakan tools seperti *Inno Setup* atau *MSIX Packaging Tool*.
- **Play Store/App Store**: Jika ingin diupload ke store, diperlukan langkah tambahan seperti *App Signing* dan pembuatan akun developer.

---
*Dibuat otomatis oleh Antigravity AI.*
