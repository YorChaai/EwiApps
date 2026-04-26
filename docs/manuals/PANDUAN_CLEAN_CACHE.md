# PANDUAN CLEAN CACHE - Python & Flutter

**Dibuat:** 22 Maret 2026  
**Update:** 22 Maret 2026

Panduan ini menjelaskan cara membersihkan cache Python (backend) dan Flutter (frontend) untuk mengatasi error aneh atau masalah build.

---

## 🧹 KAPAN PERLU CLEAN CACHE?

Clean cache diperlukan ketika:
- ✅ Ada error aneh yang tidak jelas penyebabnya
- ✅ Perubahan kode tidak terlihat setelah hot reload
- ✅ Setelah update dependencies (pip install / flutter pub add)
- ✅ Sebelum commit ke git
- ✅ Build gagal tanpa alasan yang jelas
- ✅ Module not found error

**TIDAK perlu clean cache untuk:**
- ❌ Coding sehari-hari (hot reload cukup)
- ❌ Perubahan kecil (tambah print statement)
- ❌ Testing cepat

---

## 🐍 CLEAN CACHE PYTHON (Backend)

### Metode 1: Manual (PowerShell)

```powershell
# 1. Masuk ke folder backend
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'

# 2. Hapus folder __pycache__
Remove-Item -Recurse -Force __pycache__
Remove-Item -Recurse -Force routes\__pycache__
Remove-Item -Recurse -Force routes\reports\__pycache__
Remove-Item -Recurse -Force scripts\__pycache__

# 3. Hapus file .pyc (jika ada)
Get-ChildItem -Recurse -Filter "*.pyc" | Remove-Item -Force

# 4. Hapus .pytest_cache (jika ada)
Remove-Item -Recurse -Force .pytest_cache -ErrorAction SilentlyContinue
```

### Metode 2: One-Liner (Copy-Paste)

```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'; Remove-Item -Recurse -Force __pycache__ -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force routes\__pycache__ -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force routes\reports\__pycache__ -ErrorAction SilentlyContinue; Remove-Item -Recurse -Force scripts\__pycache__ -ErrorAction SilentlyContinue
```

### Metode 3: CMD (Command Prompt)

```cmd
cd "D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend"
rd /s /q __pycache__
rd /s /q routes\__pycache__
rd /s /q routes\reports\__pycache__
rd /s /q scripts\__pycache__
```

---

## 🐦 CLEAN CACHE FLUTTER (Frontend)

### Metode 1: Standard (Recommended)

```powershell
# 1. Masuk ke folder frontend
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'

# 2. Clean build files
flutter clean

# 3. Get dependencies again
flutter pub get

# 4. Run aplikasi
flutter run -d windows
```

### Metode 2: Deep Clean (Jika ada masalah serius)

```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'

# Clean build + pub cache
flutter clean
flutter pub cache clean
flutter pub get

# Rebuild
flutter run -d windows
```

### Metode 3: Manual (Jika flutter clean gagal)

```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'

# Hapus folder manual
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .dart_tool -ErrorAction SilentlyContinue

# Get dependencies
flutter pub get
```

### One-Liner (Copy-Paste)

```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'; flutter clean; flutter pub get
```

---

## 🔄 RESTART APLIKASI

Setelah clean cache, **WAJIB restart** aplikasi:

### Backend:
```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'

# Stop server lama (Ctrl+C di terminal yang sedang berjalan)
# Lalu jalankan lagi
venv\Scripts\activate
python app.py
```

### Frontend:
```powershell
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'

# Quit aplikasi lama (q di terminal atau Ctrl+C)
# Lalu jalankan lagi
flutter run -d windows
```

---

## ⚠️ ERROR YANG UMUM TERJADI

### Error: "Cannot find path ... because it does not exist"

**Penyebab:** Folder sudah tidak ada (sudah dihapus sebelumnya)

**Solusi:** Tidak perlu lakukan apa-apa, ini justru bagus! ✅

```powershell
Remove-Item : Cannot find path '...\__pycache__' because it does not exist.
```
→ Artinya folder sudah bersih, langsung restart aplikasi saja.

---

### Error: "Module not found" (Python)

**Penyebab:** Cache __pycache__ korup atau outdated

**Solusi:**
```powershell
# Backend
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'
Remove-Item -Recurse -Force __pycache__
pip install -r requirements.txt
python app.py
```

---

### Error: "Package not found" (Flutter)

**Penyebab:** Pub cache korup

**Solusi:**
```powershell
# Frontend
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'
flutter clean
flutter pub cache clean
flutter pub get
flutter run -d windows
```

---

### Error: "Build failed" setelah update kode

**Penyebab:** Build cache outdated

**Solusi:**
```powershell
# Frontend
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'
flutter clean
flutter pub get
flutter run -d windows
```

