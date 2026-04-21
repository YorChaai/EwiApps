# 🧹 PANDUAN PEMBERSIHAN PROJECT (Flutter & Python)

Panduan ini berisi perintah-perintah terminal untuk membersihkan "sampah" build, cache, dan file sementara agar project Anda tetap rapi, ringan, dan bebas dari error aneh.

---

## 🚀 1. Pembersihan Cepat (One-Liner)
Jika Anda ingin membersihkan **SEMUANYA** (Python + Flutter + Sampah Umum) dalam satu perintah, copy-paste ini di terminal PowerShell:

```powershell
# Jalankan di root folder project
Get-ChildItem -Path . -Include __pycache__ -Recurse -Directory | Remove-Item -Recurse -Force; Get-ChildItem -Path . -Include *.pyc, .DS_Store, Thumbs.db, *.log -Recurse | Remove-Item -Force; cd frontend; flutter clean; cd ..; cd sample_app; flutter clean; cd ..
```

---

## 🐍 2. Pembersihan Python (Backend)
Python menghasilkan file `.pyc` dan folder `__pycache__` setiap kali dijalankan. Ini bisa dibersihkan secara rekursif (sampai ke sub-folder).

### Menghapus Cache Python
```powershell
# Menghapus semua folder __pycache__
Get-ChildItem -Path . -Include __pycache__ -Recurse -Directory | Remove-Item -Recurse -Force

# Menghapus semua file .pyc
Get-ChildItem -Path . -Include *.pyc -Recurse | Remove-Item -Force
```

---

## 🐦 3. Pembersihan Flutter (Frontend)
Flutter menyimpan hasil build yang sangat besar di folder `build/`. Sangat disarankan melakukan ini sebelum upload ke Git atau jika aplikasi terasa "berat".

### Membersihkan Folder Frontend Utama
```powershell
cd frontend
flutter clean
cd ..
```

### Membersihkan Folder Sample App (Jika ada)
```powershell
cd sample_app
flutter clean
cd ..
```

---

## 🗑️ 4. Menghapus Sampah Umum
File-file ini sering muncul otomatis dan tidak berguna untuk project.

| File | Deskripsi |
| :--- | :--- |
| `.DS_Store` | Sampah dari sistem Mac (sering muncul jika buka folder di Mac) |
| `Thumbs.db` | Sampah thumbnail Windows |
| `*.log` | File log yang sudah lama/tidak terpakai |

**Perintah hapus:**
```powershell
Get-ChildItem -Path . -Include .DS_Store, Thumbs.db, *.log -Recurse -Force | Remove-Item -Recurse -Force
```

---

## 💡 Tips Belajar Terminal
1. **PowerShell vs CMD**: Perintah di atas menggunakan **PowerShell** (terminal default di VS Code Windows).
2. **Tab Completion**: Selalu tekan tombol `Tab` saat mengetik folder (misal: ketik `cd fron` lalu tekan `Tab`) agar tidak salah ketik.
3. **Up Arrow**: Tekan tombol panah atas `↑` di keyboard untuk melihat perintah yang baru saja Anda jalankan tanpa harus mengetik ulang.
4. **Hati-hati**: Perintah `Remove-Item -Force` akan menghapus file secara permanen (tidak masuk Recycle Bin). Pastikan Anda berada di folder project yang benar!

---

**Status:** ✅ Update Terbaru - 19 April 2026
**Lokasi:** `panduan/PANDUAN_CLEAN_PROJECT_LENGKAP.md`
