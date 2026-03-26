# 🚀 Quick Git Commands - EWI Project

## **Commit & Push Semua Perubahan (Fast Way)**

```bash
# 1. Masuk ke folder project
cd "D:\2. Organize\1. Projects\MiniProjectKPI_EWI"

# 2. Add semua file yang diubah
git add -A

# 3. Commit dengan pesan
git commit -m "fix: [deskripsi singkat]"

# 4. Push ke GitHub
git push
```

**Selesai!** ✅

---

## **Contoh Pesan Commit**

```bash
# Bug fix
git commit -m "fix: FAB tidak muncul di settlement screen"

# Fitur baru
git commit -m "feat: tambah export Excel untuk laporan"

# Update dokumentasi
git commit -m "docs: update panduan backend"

# Refactor code
git commit -m "refactor: optimasi query database"
```

---

## **Cek Status Git**

```bash
# Lihat file apa saja yang diubah
git status

# Lihat history commit
git log --oneline -5

# Lihat perubahan yang belum commit
git diff
```

---

## **Jika Ada Konflik**

```bash
# Pull dulu dari remote
git pull origin main

# Jika ada konflik, resolve manual di file yang konflik

# Setelah resolve, commit lagi
git add -A
git commit -m "resolve: merge conflict"
git push
```

---

## **Struktur Commit yang Baik**

```
type: deskripsi singkat

[type] = fix | feat | docs | refactor | test | chore
```

**Contoh:**
- `fix: overflow error di landscape mode`
- `feat: tambah tombol delete bulk`
- `docs: update README dengan screenshot`
- `refactor: bersihkan code yang tidak dipakai`

---

## **Tips**

✅ **Selalu `git add -A`** untuk add semua file sekaligus  
✅ **Pesan commit singkat & jelas** (max 50 karakter)  
✅ **Pull sebelum push** jika kerja tim  
✅ **Commit kecil-kecil** lebih baik daripada 1 commit besar  

❌ **Jangan commit file sensitive** (.env, password, API key)  
❌ **Jangan commit file besar** (>100MB)  
❌ **Jangan force push** ke branch main  

---

## **Shortcut Command (One-Liner)**

```bash
git add -A && git commit -m "fix: bug fixes" && git push
```

**Done!** 🎉
