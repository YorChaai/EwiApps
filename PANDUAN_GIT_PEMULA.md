# Panduan Git & GitHub Lengkap (Bahasa Indonesia)

Panduan ini berisi langkah-langkah detail untuk mengelola proyek kamu.

---

## 1. Alur Rutin: Cara Menyimpan & Push ke GitHub
Lakukan ini setiap kali kamu selesai melakukan perubahan pada kode:

1.  **Cek file yang berubah**:
    ```bash
    git status
    ```
2.  **Tandai file untuk disimpan**:
    ```bash
    git add .
    ```
3.  **Beri nama pada simpanan tersebut (Commit)**:
    ```bash
    git commit -m "Tulis pesan perubahan kamu di sini"
    ```
4.  **Kirim ke online (GitHub)**:
    ```bash
    git push origin main
    ```

---

## 2. Cara Melihat Sejarah Perubahan (History)
Kamu bisa melihat kapan saja perubahan dilakukan dan oleh siapa.

### Lewat Terminal:
```bash
git log --oneline
```
*(Ini akan menampilkan daftar singkat pesan commit kamu)*

### Lewat GitHub (Lebih Visual):
1.  Buka [Halaman GitHub Proyek](https://github.com/YorChaai/EwiApps)
2.  Klik angka di sebelah tulisan **"Commits"** (ikon jam kecil).
3.  Klik pada salah satu commit untuk melihat **garis warna hijau/merah** (apa yang ditambah/dihapus).

---

## 3. Cara Kembali ke Versi Sebelumnya (Undo/Revert)
Jika kamu membuat kesalahan dan ingin membatalkan perubahan:

### A. Membatalkan perubahan yang BELUM di-commit:
Jika kamu baru saja edit file tapi belum mengetik `git commit`, dan ingin file kembali seperti semula:
```bash
git restore .
```

### B. Membatalkan perubahan yang SUDAH di-push (Revert):
Jika kamu ingin membatalkan satu commit tertentu secara aman:
1.  Cari ID commit (pakai `git log --oneline`). Contoh ID: `abc1234`.
2.  Ketik:
    ```bash
    git revert abc1234
    ```
3.  Lalu `git push` lagi.

### C. Kembali "Total" ke awal (Hati-hati!):
Jika ingin membuang SEMUA perubahan terbaru dan kembali ke versi terakhir yang ada di GitHub:
```bash
git reset --hard origin/main
```
> [!CAUTION]
> Perintah ini akan menghapus semua pekerjaan kamu yang belum disimpan/push. Pastikan kamu benar-benar ingin membuangnya.

---

## 4. Rangkuman Tombol Cepat (Cheatsheet)

| Keinginan | Ketik di Terminal |
| :--- | :--- |
| Simpan semua kerjaan | `git add .` |
| Kasih nama simpanan | `git commit -m "pesan"` |
| Kirim ke GitHub | `git push` |
| Ambil data dari GitHub | `git pull` |
| Lihat daftar simpanan | `git log --oneline` |
| Batalkan edit terbaru | `git restore .` |

---

## 5. Tanya Jawab (FAQ)
*   **Q: Bisa tidak saya hapus di laptop tapi di GitHub tetap ada?**
    *   A: Jangan. Git akan mencatat penghapusan itu sebagai perubahan. Jika di-push, file di GitHub juga akan hilang.
*   **Q: Apa bedanya `main` dan `master`?**
    *   A: Itu cuma nama cabang utama. Proyek kamu sekarang pakai nama `main`.
*   **Q: Apakah data saya aman?**
    *   A: Ya, selama kamu tidak membagikan token rahasia GitHub kamu. Data database (`.db`) juga sudah disembunyikan agar tidak ter-upload.
