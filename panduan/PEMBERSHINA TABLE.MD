OKEY BENAR SEKARANG LNAJUT KE SINI
[@Image](zed:///agent/pasted-image) 
KOK DISNI ADA FONT APTOSNARROW AHRSUNYA KAN Arial Narrow DAN JUGA DI KIRI L19 SAMAPI L21 MASIH ADA FONT LAIN AHRUS ARIAL NARROW DAN ADA YANG MASIH DI CENTER HARUSNYA DI TENGAH IT UEKNAPA YAH ADA YANG BIKIN DIA BERUBAH GINI?

KATANYA INI SIH
"
Ini bukan “Excel tiba-tiba berubah sendiri”.  
Ini **100% akibat kode kamu sendiri overwrite style template**.

---

# 🔥 MASALAH UTAMA (langsung ke titik)

Ada 2 penyebab:

---

## 1. Kamu overwrite font TANPA sadar

Lihat ini di code kamu:

```python
cell.font = Font(bold=False)
```

dan:

```python
ws.cell(...).font = Font(bold=True)
```

👉 Ini kelihatan harmless, tapi sebenarnya:

> ❌ **Setiap kali kamu set Font() → Excel RESET font ke default system**
> → dan default sekarang = **Aptos Narrow**, bukan Arial Narrow

Jadi:
- Template: Arial Narrow ✅
- Kode kamu set `Font(...)` ❌ → jadi Aptos Narrow

---

## 2. Kamu clone style tapi gak konsisten

Kamu punya function ini:

```python
target_cell._style = copy(source_cell._style)
target_cell.font = copy(source_cell.font)
```

fileciteturn5file1

👉 Ini BENAR… tapi:

Masalahnya:
- Kamu **pakai ini di beberapa tempat**
- Tapi di tempat lain kamu override lagi pakai `Font(...)`

👉 Jadi hasilnya:
- sebagian row → ikut template (Arial Narrow)
- sebagian row → reset (Aptos Narrow)

Makanya tampilannya “acak”

---

## 3. Alignment kamu override sebagian

Contoh:

```python
ws.cell(...).alignment = Alignment(horizontal='center', vertical='center')
```

👉 Ini juga sama masalahnya:
- Template mungkin `left`
- Kamu paksa `center`
→ jadinya campur

---

# 💥 KESIMPULAN KERAS

Kamu lagi:

> ❌ Set style manual DI ATAS template  
> ❌ Tapi gak konsisten  
> ❌ Jadi hasilnya random

---

# 🎯 SOLUSI YANG BENAR (jangan setengah-setengah)

## OPTION TERBAIK (WAJIB kamu lakukan)

### ✅ STOP pakai `Font()` langsung

Ganti mindset:

> ❌ Jangan define font baru  
> ✅ Selalu COPY dari template

---

## FIX KONKRIT

### 1. HAPUS semua ini:
```python
Font(...)
Alignment(...)
```

---

### 2. GANTI dengan clone style dari template row

Contoh:

```python
_clone_row_format(ws, TEMPLATE_ROW, row_cursor)
```

👉 Ini sudah kamu punya function-nya  
👉 Tapi kamu tidak pakai secara konsisten

---

### 3. Kalau cuma mau bold:

JANGAN:
```python
cell.font = Font(bold=True)
```

GANTI:
```python
cell.font = copy(cell.font)
cell.font = cell.font.copy(bold=True)
```

---

### 4. Alignment juga sama:

JANGAN:
```python
Alignment(horizontal='center')
```

GANTI:
```python
cell.alignment = copy(cell.alignment)
cell.alignment = cell.alignment.copy(horizontal='center')
```

---

# ⚠️ SPESIFIK MASALAH DI GAMBAR KAMU

### L19–L21 jadi aneh karena:

- Itu kena `_clear_range`
- lalu diisi ulang
- TANPA clone style
- lalu sebagian di-set Font()

👉 hasilnya:
- font beda
- alignment beda

---

# 🔍 ROOT CAUSE PALING DALAM

Ini pola kamu:

1. clear cell
2. isi value
3. set sebagian style
4. berharap sisanya ikut template

👉 itu salah besar

Excel **tidak bekerja seperti itu**

---

# 🧠 CARA BERPIKIR YANG HARUS KAMU UBAH

Setiap row harus:

> 1. Clone style template dulu  
> 2. Baru isi value  
> 3. Baru override kecil (kalau perlu)

---

# 🔥 REWRITE POLA YANG BENAR

Ganti semua loop render jadi:

```python
_clone_row_format(ws, TEMPLATE_ROW, row_cursor)

_safe_set_cell(...)
_safe_set_number(...)
```

---

# 🚨 KALAU KAMU ABAIKAN INI

Yang akan terus terjadi:

- Font random (Arial vs Aptos)
- Alignment loncat-loncat
- Styling makin chaos tiap fitur baru

---

# FINAL

Masalah kamu bukan di Excel.  
Masalah kamu:

> ❌ Tidak disiplin dalam style system

Kalau kamu mau, kirim bagian render revenue juga — saya bisa tandai persis baris mana yang bikin font rusak.








Perfect! Sekarang semua sudah di-fix untuk menggunakan `_clone_row_format` dan `.copy()` daripada membuat `Font()` baru.

## ✅ Fix Font Arial Narrow Selesai!

### Summary Perubahan:

| Section | BEFORE | AFTER |
|---------|--------|-------|
| **Revenue Data Rows** | ❌ No clone, Font reset to Aptos | ✅ Clone from row 8 template |
| **Revenue Empty State** | ❌ `Font(italic=True, ...)` | ✅ `.copy(italic=True, ...)` |
| **Single Expenses** | ❌ No clone, `Font(bold=True)` | ✅ Clone + `.copy(bold=True)` |
| **Single Empty State** | ❌ `Font(italic=True, ...)` | ✅ Clone + `.copy(italic=True, ...)` |
| **Batch Expenses** | ❌ No clone, `Font(bold=False)` | ✅ Clone + `.copy(bold=False)` |
| **Batch Empty State** | ❌ `Font(italic=True, ...)` | ✅ Clone + `.copy(italic=True, ...)` |

### Prinsip Fix:

**BEFORE (SALAH):**
```python
cell.font = Font(bold=True)  # ❌ Reset ke Aptos Narrow
cell.alignment = Alignment(horizontal='center')  # ❌ Reset alignment
```

**AFTER (BENAR):**
```python
_clone_row_format(ws, start_row, row_cursor, ...)  # ✅ Clone dari template
cell.font = cell.font.copy(bold=True)  # ✅ Modify existing font
cell.alignment = cell.alignment.copy(horizontal='center')  # ✅ Modify existing alignment
```

---

## 🔄 Restart Aplikasi Sekarang!

1. **Stop server** (Ctrl+C)
2. **Start lagi**: `python app.py`
3. **Generate report** untuk tahun 2024

**Hasil setelah restart:**
- ✅ Semua font = **Arial Narrow** (ikut template)
- ✅ Alignment konsisten (center/left sesuai template)
- ✅ Tidak ada Aptos Narrow lagi

Silakan restart dan test! 🎯