---

## 📊 PERBEDAAN CLEAN VS TIDAK CLEAN

| Aspek | Setelah Clean | Tidak Clean |
|-------|---------------|-------------|
| **Build pertama** | Lebih lama (compile ulang) | Lebih cepat (pakai cache) |
| **Perubahan kode** | Langsung terlihat | Kadang perlu restart manual |
| **Error aneh** | ✅ Tidak ada | ❌ Bisa muncul |
| **Module not found** | ✅ Tidak ada | ❌ Bisa muncul |
| **Hot reload** | ✅ Stabil | ⚠️ Kadang gagal |

---

## 💡 TIPS & BEST PRACTICES

### 1. Frekuensi Clean
- **Backend (Python):** 1x per minggu atau saat ada error
- **Frontend (Flutter):** 1x per minggu atau setelah pub add

### 2. Backup Sebelum Clean
```powershell
# Backup database (PENTING!)
Copy-Item 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\database.db' `
          'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\database_backup_20260322.db'
```

### 3. Clean Aman
- ✅ `flutter clean` → Aman, tidak hapus kode
- ✅ `Remove-Item __pycache__` → Aman, auto re-generate
- ❌ `Remove-Item migrations` → **BAHAYA!** Bisa hilangin migration history
- ❌ `Remove-Item venv` → **BAHAYA!** Harus install ulang semua package

### 4. Verifikasi Setelah Clean
```powershell
# Backend - cek tidak ada __pycache__
Get-ChildItem -Recurse -Directory -Filter "__pycache__"

# Frontend - cek build bersih
Test-Path 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\build'
# Harus return: False
```

---

## 🔗 COMMAND QUICK REFERENCE

### Backend (PowerShell)
```powershell
# Clean cache
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend'
Remove-Item -Recurse -Force __pycache__ -ErrorAction SilentlyContinue

# Restart
venv\Scripts\activate
python app.py
```

### Frontend (PowerShell)
```powershell
# Clean cache
cd 'D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend'
flutter clean
flutter pub get

# Restart
flutter run -d windows
```

---

## 📚 FILE YANG DIHAPUS SAAT CLEAN

### Backend (Python)
| Folder/File | Aman Dihapus? | Auto Re-generate? |
|-------------|---------------|-------------------|
| `__pycache__/` | ✅ Ya | ✅ Ya (saat run) |
| `*.pyc` | ✅ Ya | ✅ Ya (saat run) |
| `.pytest_cache/` | ✅ Ya | ✅ Ya (saat test) |
| `migrations/versions/*.pyc` | ✅ Ya | ✅ Ya (saat run) |
| `venv/` | ❌ **JANGAN!** | ❌ Harus install ulang |
| `database.db` | ❌ **JANGAN!** | ❌ Data hilang! |

### Frontend (Flutter)
| Folder/File | Aman Dihapus? | Auto Re-generate? |
|-------------|---------------|-------------------|
| `build/` | ✅ Ya | ✅ Ya (saat build) |
| `.dart_tool/` | ✅ Ya | ✅ Ya (saat run) |
| `.packages` | ✅ Ya | ✅ Ya (pub get) |
| `pubspec.lock` | ⚠️ Bisa | ✅ Ya (pub get) |
| `android/app/build/` | ✅ Ya | ✅ Ya (saat build) |

---

## 🎯 TROUBLESHOOTING

### Problem: "Access denied" saat hapus folder

**Solusi:**
```powershell
# Tutup aplikasi dulu (stop Python/Flutter)
# Lalu coba lagi
Remove-Item -Recurse -Force __pycache__
```

### Problem: "flutter clean" stuck/hang

**Solusi:**
```powershell
# Ctrl+C untuk stop
# Hapus manual
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force .dart_tool
flutter pub get
```

### Problem: Error masih ada setelah clean

**Solusi:**
1. Restart komputer (kadang ada file yang locked)
2. Clean lebih dalam: `flutter pub cache clean`
3. Reinstall dependencies: `pip install -r requirements.txt --force-reinstall`

---

## 📞 SUMMARY

**Clean cache itu seperti "restart" untuk project coding:**
- Menghilangkan file temporary yang mungkin korup
- Memaksa rebuild dari awal
- Mengatasi error aneh yang tidak jelas

**Lakukan clean cache:**
- Saat ada error aneh
- Setelah update dependencies
- Sebelum commit besar
- 1x per minggu untuk maintenance

**Jangan clean cache:**
- Setiap kali coding (hot reload cukup)
- Saat sedang debugging (bisa hilangin trace)
- Tanpa backup database

---

**Status:** ✅ Ready to Use  
**Related Files:**
- `backend/__pycache__/`
- `frontend/build/`
- `frontend/.dart_tool/`
