"""
Script untuk menginisialisasi default deadline settings.
Jalankan ini sekali saat setup awal.
"""
from datetime import datetime, timezone
from app import app, db
from models import DeadlineSetting


def initialize_default_deadline_settings():
    """Initialize default deadline settings jika belum ada."""
    with app.app_context():
        # Check if already initialized
        existing = DeadlineSetting.query.first()
        if existing:
            print("[*] Deadline settings sudah ada. Skip initialization.")
            return
        
        # Create default settings
        settings = [
            DeadlineSetting(
                rule_key='SETTLEMENT_SUBMISSION',
                days=[2, 10, 20],
                is_active=True,
                created_at=datetime.now(timezone.utc),
                updated_at=datetime.now(timezone.utc)
            ),
            DeadlineSetting(
                rule_key='SETTLEMENT_APPROVAL',
                days=[2, 5, 10],
                is_active=True,
                created_at=datetime.now(timezone.utc),
                updated_at=datetime.now(timezone.utc)
            )
        ]
        
        try:
            db.session.add_all(settings)
            db.session.commit()
            print("[+] Default deadline settings berhasil dibuat.")
            print("    - SETTLEMENT_SUBMISSION: [2, 10, 20] hari")
            print("    - SETTLEMENT_APPROVAL: [2, 5, 10] hari")
        except Exception as e:
            db.session.rollback()
            print(f"[!] Error: {str(e)}")


if __name__ == '__main__':
    initialize_default_deadline_settings()
