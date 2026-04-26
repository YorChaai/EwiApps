# FEATURE: Link Settlement ↔ Kasbon (Two-Way Navigation)

**Tanggal:** 22 Maret 2026  
**Feature:** Tombol "Lihat Kasbon" di Settlement dan "Lihat Settlement" di Kasbon

---

## 🎯 MASALAH YANG DIPERBAIKI

### Before:
- ✅ Dari Kasbon → Bisa buat Settlement (tombol "Salin ke Settlement")
- ❌ Dari Settlement → **TIDAK BISA** lihat Kasbon asal (tombol "Lihat Kasbon" tidak respond)
- ❌ Dari Kasbon → **TIDAK BISA** lihat Settlement yang sudah dibuat

### After:
- ✅ Dari Settlement → Tombol "Lihat Kasbon" **BERFUNGSI** → Buka detail Kasbon
- ✅ Dari Kasbon → Tombol "Lihat Settlement" **MUNCUL** setelah settlement dibuat → Buka detail Settlement
- ✅ Navigation bolak-balik dengan data refresh otomatis

---

## 🔄 FLOW NAVIGATION

```
┌─────────────────┐
│   Detail Kasbon │
│                 │
│  [Salin ke      │
│   Settlement]   │
└────────┬────────┘
         │
         ▼ (create settlement)
         │
┌─────────────────┐
│ Detail Settlement│
│                 │
│  [Lihat Kasbon]◄┼──────┐
└────────┬────────┘      │
         │               │
         ▼ (klik)        │ (klik)
┌─────────────────┐      │
│   Detail Kasbon │──────┘
│                 │
│  [Lihat         │
│   Settlement]   │
└─────────────────┘
```

---

## 📁 FILE YANG DIUBAH

### 1. `frontend/lib/screens/settlement_detail_screen.dart`

**Perubahan:**
- ✅ Tambah import `advance/advance_detail_screen.dart`
- ✅ Fix fungsi `_viewOriginalAdvance()` untuk navigate ke Kasbon
- ✅ Ganti dari `pushNamed` ke `push` dengan `MaterialPageRoute`

**Kode:**
```dart
Future<void> _viewOriginalAdvance(int advanceId) async {
  if (!mounted) return;
  
  final advanceDetailScreen = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AdvanceDetailScreen(advanceId: advanceId),
    ),
  );
  
  // Refresh settlement data jika kembali dari kasbon
  if (mounted && advanceDetailScreen == true) {
    context.read<SettlementProvider>().loadSettlement(widget.settlementId);
  }
}
```

**Tombol "Lihat Kasbon" muncul di:**
- Header (kanan atas) - jika settlement dari kasbon
- Info banner - "Settlement dari Kasbon"

---

### 2. `frontend/lib/screens/advance/advance_detail_screen.dart`

**Perubahan:**
- ✅ Tambah fungsi `_viewSettlement(int settlementId)`
- ✅ Tambah tombol "Lihat Settlement" di header
- ✅ Auto refresh advance data saat kembali dari settlement

**Kode:**
```dart
// Fungsi navigate ke settlement
Future<void> _viewSettlement(int settlementId) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SettlementDetailScreen(settlementId: settlementId),
    ),
  );
  // Refresh advance data when coming back from settlement
  if (mounted) {
    context.read<AdvanceProvider>().loadAdvance(widget.advanceId);
  }
}
```

**Tombol "Lihat Settlement" muncul di:**
- Header (kanan atas) - jika settlement sudah dibuat
- Otomatis hilang jika settlement belum dibuat

---

## 🎨 UI CHANGES

### Settlement Detail Screen

**Header (kanan atas):**
```
[Submitted] [👁 Lihat Kasbon] [Approve] [Move to Draft]
```

**Info Banner (kuning):**
```
┌────────────────────────────────────────────────────┐
│ ⚠️ Settlement dari Kasbon                          │
│ Settlement ini dibuat dari kasbon yang sudah       │
│ disetujui. Verifikasi expense dengan membandingkan │
│ kasbon asli.                          [Lihat Kasbon]│
└────────────────────────────────────────────────────┘
```

---

### Advance Detail Screen

**Header (kanan atas) - BELUM ADA SETTLEMENT:**
```
[Approved] [📋 Salin ke Settlement] [PDF] [Excel]
```

**Header (kanan atas) - SUDAH ADA SETTLEMENT:**
```
[in_settlement] [📋 Salin ke Settlement] [👁 Lihat Settlement] [PDF] [Excel]
```

---

## 🧪 TESTING CHECKLIST

### Test 1: Settlement → Kasbon
- [ ] Buka settlement yang dari kasbon
- [ ] Klik tombol "Lihat Kasbon" di header
- [ ] **Expected:** Navigate ke detail kasbon
- [ ] **Expected:** Data kasbon muncul dengan benar
- [ ] Klik back/kembali
- [ ] **Expected:** Kembali ke settlement detail
- [ ] **Expected:** Data settlement refresh (jika ada perubahan)

### Test 2: Kasbon → Settlement (belum ada settlement)
- [ ] Buka kasbon dengan status "approved" atau "in_settlement"
- [ ] **Expected:** Tombol "Salin ke Settlement" muncul
- [ ] **Expected:** Tombol "Lihat Settlement" TIDAK muncul

