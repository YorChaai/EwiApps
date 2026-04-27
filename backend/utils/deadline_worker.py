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
        # 0. CLEANUP RESOLVED NOTIFICATIONS
        # =========================================
        # Delete deadline warnings for Advances that already have settlements
        resolved_advances = Advance.query.filter(Advance.settlement != None).all()
        for adv in resolved_advances:
            Notification.query.filter_by(
                target_type='advance',
                target_id=adv.id,
                action_type='deadline_warning'
            ).delete()
            
        # Delete deadline warnings for Settlements that are approved or rejected
        resolved_settlements = Settlement.query.filter(Settlement.status.in_(['approved', 'rejected'])).all()
        for sett in resolved_settlements:
            Notification.query.filter_by(
                target_type='settlement',
                target_id=sett.id,
                action_type='deadline_warning'
            ).delete()
        
        db.session.commit()
        print("[*] Cleanup notifikasi deadline selesai.")

        # Ambil semua setting deadline yang aktif
        settings = DeadlineSetting.query.filter_by(is_active=True).all()
        if not settings:
            print("[*] Tidak ada deadline setting yang aktif.")
            return
        
        settings_map = {s.rule_key: s.days for s in settings}
        
        # =========================================
        # 1. CHECK SETTLEMENT_SUBMISSION DEADLINE
        # =========================================
        if 'SETTLEMENT_SUBMISSION' in settings_map:
            days_thresholds = settings_map['SETTLEMENT_SUBMISSION']
            
            # Cari Kasbon yang sudah APPROVED tapi belum ada Settlement
            approved_advances = Advance.query.filter(
                Advance.status == 'approved',
                Advance.settlement == None,
                Advance.approved_at != None
            ).all()
            
            for advance in approved_advances:
                if not advance.approved_at:
                    continue
                
                # Calculate days passed since approval
                days_passed = (today - advance.approved_at.date()).days
                
                # Check if any threshold matches
                for threshold_day in days_thresholds:
                    if days_passed == threshold_day:
                        # Create notification for requester
                        _create_notification(
                            user_id=advance.user_id,
                            action_type='deadline_warning',
                            target_type='advance',
                            target_id=advance.id,
                            message=f'Kasbon "{advance.title}" Anda sudah lewat {threshold_day} hari, mohon segera buat settlement!',
                            link_path=f'/advances/{advance.id}'
                        )
                        print(f"[+] Notifikasi deadline dibuat untuk Kasbon {advance.id} (hari ke-{threshold_day})")
        
        # =========================================
        # 2. CHECK SETTLEMENT_APPROVAL DEADLINE
        # =========================================
        if 'SETTLEMENT_APPROVAL' in settings_map:
            days_thresholds = settings_map['SETTLEMENT_APPROVAL']
            
            # Cari Settlement yang statusnya SUBMITTED
            submitted_settlements = Settlement.query.filter(
                Settlement.status == 'submitted'
            ).all()
            
            for settlement in submitted_settlements:
                # Get the timestamp when it was submitted
                # Assuming updated_at tracks the last status change
                submission_date = settlement.updated_at.date() if settlement.updated_at else today
                
                days_passed = (today - submission_date).days
                
                # Check if any threshold matches
                for threshold_day in days_thresholds:
                    if days_passed == threshold_day:
                        # Create notifications for all managers
                        managers = User.query.filter_by(role='manager').all()
                        
                        creator_name = settlement.creator.full_name if settlement.creator else "Unknown"
                        for manager in managers:
                            _create_notification(
                                user_id=manager.id,
                                action_type='deadline_warning',
                                target_type='settlement',
                                target_id=settlement.id,
                                message=f'Settlement "{settlement.title}" dari {creator_name} sudah menunggu selama {threshold_day} hari, mohon segera ditinjau!',
                                link_path=f'/settlements/{settlement.id}'
                            )
                        
                        print(f"[+] Notifikasi deadline dibuat untuk Settlement {settlement.id} (hari ke-{threshold_day})")
        
        print("[*] Check deadline notifications selesai.")
        
    except Exception as e:
        print(f"[!] Error saat check deadline: {str(e)}")
        db.session.rollback()
        import traceback
        traceback.print_exc()


def _create_notification(user_id, action_type, target_type, target_id, message, link_path=None):
    """
    Helper function untuk membuat notifikasi.
    Cek dulu apakah notifikasi sudah ada hari ini (untuk menghindari duplikat).
    """
    try:
        today = datetime.now(timezone.utc).date()
        
        # Check if notification already exists for today
        existing = Notification.query.filter(
            Notification.user_id == user_id,
            Notification.action_type == action_type,
            Notification.target_type == target_type,
            Notification.target_id == target_id,
            db.func.date(Notification.created_at) == today
        ).first()
        
        if existing:
            print(f"[*] Notifikasi sudah ada untuk user {user_id}, target {target_id}")
            return
        
        notification = Notification(
            user_id=user_id,
            actor_id=None,  # System notification
            action_type=action_type,
            target_type=target_type,
            target_id=target_id,
            message=message,
            read_status=False,
            link_path=link_path
        )
        
        db.session.add(notification)
        db.session.commit()
        
    except Exception as e:
        print(f"[!] Error membuat notifikasi: {str(e)}")
        db.session.rollback()


if __name__ == '__main__':
    # For testing purposes
    check_and_create_deadline_notifications()
