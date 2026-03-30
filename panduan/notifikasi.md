Comprehensive Notification Analysis - MiniProjectKPI_EWI

### 1. NOTIFICATION MODEL (Database Schema)

**File:** `D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\models.py` (lines 579-610)

```python
class Notification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    actor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    action_type = db.Column(db.String(50), nullable=False)  # submit, approve, reject, create
    target_type = db.Column(db.String(50), nullable=False)  # settlement, advance, category
    target_id = db.Column(db.Integer, nullable=False)
    message = db.Column(db.Text, nullable=False)
    read_status = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    link_path = db.Column(db.String(200), nullable=True)  # Deep-link path
```

---

### 2. NOTIFICATION MANAGER/HANDLER

**File:** `D:\2. Organize\1. Projects\MiniProjectKPI_EWI\backend\routes\notifications.py`

**Key Functions:**

| Function | Purpose |
|----------|---------|
| `create_notification()` | Creates a notification in the database |
| `notify_managers()` | Sends notification to ALL managers (for important cross-user events) |
| `notify_staff()` | Sends notification to a specific staff member |
| `_can_access_notification()` | Access control: Manager=full access, Staff/Mitra=own only |

**API Endpoints:**
- `GET /api/notifications` - List notifications (role-based filtering)
- `PUT /api/notifications/<id>/read` - Mark as read
- `PUT /api/notifications/mark-all-read` - Mark all as read
- `DELETE /api/notifications/<id>` - Delete notification
- `GET /api/notifications/unread-count` - Get unread count

---

### 3. ROLE-BASED NOTIFICATION ACCESS

| Role | Can See | Can Mark Read |
|------|---------|---------------|
| **Manager** | ALL notifications in the system | ALL notifications |
| **Staff** | Only their own notifications (`user_id`) | Only their own |
| **Mitra** | Only their own notifications (`user_id`) | Only their own |

---

### 4. COMPLETE LIST OF NOTIFICATION TYPES BY ROLE

#### **NOTIFICATIONS RECEIVED BY MANAGERS** (via `notify_managers()`)

| # | Action Type | Target Type | Trigger Event | Source File |
|---|-------------|-------------|---------------|-------------|
| 1 | `submit` | `settlement` | Staff submits settlement | `settlements.py:356` |
| 2 | `submit` | `advance` | Staff submits kasbon (advance) | `advances.py:528` |
| 3 | `start_revision` | `advance` | Staff starts revision on kasbon | `advances.py:286` |
| 4 | `create` | `category` | Staff creates new category | `categories.py:150` |
| 5 | `register` | `user` | New user registers | `auth.py:165` |

**Message Examples for Managers:**
- `"{user.full_name} melakukan submit settlement: {settlement.title}"`
- `"{user.full_name} melakukan submit kasbon: {advance.title}"`
- `"{advance.requester.full_name} memulai revisi kasbon: {advance.title} (Revisi #{advance.active_revision_no})"`
- `"{user.full_name} membuat kategori baru: {name}"`
- `"User baru terdaftar: {full_name} (@{username}) - Role: {role}"`

---

#### **NOTIFICATIONS RECEIVED BY STAFF/MITRA** (via `notify_staff()`)

| # | Action Type | Target Type | Trigger Event | Source File |
|---|-------------|-------------|---------------|-------------|
| 1 | `submit_confirmation` | `settlement` | Confirmation when staff submits their own settlement | `settlements.py:359` |
| 2 | `approve` | `settlement` | Manager approves settlement | `settlements.py:390` |
| 3 | `reject` | `settlement` | Manager rejects settlement | `settlements.py:496` |
| 4 | `approve_expense` | `expense` | Manager approves individual expense | `expenses.py:304` |
| 5 | `reject_expense` | `expense` | Manager rejects individual expense | `expenses.py:379` |
| 6 | `submit_confirmation` | `advance` | Confirmation when staff submits their own kasbon | `advances.py:531` |
| 7 | `approve` | `advance` | Manager approves kasbon | `advances.py:591` |
| 8 | `reject` | `advance` | Manager rejects kasbon | `advances.py:633` |
| 9 | `approve_item` | `advance_item` | Manager approves individual kasbon item | `advances.py:712` |
| 10 | `reject_item` | `advance_item` | Manager rejects individual kasbon item | `advances.py:788` |
| 11 | `approve` | `category` | Manager approves category | `categories.py:237` |
| 12 | `reject` | `category` | Manager rejects category | `categories.py:240` |

