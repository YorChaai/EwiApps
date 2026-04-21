from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from models import Notification, User, db
from datetime import datetime, timezone

notifications_bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')


@notifications_bp.route('', methods=['GET'])
@jwt_required()
def get_notifications():
    """
    Get notifications for the logged-in user.
    Role-based:
    - Manager: sees all notifications in the system
    - Staff & Mitra: sees only their own notifications (personal)
    Query params:
    - read_status: true/false/all (default: all)
    - limit: number of notifications (default: 50)
    - offset: pagination offset (default: 0)
    """
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)

    read_status = request.args.get('read_status', 'all').lower()
    limit = min(request.args.get('limit', 50, type=int), 100)
    offset = request.args.get('offset', 0, type=int)

    if user.role == 'manager':
        query = Notification.query
        unread_count = Notification.query.filter(
            Notification.read_status == False
        ).count()
    else:
        query = Notification.query.filter_by(user_id=user_id)
        unread_count = Notification.query.filter_by(user_id=user_id, read_status=False).count()

    if read_status == 'true':
        query = query.filter_by(read_status=True)
    elif read_status == 'false':
        query = query.filter_by(read_status=False)

    total = query.count()
    notifications = query.order_by(Notification.created_at.desc()).limit(limit).offset(offset).all()

    return jsonify({
        'success': True,
        'data': [notif.to_dict() for notif in notifications],
        'total': total,
        'unread_count': unread_count,
        'limit': limit,
        'offset': offset
    }), 200


def _can_access_notification(user, notification):
    """Manager: akses penuh ke semua notifikasi. Staff/Mitra: hanya milik sendiri."""
    if notification.user_id == user.id:
        return True
    if user.role == 'manager':
        return True
    return False


@notifications_bp.route('/<int:notification_id>/read', methods=['PUT'])
@jwt_required()
def mark_notification_as_read(notification_id):
    """Mark single notification as read"""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)

    notification = Notification.query.get(notification_id)
    if not notification or not _can_access_notification(user, notification):
        return jsonify({'success': False, 'message': 'Notification not found'}), 404

    notification.read_status = True
    db.session.commit()

    if user.role == 'manager':
        unread_count = Notification.query.filter(
            Notification.read_status == False
        ).count()
    else:
        unread_count = Notification.query.filter_by(user_id=user_id, read_status=False).count()

    return jsonify({
        'success': True,
        'message': 'Notification marked as read',
        'data': notification.to_dict(),
        'unread_count': unread_count
    }), 200


@notifications_bp.route('/mark-all-read', methods=['PUT'])
@jwt_required()
def mark_all_notifications_as_read():
    """Mark all notifications as read. Manager: semua notifikasi. Staff/Mitra: milik sendiri."""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)

    if user.role == 'manager':
        Notification.query.filter(
            Notification.read_status == False
        ).update({'read_status': True}, synchronize_session=False)
    else:
        Notification.query.filter_by(user_id=user_id, read_status=False).update({'read_status': True})
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'All notifications marked as read',
        'unread_count': 0
    }), 200


@notifications_bp.route('/<int:notification_id>', methods=['DELETE'])
@jwt_required()
def delete_notification(notification_id):
    """Delete a single notification"""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)

    notification = Notification.query.get(notification_id)
    if not notification or not _can_access_notification(user, notification):
        return jsonify({'success': False, 'message': 'Notification not found'}), 404

    db.session.delete(notification)
    db.session.commit()

    if user.role == 'manager':
        unread_count = Notification.query.filter(
            Notification.read_status == False
        ).count()
    else:
        unread_count = Notification.query.filter_by(user_id=user_id, read_status=False).count()

    return jsonify({
        'success': True,
        'message': 'Notification deleted',
        'unread_count': unread_count
    }), 200


@notifications_bp.route('/unread-count', methods=['GET'])
@jwt_required()
def get_unread_count():
    """Get unread notification count. Manager: semua notifikasi. Staff/Mitra: milik sendiri."""
    user_id = int(get_jwt_identity())
    user = User.query.get_or_404(user_id)

    if user.role == 'manager':
        unread_count = Notification.query.filter(
            Notification.read_status == False
        ).count()
    else:
        unread_count = Notification.query.filter_by(user_id=user_id, read_status=False).count()

    return jsonify({
        'success': True,
        'unread_count': unread_count
    }), 200


# Helper functions
def create_notification(user_id, actor_id, action_type, target_type, target_id, message, link_path):
    """Create a notification in the database"""
    try:
        notification = Notification(
            user_id=user_id,
            actor_id=actor_id,
            action_type=action_type,
            target_type=target_type,
            target_id=target_id,
            message=message,
            read_status=False,
            link_path=link_path
        )
        db.session.add(notification)
        db.session.commit()
        return notification
    except Exception as e:
        db.session.rollback()
        print(f"Error creating notification: {str(e)}")
        return None


def notify_managers(action_type, target_type, target_id, message, staff_id, link_path):
    """Notify all managers about an action"""
    managers = User.query.filter_by(role='manager').all()
    for manager in managers:
        create_notification(
            user_id=manager.id,
            actor_id=staff_id,
            action_type=action_type,
            target_type=target_type,
            target_id=target_id,
            message=message,
            link_path=link_path
        )


def notify_staff(user_id, action_type, target_type, target_id, message, actor_id, link_path):
    """Notify staff member about manager action"""
    create_notification(
        user_id=user_id,
        actor_id=actor_id,
        action_type=action_type,
        target_type=target_type,
        target_id=target_id,
        message=message,
        link_path=link_path
    )
