# Dokumentasi Fitur Notifikasi Deadline

## Ringkasan
Fitur Notifikasi Deadline memungkinkan Manager untuk mengatur notifikasi otomatis yang dikirim kepada Staff dan Manager ketika dokumen (Kasbon/Settlement) melampaui threshold waktu tertentu.

## Komponen Implementasi

### 1. Backend
#### a. Database Model (`backend/models.py`)
- **Tabel: `deadline_settings`**
  - `id` (Integer, Primary Key)
  - `rule_key` (String, Unique) - Identitas aturan: `SETTLEMENT_SUBMISSION` atau `SETTLEMENT_APPROVAL`
  - `days` (JSON) - Array angka threshold hari. Contoh: `[2, 10, 20]`
  - `is_active` (Boolean) - Status aktif/nonaktif
  - `created_at`, `updated_at` (DateTime)

#### b. API Endpoint (`backend/routes/settings.py`)
- **GET** `/api/settings/deadline`
  - Mengambil semua deadline settings
  - Return: `{ "SETTLEMENT_SUBMISSION": {...}, "SETTLEMENT_APPROVAL": {...} }`

- **POST** `/api/settings/deadline`
  - Membuat setting deadline baru
  - Body: `{ "rule_key": "...", "days": [...], "is_active": true }`
  
- **PUT** `/api/settings/deadline`
  - Update setting deadline
  - Body: `{ "rule_key": "...", "days": [...], "is_active": ... }`

#### c. Background Worker (`backend/utils/deadline_worker.py`)
- **Function: `check_and_create_deadline_notifications()`**
  - Dijalankan setiap hari jam 00:00 (midnight)
  - Check semua Kasbon approved tanpa Settlement
  - Check semua Settlement submitted tanpa approval
  - Membuat notifikasi jika melampaui threshold

#### d. Inisialisasi (`backend/scripts/init_deadline_settings.py`)
- Script untuk setup default deadline settings saat pertama kali
- Default values:
  - `SETTLEMENT_SUBMISSION`: [2, 10, 20] hari
  - `SETTLEMENT_APPROVAL`: [2, 5, 10] hari

### 2. Frontend
#### a. Screen (`frontend/lib/screens/settings/deadline_manager_screen.dart`)
- **DeadlineManagerScreen** - UI untuk mengatur deadline
- Menampilkan 2 section:
  1. **Kasbon → Settlement Deadline**
  2. **Settlement → Approval Deadline**
- Input fields untuk setiap threshold
  - Tambah/Hapus hari baru
  - Save button untuk menyimpan perubahan

#### b. Integration (`frontend/lib/screens/settings/settings_screen.dart`)
- Tambah card "Pengaturan Deadline Notifikasi" di Manager Panel
- Button "Kelola Deadline Notifikasi" yang navigasi ke `DeadlineManagerScreen`

#### c. API Client (`frontend/lib/services/api_service.dart`)
- **getDeadlineSettings()** - GET settings
- **updateDeadlineSetting(ruleKey, days)** - PUT update settings

## Logika Bisnis

### Rule 1: Kasbon → Settlement (SETTLEMENT_SUBMISSION)
```
Trigger: Kasbon status = APPROVED dan belum ada Settlement terkait
Titik Awal: Tanggal kasbon disetujui (approved_at)
Threshold: Dinamis (Manager bisa set hari ke berapa notifikasi muncul)
Berhenti Ketika: Settlement sudah dibuat untuk kasbon tersebut
Penerima: Staff yang mengajukan kasbon
Notifikasi: "Kasbon 'X' Anda sudah disetujui selama Y hari, harap segera selesaikan settlement."
```

### Rule 2: Settlement → Approval (SETTLEMENT_APPROVAL)
```
Trigger: Settlement status = SUBMITTED dan belum di-APPROVE/REJECT
Titik Awal: Tanggal settlement dikirim (updated_at saat status = submitted)
Threshold: Dinamis (Manager bisa set hari ke berapa notifikasi muncul)
Berhenti Ketika: Settlement sudah di-APPROVE atau REJECT
Penerima: Semua Manager
Notifikasi: "Settlement 'X' dari 'Y' sudah menunggu approval selama Z hari, mohon segera ditinjau."
```

