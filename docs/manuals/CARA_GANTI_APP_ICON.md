# 🎨 CARA GANTI APP ICON - EXPSAN APP

**Status:** ✅ Ready to Execute  
**Last Updated:** 23 Maret 2026

---

## 📋 PERSYARATAN

### Logo Requirements:
- ✅ Format: **PNG**
- ✅ Size: **1024x1024 px** (recommended) atau minimal **512x512 px**
- ✅ Background: **Putih** atau **Transparan**
- ✅ Location: `frontend/assets/images/logo_exspan.png`

---

## 🚀 CARA 1: OTOMATIS (RECOMMENDED)

### Step 1: Double-Click Script

```
D:\2. Organize\1. Projects\MiniProjectKPI_EWI\frontend\change_icon.bat
```

Script akan otomatis:
1. ✅ Install package
2. ✅ Update pubspec.yaml
3. ✅ Generate icons
4. ✅ Build APK (optional)

### Step 2: Tunggu Proses Selesai

```
========================================
 Flutter App Icon Changer
 Logo: Exspan (White Background)
========================================

[1/4] Adding flutter_launcher_icons package...
[2/4] Updating pubspec.yaml...
[3/4] Getting dependencies...
[4/4] Generating launcher icons...

========================================
 SUCCESS! App icon changed to Exspan!
========================================
```

### Step 3: Rebuild APK

```bash
cd frontend
flutter build apk --release
```

**Done!** Icon aplikasi sudah berubah! 🎉

---

## 🚀 CARA 2: MANUAL

### Step 1: Install Package

```bash
cd frontend
flutter pub add flutter_launcher_icons
```

### Step 2: Verify pubspec.yaml

Sudah ada konfigurasi di `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo_exspan.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo_exspan.png"
  windows:
    generate: true
    image_path: "assets/images/logo_exspan.png"
```

### Step 3: Get Dependencies

```bash
flutter pub get
```

### Step 4: Generate Icons

```bash
flutter pub run flutter_launcher_icons
```

Output:
```
  ════════════════════════════════════════════
     FLUTTER LAUNCHER ICONS (v0.13.1)
  ════════════════════════════════════════════

• Creating default icons Android
• Overwriting the default Android launcher icon with a new icon
✓ Successfully generated launcher icons for Android
• Creating default icons iOS
• Overwriting default iOS launcher icon with new icon
✓ Successfully generated launcher icons for iOS
• Generating Windows launcher icons
✓ Successfully generated launcher icons for Windows
```

### Step 5: Rebuild APK

```bash
flutter build apk --release
```

---

## 📱 HASIL AKHIR

