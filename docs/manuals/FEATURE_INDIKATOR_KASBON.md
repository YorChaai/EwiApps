# FEATURE: Indikator Kasbon di Settlement Card

**Tanggal:** 22 Maret 2026  
**Feature:** Tambah logo kasbon warna kuning di settlement card untuk settlement yang berasal dari kasbon

---

## 🎯 YANG DITAMBAHKAN

Logo 💰 (wallet icon) warna kuning (#FFA500) akan muncul di **kanan atas** settlement card jika settlement tersebut dibuat dari kasbon.

### Tampilan

**Settlement BUKAN dari kasbon:**
```
┌─────────────────────────────────────────┐
│ Gaji mael                    Rp 5.000.000 │
│ Manager · 1 item        APPROVED    >   │
└─────────────────────────────────────────┘
```

**Settlement DARI kasbon:**
```
┌─────────────────────────────────────────┐
│ Gaji mael              💰 Rp 5.000.000 │
│ Manager · 1 item        APPROVED    >   │
└─────────────────────────────────────────┘
```

---

## 📁 FILE YANG DIUBAH

**File:** `frontend/lib/screens/widgets/settlement_widgets.dart`

**Perubahan:**
1. Tambah logic cek `advance_id != null` di SettlementCard
2. Tambah icon wallet dengan background orange lembut
3. Support untuk desktop dan mobile view

---

## 🎨 DESIGN DETAIL

### Icon
- **Icon:** `Icons.account_balance_wallet_rounded` (wallet/brankas)
- **Size:** 16px (desktop), 14px (mobile)
- **Color:** `#FFA500` (orange/kuning)
- **Background:** Orange dengan alpha 0.15 (transparan)
- **Border Radius:** 4px (rounded corners)

### Posisi
- **Desktop:** Di antara judul dan amount
- **Mobile:** Di sebelah amount (di baris terpisah)

### Tooltip
- **Text:** "Settlement dari Kasbon"
- Muncul saat hover di atas icon

---

## 🔍 LOGIC DETEKSI

```dart
if (s['advance_id'] != null && s['advance_id'] != 0) {
  // Tampilkan logo kasbon
}
```

**Penjelasan:**
- `advance_id` adalah field di settlement yang link ke kasbon
- Jika `null` atau `0` → settlement manual (bukan dari kasbon)
- Jika ada angka → settlement dari kasbon

---

## 📊 CONTOH VISUAL

### Desktop View (> 300px width)
```
┌──────────────────────────────────────────────────┐
│ ALFA Service PDP-075            💰 Rp 29.640.916 │
│ Staff · 1 item              APPROVED         >   │
└──────────────────────────────────────────────────┘
```

### Mobile View (< 300px width)
```
┌──────────────────────────┐
│ ALFA Service PDP-075     │
│ Staff · 1 item           │
│ 💰 Rp 29.640.916         │
│ APPROVED              >  │
└──────────────────────────┘
```

---

## 🧪 TESTING CHECKLIST

### Test 1: Settlement dari Kasbon
- [ ] Buka settlement yang dibuat dari kasbon
- [ ] **Expected:** Logo 💰 muncul di kanan atas (kuning)
- [ ] **Expected:** Tooltip "Settlement dari Kasbon" muncul saat hover

### Test 2: Settlement Manual (Bukan dari Kasbon)
- [ ] Buka settlement yang dibuat manual (tidak dari kasbon)
- [ ] **Expected:** TIDAK ada logo 💰
- [ ] **Expected:** Tampilan polos seperti biasa

### Test 3: Mobile View
- [ ] Resize window ke ukuran kecil (< 300px)
- [ ] **Expected:** Logo 💰 tetap muncul (di sebelah amount)
- [ ] **Expected:** Ukuran icon lebih kecil (14px)

### Test 4: Dark/Light Theme
- [ ] Switch ke dark theme
- [ ] **Expected:** Logo tetap terlihat jelas
- [ ] Switch ke light theme
- [ ] **Expected:** Logo tetap terlihat jelas

---

## 🎨 COLOR REFERENCE

```dart
Color(0xFFFFA500)  // Orange/kuning terang
```

**Warna yang dipakai:**
- **Icon:** `#FFA500` (solid)
- **Background:** `AppTheme.warning.withValues(alpha: 0.15)` (transparan)

**Alternatif warna kuning lain:**
```dart
Color(0xFFFFD700)  // Kuning emas (gold)
Color(0xFFFFEB3B)  // Kuning lembut (Material Yellow 500)
Color(0xFFFFC107)  // Kuning amber (Material Amber 500)
```

---

## 📝 NOTES

1. **Icon dipilih yang mirip dengan sidebar kasbon** → `account_balance_wallet_rounded`
2. **Warna kuning orange** → Kontras dengan background gelap dan terang
3. **Ukuran responsif** → Lebih kecil di mobile agar tidak terlalu dominan
4. **Tooltip informatif** → User tahu apa arti icon tersebut

---

## 🔗 RELATED FILES

- `frontend/lib/screens/widgets/settlement_widgets.dart` - SettlementCard widget
- `frontend/lib/screens/dashboard_screen.dart` - Settlement list view
- `frontend/lib/theme/app_theme.dart` - Theme colors

---

**Status:** ✅ Implemented  
**Tested:** ⏳ Pending user confirmation