**Message Examples for Staff/Mitra:**
- `"Settlement \"{settlement.title}\" Anda telah disubmit"`
- `"Settlement Anda telah disetujui: {settlement.title}"`
- `"Kasbon \"{advance.title}\" Anda telah disubmit"`
- `"Kasbon Anda telah disetujui: {advance.title}"`
- `"Expense disetujui: {expense.description}"`
- `"Expense ditolak: {expense.description}"`
- `"Item kasbon disetujui: {item.description}"`
- `"Item kasbon ditolak: {item.description}"`
- `"Kategori '{cat.name}' Anda telah disetujui"`
- `"Kategori '{cat.name}' Anda telah ditolak"`

---

### 5. NOTIFICATION FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                    EVENT TRIGGERED                              │
│  (submit settlement, approve advance, reject expense, etc.)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              notify_managers() OR notify_staff()                │
│                                                                 │
│  notify_managers(): → All users with role='manager'            │
│  notify_staff():    → Specific user_id                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   create_notification()                         │
│  - user_id: recipient                                          │
│  - actor_id: who performed the action                          │
│  - action_type: submit/approve/reject/create/etc.              │
│  - target_type: settlement/advance/expense/category/user       │
│  - target_id: ID of the object                                 │
│  - message: Human-readable text                                │
│  - link_path: Deep-link for navigation (e.g., '/settlements/5')│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE (notifications table)               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              FRONTEND POLLING (30 second interval)              │
│  - GET /api/notifications (role-based filtering)               │
│  - Manager: sees ALL notifications                             │
│  - Staff/Mitra: sees only own notifications                    │
└─────────────────────────────────────────────────────────────────┘
```

---

### 6. ACTION TYPES SUMMARY

| Action Type | Description | Recipients |
|-------------|-------------|------------|
| `submit` | User submits settlement/advance | Managers |
| `submit_confirmation` | Confirmation to submitter | Staff/Mitra (self) |
| `approve` | Manager approves | Staff/Mitra |
| `reject` | Manager rejects | Staff/Mitra |
| `approve_expense` | Manager approves expense | Staff/Mitra |
| `reject_expense` | Manager rejects expense | Staff/Mitra |
| `approve_item` | Manager approves advance item | Staff/Mitra |
| `reject_item` | Manager rejects advance item | Staff/Mitra |
| `create` | User creates category | Managers |
| `start_revision` | User starts kasbon revision | Managers |
| `register` | New user registration | Managers |

---

### 7. TARGET TYPES SUMMARY

| Target Type | Objects |
|-------------|---------|
| `settlement` | Settlement realizations |
| `advance` | Kasbon (cash advance) |
| `advance_item` | Individual items in kasbon |
| `expense` | Individual expenses in settlement |
| `category` | Expense categories |
| `user` | User accounts |

---

### 8. KEY FILES SUMMARY

| File Path | Purpose |
|-----------|---------|
| `backend/models.py` | Notification model definition |
| `backend/routes/notifications.py` | Notification API endpoints + helper functions |
| `backend/routes/settlements.py` | Settlement-related notifications |
| `backend/routes/advances.py` | Advance/kasbon-related notifications |
| `backend/routes/expenses.py` | Expense approval/rejection notifications |
| `backend/routes/categories.py` | Category creation/approval notifications |
| `backend/routes/auth.py` | User registration notifications |

---

### 9. DOCUMENTATION FILES

| File | Content |
|------|---------|
| `panduan/Panduan_Backend_ewi.md` | Section 4.10 explains notification system |
| `panduan/PANDUAN_MODIFIKASI_KODE.md` | Section 10 explains how to add/modify notifications |
| `CATATAN_PROYEK_KPI_EWI.md` | Database schema and API routes |
| `DOKUMENTASI_UTAMA.md` | Main documentation with notification features

Berdasarkan analisis kode proyek Anda, berikut adalah **daftar lengkap notifikasi** untuk setiap role:

## 📋 Ringkasan Notifikasi per Role

### 👔 **MANAGER** - Menerima notifikasi ketika:

| No | Event | Contoh Pesan |
|----|-------|--------------|
| 1 | Staff submit **settlement** | "Budi melakukan submit settlement: Laporan Expense Maret" |
| 2 | Staff submit **kasbon (advance)** | "Siti melakukan submit kasbon: Kasbon Event Client" |
| 3 | Staff memulai **revisi kasbon** | "Budi memulai revisi kasbon: Kasbon Event Client (Revisi #2)" |
| 4 | Staff membuat **kategori baru** | "Siti membuat kategori baru: Transportasi Lokal" |
| 5 | **User baru terdaftar** | "User baru terdaftar: Ahmad Dani (@ahmad) - Role: staff" |

---

### 👤 **STAFF & MITRA** - Menerima notifikasi ketika:

| No | Event | Contoh Pesan |
|----|-------|--------------|
| 1 | **Submit settlement** sendiri (konfirmasi) | "Settlement 'Laporan Expense Maret' Anda telah disubmit" |
| 2 | Manager **approve settlement** | "Settlement Anda telah disetujui: Laporan Expense Maret" |
| 3 | Manager **reject settlement** | "Settlement Anda telah ditolak: Laporan Expense Maret" |
| 4 | Manager **approve expense** individual | "Expense disetujui: Tiket Kereta Jakarta-Bandung" |
| 5 | Manager **reject expense** individual | "Expense ditolak: Makan Siang Client" |
| 6 | **Submit kasbon** sendiri (konfirmasi) | "Kasbon 'Kasbon Event Client' Anda telah disubmit" |
| 7 | Manager **approve kasbon** | "Kasbon Anda telah disetujui: Kasbon Event Client" |
| 8 | Manager **reject kasbon** | "Kasbon Anda telah ditolak: Kasbon Event Client" |
| 9 | Manager **approve item kasbon** | "Item kasbon disetujui: Hotel Grand Asia Afrika" |
| 10 | Manager **reject item kasbon** | "Item kasbon ditolak: Sewa Sound System" |
| 11 | Manager **approve kategori** | "Kategori 'Transportasi Lokal' Anda telah disetujui" |
| 12 | Manager **reject kategori** | "Kategori 'Transportasi Lokal' Anda telah ditolak" |

---

## 🔍 Perbedaan Akses Notifikasi

| Role | Bisa Lihat | Bisa Tandai Read |
|------|-----------|------------------|
| **Manager** | SEMUA notifikasi di sistem | SEMUA notifikasi |
| **Staff** | Hanya notifikasi miliknya | Hanya miliknya |
| **Mitra** | Hanya notifikasi miliknya | Hanya miliknya |

---

## 📊 Tipe Notifikasi (action_type)

- `submit` - Pengajuan (settlement/kasbon)
- `submit_confirmation` - Konfirmasi submit
- `approve` - Persetujuan
- `reject` - Penolakan
- `approve_expense` / `reject_expense` - Persetujuan/penolakan expense
- `approve_item` / `reject_item` - Persetujuan/penolakan item kasbon
- `create` - Pembuatan (kategori)
- `start_revision` - Mulai revisi
- `register` - Pendaftaran user baru

Ada yang ingin Anda tambahkan atau ubah dari sistem notifikasi ini?