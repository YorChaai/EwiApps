"""
Background worker untuk mengecek deadline dan membuat notifikasi.
Dijalankan setiap jam 00:00 (tengah malam).
"""
from datetime import datetime, timezone, timedelta
from models import db, DeadlineSetting, Notification, Advance, Settlement, User


def check_and_create_deadline_notifications():
    """
    Fungsi utama untuk check deadline dan membuat notifikasi.
    Dipanggil setiap hari jam 00:00.
    """
    try:
        today = datetime.now(timezone.utc).date()
        
        # =========================================
        # 0. CLEANUP (Optimized Fallback)
        # =========================================
        # Hanya bersihkan notifikasi yang targetnya sudah tidak 'menggantung'
        # 1. Kasbon yang sudah punya settlement
        db.session.query(Notification).filter(
            Notification.action_type == 'deadline_warning',
            Notification.target_type == 'advance',
            Notification.target_id.in_(
                db.session.query(Advance.id).filter(Advance.settlement != None)
            )
        ).delete(synchronize_session=False)

        # 2. Settlement yang sudah approved/rejected
        db.session.query(Notification).filter(
            Notification.action_type == 'deadline_warning',
            Notification.target_type == 'settlement',
            Notification.target_id.in_(
                db.session.query(Settlement.id).filter(Settlement.status.in_(['approved', 'rejected']))
            )
        ).delete(synchronize_session=False)
        
        db.session.commit()

        # Ambil semua setting deadline yang aktif
        settings = DeadlineSetting.query.filter_by(is_active=True).all()
        if not settings:
            return
        
        settings_map = {s.rule_key: sorted(s.days) for s in settings}
        
        # =========================================
        # 1. CHECK SETTLEMENT_SUBMISSION DEADLINE
        # =========================================
        if 'SETTLEMENT_SUBMISSION' in settings_map:
            days_thresholds = settings_map['SETTLEMENT_SUBMISSION']
            
            approved_advances = Advance.query.filter(
                Advance.status == 'approved',
                Advance.settlement == None,
                Advance.approved_at != None
            ).all()
            
            for advance in approved_advances:
                days_passed = (today - advance.approved_at.date()).days
                
                # Check all thresholds that have been passed
                for threshold_day in days_thresholds:
                    if days_passed >= threshold_day:
                        # Check if this specific threshold has been notified
                        _create_deadline_notification_if_missing(
                            user_id=advance.user_id,
                            target_type='advance',
                            target_id=advance.id,
                            threshold_day=threshold_day,
                            message=f'Kasbon "{advance.title}" Anda sudah lewat {threshold_day} hari, mohon segera buat settlement!',
                            link_path=f'/advances/{advance.id}'
                        )
        
        # =========================================
        # 2. CHECK SETTLEMENT_APPROVAL DEADLINE
        # =========================================
        if 'SETTLEMENT_APPROVAL' in settings_map:
            days_thresholds = settings_map['SETTLEMENT_APPROVAL']
            
            submitted_settlements = Settlement.query.filter(
                Settlement.status == 'submitted'
            ).all()
            
            for settlement in submitted_settlements:
                # Use submitted_at (fixed) or fallback to updated_at if not set yet
                start_date = settlement.submitted_at or settlement.updated_at
                days_passed = (today - start_date.date()).days
                
                for threshold_day in days_thresholds:
                    if days_passed >= threshold_day:
                        managers = User.query.filter_by(role='manager').all()
                        creator_name = settlement.creator.full_name if settlement.creator else "Unknown"
                        
                        for manager in managers:
                            _create_deadline_notification_if_missing(
                                user_id=manager.id,
                                target_type='settlement',
                                target_id=settlement.id,
                                threshold_day=threshold_day,
                                message=f'Settlement "{settlement.title}" dari {creator_name} sudah menunggu selama {threshold_day} hari, mohon segera ditinjau!',
                                link_path=f'/settlements/{settlement.id}'
                            )
        
        db.session.commit()
        
    except Exception as e:
        db.session.rollback()
        print(f"[!] Error saat check deadline: {str(e)}")


def _create_deadline_notification_if_missing(user_id, target_type, target_id, threshold_day, message, link_path):
    """
    Membuat notifikasi deadline jika belum ada untuk threshold hari tertentu.
    Menggunakan extra_metadata untuk melacak threshold_day.
    """
    try:
        # Check if notification for THIS THRESHOLD already exists
        # We search in JSON extra_metadata using SQLite/Postgres compatible approach if possible,
        # but for simplicity and cross-db compatibility, we'll check it in Python or via simple filter
        existing = Notification.query.filter(
            Notification.user_id == user_id,
            Notification.action_type == 'deadline_warning',
            Notification.target_type == target_type,
            Notification.target_id == target_id
        ).all()
        
        # Filter manually to check threshold in JSON
        has_notified = any(
            n.extra_metadata and n.extra_metadata.get('threshold_day') == threshold_day 
            for n in existing
        )
        
        if has_notified:
            return

        notification = Notification(
            user_id=user_id,
            actor_id=None,
            action_type='deadline_warning',
            target_type=target_type,
            target_id=target_id,
            message=message,
            read_status=False,
            link_path=link_path,
            extra_metadata={'threshold_day': threshold_day}
        )
        db.session.add(notification)
        
    except Exception as e:
        print(f"[!] Error helper notifikasi: {str(e)}")


if __name__ == '__main__':
    # For testing purposes
    check_and_create_deadline_notifications()