## Setup Awal (Initial Setup)

### 1. Database Migration
```bash
# Jalankan migration untuk membuat tabel deadline_settings
alembic upgrade head
```

### 2. Initialize Default Settings
```bash
# Di backend folder
python scripts/init_deadline_settings.py
```

Atau manual via API:
```bash
curl -X POST http://localhost:5000/api/settings/deadline \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "rule_key": "SETTLEMENT_SUBMISSION",
    "days": [2, 10, 20],
    "is_active": true
  }'
```

### 3. Setup Background Scheduler
Gunakan salah satu:

#### Opsi A: Celery (Recommended)
```python
# celery_tasks.py
from celery import Celery
from celery.schedules import crontab
from utils.deadline_worker import check_and_create_deadline_notifications

app = Celery('myapp')

app.conf.beat_schedule = {
    'check-deadline-notifications': {
        'task': 'tasks.check_deadline_notifications_task',
        'schedule': crontab(hour=0, minute=0),  # Jam 00:00 setiap hari
    },
}

@app.task
def check_deadline_notifications_task():
    check_and_create_deadline_notifications()
```

#### Opsi B: APScheduler (Lightweight)
```python
# app.py
from apscheduler.schedulers.background import BackgroundScheduler
from utils.deadline_worker import check_and_create_deadline_notifications

scheduler = BackgroundScheduler()
scheduler.add_job(
    func=check_and_create_deadline_notifications,
    trigger="cron",
    hour=0,
    minute=0,
    id='deadline_check'
)
scheduler.start()
```

#### Opsi C: Linux Cron
```bash
0 0 * * * cd /path/to/backend && python -c "from app import app; from utils.deadline_worker import check_and_create_deadline_notifications; app.app_context().push(); check_and_create_deadline_notifications()"
```

## Testing

### 1. Test API Endpoints

**GET Settings:**
```bash
curl http://localhost:5000/api/settings/deadline \
  -H "Authorization: Bearer <TOKEN>"
```

**Response:**
```json
{
  "SETTLEMENT_SUBMISSION": {
    "id": 1,
    "rule_key": "SETTLEMENT_SUBMISSION",
    "days": [2, 10, 20],
    "is_active": true,
    "created_at": "...",
    "updated_at": "..."
  },
  "SETTLEMENT_APPROVAL": {
    "id": 2,
    "rule_key": "SETTLEMENT_APPROVAL",
    "days": [2, 5, 10],
    "is_active": true,
    "created_at": "...",
    "updated_at": "..."
  }
}
```

**UPDATE Settings:**
```bash
curl -X PUT http://localhost:5000/api/settings/deadline \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "rule_key": "SETTLEMENT_SUBMISSION",
    "days": [1, 5, 7]
  }'
```

### 2. Test Worker Manual

```bash
# Di backend folder
python -c "
from app import app
from utils.deadline_worker import check_and_create_deadline_notifications
with app.app_context():
    check_and_create_deadline_notifications()
"
```

### 3. Test Manual di Database

```sql
-- Ubah tanggal kasbon yang sudah approved
UPDATE advances 
SET approved_at = '2024-04-20 00:00:00+00:00'  -- 7 hari lalu
WHERE id = 1 AND status = 'approved';

-- Run worker
-- Harusnya notifikasi muncul jika ada threshold yang match (misal: 7 hari)
```

### 4. UI Testing (Flutter)
1. Login sebagai Manager
2. Ke Settings > Manager Panel > "Kelola Deadline Notifikasi"
3. Edit hari untuk setiap rule
4. Klik "Simpan"
5. Verifikasi perubahan di API atau database

## Notes
- Notifikasi dibuat di tabel `notifications` dengan `action_type='deadline_warning'`
- Notifikasi akan muncul di bell icon (notification bell) yang sudah ada
- Duplikat notifikasi dihindari dengan check same-day notification
- System berjalan otomatis tanpa intervensi manual (setelah setup)

## Troubleshooting
- Jika notifikasi tidak muncul: Check apakah background scheduler sudah berjalan
- Jika error di API: Check database connection dan migration status
- Jika Flutter error: Pastikan import `deadline_manager_screen.dart` sudah benar
