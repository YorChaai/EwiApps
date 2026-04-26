# 📋 PLAN IMPLEMENTASI - LOGIN, REGISTRASI & ACCOUNT MANAGEMENT

## 🎯 OVERVIEW

| Fitur | Deskripsi |
|-------|-----------|
| **Register** | User bisa daftar akun baru dari login page |
| **Login** | Update untuk tracking last_login |
| **Settings** | Semua role bisa akses, Manager punya menu khusus |
| **Account List** | Manager bisa lihat & manage user (Staff/Mitra) |

---

## 🔧 BACKEND (Python Flask)

### 1. Update User Model (`models.py`)
```
File: backend/models.py
```
- [ ] Tambah kolom `last_login` (DateTime, nullable)
- [ ] Update method `to_dict()` untuk include `last_login`

### 2. Register Endpoint (`routes/auth.py`)
```
POST /api/auth/register
Body: { username, password, full_name, role }
Response: { user, message }
```
- [ ] Validasi input (username tidak kosong, password min 6 char)
- [ ] Cek username tidak duplikat
- [ ] Hash password
- [ ] Simpan user baru ke database
- [ ] Return user data + success message

### 3. Update Login Endpoint (`routes/auth.py`)
```
POST /api/auth/login
```
- [ ] Update `last_login` timestamp saat login berhasil

### 4. Get Users Endpoint (`routes/auth.py`)
```
GET /api/auth/users
Header: JWT Token
Role: Manager only
Response: { users: [...] }
```
- [ ] Check role = manager
- [ ] Return list semua user dengan info last_login

---

## 📱 FRONTEND (Flutter)

### 5. Buat Register Screen (`screens/register_screen.dart`)
```
UI Components:
- TextField: Username
- TextField: Full Name
- TextField: Password
- TextField: Confirm Password
- Dropdown: Role (Staff / Mitra)
- Button: Register
- Button: Back to Login
```
- [ ] Form validation (password match, required fields)
- [ ] Show loading state
- [ ] Show error message jika register gagal
- [ ] Show success popup → navigate ke Login

### 6. Update Login Screen (`screens/login_screen.dart`)
```
Add:
- Button/Text: "Belum punya akun? Daftar"
- Navigate to Register Screen on tap
```

### 7. Update Settings Screen (`screens/settings_screen.dart`)
```
Settings Page - SEMUA ROLE BISA AKSES:
- Profile info
- Tema Aplikasi (Theme)
- Ubah password

Manager Only Button (AppBar - kanan atas, hanya untuk Manager):
- Default Tahun Laporan
- Penyimpanan File Lampiran
- Manage user (Account List, edit role, dll)
```

### 8. Buat Account List Dialog (`widgets/account_list_dialog.dart`)
```
UI Components:
- DataTable (Desktop) / Card List (Mobile)
- Columns: Username, Full Name, Role, Last Login, Status
- Responsive layout
```
- [ ] Fetch users dari API
- [ ] Display dalam table (desktop) atau card (mobile)
- [ ] Show last_login timestamp
- [ ] Show status indicator (Online jika last_login < 5 menit)

### 9. Update AuthProvider (`providers/auth_provider.dart`)
```
Add methods:
- Future<bool> register(username, password, full_name, role)
- Future<List<User>> getUsers()
```

---

## 📊 DATA FLOW

```
┌─────────────────────────────────────────────────────────────┐
│                    REGISTER FLOW                            │
├─────────────────────────────────────────────────────────────┤
│  Login Screen → Tap "Daftar" → Register Screen             │
│  → Input form → Validate → POST /api/auth/register         │
│  → Success → Show popup → Navigate to Login                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     LOGIN FLOW                              │
├─────────────────────────────────────────────────────────────┤
│  Input credentials → POST /api/auth/login                  │
│  → Update last_login → Return token + user data            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  MANAGER PANEL FLOW                         │
├─────────────────────────────────────────────────────────────┤
│  Settings → Tap "Manager Panel" → GET /api/auth/users      │
│  → Show Account List (table/card) → Display user info      │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 UI/UX SPEC

### Settings Page Structure
```
┌─────────────────────────────────────────────────────────────┐
│  Settings                              [Manager Only ▼]    │ ← Hanya Manager
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Profile Info                                        │   │
│  │  - Username                                          │   │
│  │  - Full Name                                         │   │
│  │  - Role                                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Tema Aplikasi                                       │   │
│  │  Light | Dark | System                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Ubah Password                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ────────────────────────────────────────────────────────  │
│  MANAGER ONLY SECTION (Click button di atas)               │
│  ────────────────────────────────────────────────────────  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Default Tahun Laporan                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Penyimpanan File Lampiran                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Manage User (Account List)                          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Register Screen
- **Layout**: Portrait & Landscape support
- **Validation**: Real-time error message
- **Success**: Dialog popup dengan tombol OK

### Account List
- **Desktop**: DataTable dengan columns
- **Mobile**: Card list dengan detail per user
- **Status indicator**: Green dot untuk online (< 5 menit)

---

## 🔒 SECURITY

| Check | Implementation |
|-------|----------------|
| Password hashing | Werkzeug generate_password_hash |
| Role check | Backend middleware untuk Manager-only endpoints |
| JWT Token | Required untuk semua authenticated requests |

---

## ✅ ACCEPTANCE CRITERIA

1. [ ] User bisa register dari login page
2. [ ] Register form validasi password match
3. [ ] Success popup muncul setelah register
4. [ ] Redirect otomatis ke login setelah OK
5. [ ] Last login terupdate saat user login
6. [ ] Manager bisa lihat Account List
7. [ ] Staff/Mitra tidak bisa akses Manager Panel
8. [ ] UI responsive di HP dan Laptop
9. [ ] Settings page bisa diakses semua role
10. [ ] Manager Only button hanya muncul untuk Manager

---

## 📁 FILE YANG DIUBAH/DIBUAT

### Backend
| File | Action | Deskripsi |
|------|--------|-----------|
| `backend/models.py` | Edit | Tambah field `last_login` |
| `backend/routes/auth.py` | Edit | Tambah endpoint register, update login, get users |

### Frontend
| File | Action | Deskripsi |
|------|--------|-----------|
| `frontend/lib/screens/register_screen.dart` | Baru | Halaman registrasi |
| `frontend/lib/screens/login_screen.dart` | Edit | Tambah button Register |
| `frontend/lib/screens/settings_screen.dart` | Edit | Tambah Manager Only section |
| `frontend/lib/widgets/account_list_dialog.dart` | Baru | Dialog list akun |
| `frontend/lib/providers/auth_provider.dart` | Edit | Tambah method register & getUsers |

---

**Status**: Siap implementasi


3. **Kapan Notifikasi Muncul?**

**A. Real-time (WebSocket/Polling)**
- ✅ Notifikasi muncul langsung saat event terjadi
- ⚠️ Butuh backend support WebSocket atau polling
- ⚠️ Lebih kompleks implementasi

**B. On-Demand (Saat Buka App)**
- ✅ Notifikasi di-load saat user buka app / refresh
- ✅ Lebih simple, tidak butuh WebSocket
- ⚠️ User harus buka app dulu untuk lihat notifikasi

**C. Push Notification**
- ✅ Notifikasi muncul walau app tertutup
- ⚠️ Butuh Firebase Cloud Messaging (FCM)
- ⚠️ Paling kompleks, butuh setup server tambahan

**Mau yang mana?** (Rekomendasi saya: **On-Demand** dulu untuk MVP)