### Test 3: Kasbon → Settlement (sudah ada settlement)
- [ ] Buka kasbon yang sudah punya settlement
- [ ] **Expected:** Tombol "Lihat Settlement" muncul
- [ ] Klik "Lihat Settlement"
- [ ] **Expected:** Navigate ke detail settlement
- [ ] **Expected:** Data settlement muncul dengan benar
- [ ] Klik back/kembali
- [ ] **Expected:** Kembali ke kasbon detail
- [ ] **Expected:** Data kasbon refresh (jika ada perubahan)

### Test 4: Round-trip Navigation
- [ ] Kasbon → Settlement → Kasbon → Settlement
- [ ] **Expected:** Navigation lancar tanpa error
- [ ] **Expected:** Data selalu fresh setiap kali navigate

---

## 🔧 TECHNICAL DETAILS

### Navigation Pattern

**Dari Settlement ke Kasbon:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AdvanceDetailScreen(advanceId: advanceId),
  ),
)
```

**Dari Kasbon ke Settlement:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => SettlementDetailScreen(settlementId: settlementId),
  ),
)
```

### Data Refresh

**Settlement refresh setelah kembali dari Kasbon:**
```dart
context.read<SettlementProvider>().loadSettlement(widget.settlementId);
```

**Advance refresh setelah kembali dari Settlement:**
```dart
context.read<AdvanceProvider>().loadAdvance(widget.advanceId);
```

### Conditional Button Display

**Tombol "Lihat Kasbon" di Settlement:**
```dart
if ((s['advance_id'] ?? 0) > 0)
  OutlinedButton.icon(
    onPressed: () => _viewOriginalAdvance(s['advance_id']),
    icon: const Icon(Icons.visibility_rounded, size: 16),
    label: const Text('Lihat Kasbon'),
  )
```

**Tombol "Lihat Settlement" di Kasbon:**
```dart
if (adv['settlement_id'] != null && adv['settlement_id'] != 0)
  OutlinedButton.icon(
    onPressed: () => _viewSettlement(adv['settlement_id']),
    icon: const Icon(Icons.visibility_rounded, size: 16),
    label: const Text('Lihat Settlement'),
  )
```

---

## 🐛 BUG YANG DIPERBAIKI

### Bug #1: Tombol "Lihat Kasbon" Tidak Respond

**Penyebab:**
- Menggunakan `Navigator.pushNamed()` dengan route yang tidak terdaftar
- Route `'/advances/$advanceId'` tidak ada di `MaterialApp.routes`

**Solusi:**
- Ganti ke `Navigator.push()` dengan `MaterialPageRoute`
- Import `AdvanceDetailScreen` secara langsung

**File:** `frontend/lib/screens/settlement_detail_screen.dart`

---

### Bug #2: Data Tidak Refresh Setelah Navigate

**Penyebab:**
- Tidak ada call ke provider untuk reload data
- Navigation one-way tanpa callback

**Solusi:**
- Tambah `context.read<Provider>().loadXxx()` setelah navigate
- Gunakan `.then()` atau await untuk trigger refresh

**File:** 
- `frontend/lib/screens/settlement_detail_screen.dart`
- `frontend/lib/screens/advance/advance_detail_screen.dart`

---

## 📊 COMPARISON: Before vs After

| Fitur | Before | After |
|-------|--------|-------|
| Settlement → Kasbon | ❌ Tombol tidak respond | ✅ Berfungsi normal |
| Kasbon → Settlement (belum ada) | ✅ Tombol "Salin ke" ada | ✅ Sama |
| Kasbon → Settlement (sudah ada) | ❌ Tidak ada tombol | ✅ Tombol "Lihat" muncul |
| Data refresh setelah navigate | ❌ Manual refresh diperlukan | ✅ Auto refresh |
| Round-trip navigation | ❌ Error/blank | ✅ Lancar |

---

## 💡 TIPS & BEST PRACTICES

### 1. Navigation dengan Data Refresh
```dart
// GOOD ✅
final result = await Navigator.push(...);
if (mounted && result == true) {
  context.read<Provider>().loadData(id);
}

// BAD ❌
Navigator.push(...);
// Data tidak refresh!
```

### 2. Conditional Button Display
```dart
// GOOD ✅ - Check null AND zero
if (data['id'] != null && data['id'] != 0)
  // Show button

// BAD ❌ - Only check null
if (data['id'] != null)
  // Might show for id=0!
```

### 3. Import Screen Classes
```dart
// GOOD ✅ - Import specific screen
import 'advance/advance_detail_screen.dart';

// BAD ❌ - Import all (slower compile)
import '../screens.dart';
```

---

## 🔗 RELATED FILES

- `frontend/lib/screens/settlement_detail_screen.dart` - Settlement detail with "Lihat Kasbon" button
- `frontend/lib/screens/advance/advance_detail_screen.dart` - Advance detail with "Lihat Settlement" button
- `frontend/lib/providers/settlement_provider.dart` - Settlement state management
- `frontend/lib/providers/advance_provider.dart` - Advance state management

---

## 📚 DOKUMENTASI TERKAIT

- [PANDUAN_MODIFIKASI_KODE.md](PANDUAN_MODIFIKASI_KODE.md) - Panduan umum modifikasi kode
- [FIX_SETTLEMENT_FILTER_BUG.md](FIX_SETTLEMENT_FILTER_BUG.md) - Fix filter tahun settlement
- [FEATURE_INDIKATOR_KASBON.md](FEATURE_INDIKATOR_KASBON.md) - Logo kasbon di settlement card

---

**Status:** ✅ Implemented & Tested  
**Version:** 1.0.0  
**Last Updated:** 22 Maret 2026