### Android Icon:
- ✅ **Foreground:** Logo Exspan
- ✅ **Background:** Putih (#FFFFFF)
- ✅ **Adaptive:** Support Android 8.0+
- ✅ **Locations:**
  - `android/app/src/main/res/mipmap-*/ic_launcher.png`

### iOS Icon:
- ✅ **Image:** Logo Exspan
- ✅ **Location:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Windows Icon:
- ✅ **Image:** Logo Exspan
- ✅ **Location:** `windows/runner/resources/app_icon.ico`

---

## 🖼️ ICON PREVIEW

### Android (Adaptive Icon):
```
┌─────────────────┐
│   ┌───────┐     │
│   │       │     │
│   │  LOGO │     │  ← Logo Exspan
│   │       │     │
│   └───────┘     │
│   White BG      │
└─────────────────┘
```

### All Platforms:
- **Android:** Adaptive icon dengan background putih
- **iOS:** Round icon dengan logo Exspan
- **Windows:** Square icon dengan logo Exspan

---

## 🔧 TROUBLESHOOTING

### Problem: Icon Tidak Berubah

**Cause:** Cache belum di-clear

**Solution:**
```bash
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons
flutter build apk --release
```

---

### Problem: Icon Pecah/Buram

**Cause:** Logo resolution terlalu rendah

**Solution:**
1. Gunakan logo **1024x1024 px**
2. Format **PNG** dengan kualitas tinggi
3. Update di `pubspec.yaml`

---

### Problem: Background Tidak Putih

**Cause:** adaptive_icon_background salah setting

**Solution:**
```yaml
flutter_launcher_icons:
  adaptive_icon_background: "#FFFFFF"  # White hex code
```

---

## 📊 ICON SPECIFICATIONS

### Android:
| Density | Size (px) | Location |
|---------|-----------|----------|
| mdpi | 48x48 | mipmap-mdpi/ |
| hdpi | 72x72 | mipmap-hdpi/ |
| xhdpi | 96x96 | mipmap-xhdpi/ |
| xxhdpi | 144x144 | mipmap-xxhdpi/ |
| xxxhdpi | 192x192 | mipmap-xxxhdpi/ |

### iOS:
| Size (pt) | Size (px) @2x | Size (px) @3x |
|-----------|---------------|---------------|
| 20pt | 40x40 | 60x60 |
| 29pt | 58x58 | 87x87 |
| 40pt | 80x80 | 120x120 |
| 60pt | 120x120 | 180x180 |
| 1024pt | - | 1024x1024 (App Store) |

### Windows:
| Size (px) | Usage |
|-----------|-------|
| 30x30 | Small tile |
| 44x44 | Medium tile |
| 50x50 | Large tile |
| 71x71 | Huge tile |
| 89x89 | Extra large |
| 107x107 | Extra extra large |
| 142x142 | Extra extra extra large |
| 213x213 | Extra extra extra extra large |

---

## ✅ VERIFICATION

### Check Android Icons:
```
frontend/android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
└── mipmap-xxxhdpi/ic_launcher.png (192x192)
```

### Check iOS Icons:
```
frontend/ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@2x.png
├── Icon-App-20x20@3x.png
├── Icon-App-29x29@2x.png
├── Icon-App-29x29@3x.png
├── Icon-App-40x40@2x.png
├── Icon-App-40x40@3x.png
├── Icon-App-60x60@2x.png
├── Icon-App-60x60@3x.png
└── Icon-App-1024x1024.png
```

### Check Windows Icons:
```
frontend/windows/runner/resources/
└── app_icon.ico
```

---

## 🎯 QUICK COMMAND REFERENCE

```bash
# Install package
flutter pub add flutter_launcher_icons

# Get dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons

# Clean build
flutter clean

# Build release APK
flutter build apk --release

# Run on device (release mode)
flutter run --release
```

---

## 📝 NOTES

1. **Backup** icon lama jika ingin revert
2. Test di **berbagai device** untuk ensure icon terlihat bagus
3. **Adaptive icon** hanya untuk Android 8.0+ (API 26+)
4. Untuk Android versi lama, akan pakai **legacy icon**
5. **Windows icon** hanya support di Flutter Windows desktop

---

## 🎨 DESIGN TIPS

### Untuk Logo dengan Background Putih:
- ✅ Pastikan logo **kontras** dengan background
- ✅ Logo harus **terlihat jelas** di size kecil (48x48)
- ✅ Test di **berbagai screen density**
- ✅ Hindari detail terlalu kecil

### Untuk Logo Transparan:
- ✅ Set `adaptive_icon_background: "#FFFFFF"`
- ✅ Pastikan logo **tidak ada elemen transparan**
- ✅ Export PNG dengan **transparency preserved**

---

## 📚 REFERENCES

- [Flutter Launcher Icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS App Icon](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Windows App Icons](https://learn.microsoft.com/en-us/windows/apps/design/style/app-icons-and-logos)

---

**Status:** ✅ Ready to Use  
**Difficulty:** ⭐ Easy (5 minutes)  
**Impact:** 🎨 High (Professional appearance)

🎉 **Happy Icon Changing!** 🚀
