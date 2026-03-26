from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from models import db, User
from datetime import datetime, timezone
from routes.notifications import notify_managers, create_notification

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


def format_last_login(last_login):
    """Format last_login timestamp to human-readable string"""
    if last_login is None:
        return "-"

    try:
        # Parse ISO format timestamp
        if isinstance(last_login, str):
            last = datetime.fromisoformat(last_login.replace('Z', '+00:00'))
        else:
            last = last_login

        # Make timezone-aware if naive (SQLite stores naive datetimes)
        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)

        now = datetime.now(timezone.utc)
        diff = now - last
        total_seconds = int(diff.total_seconds())

        # < 24 jam → format relatif
        if total_seconds < 86400:  # 24 jam = 86400 detik
            if total_seconds < 60:  # < 1 menit
                return "Baru saja"
            elif total_seconds < 3600:  # < 1 jam
                minutes = total_seconds // 60
                return f"{minutes} menit yang lalu"
            else:  # < 24 jam
                hours = total_seconds // 3600
                return f"{hours} jam yang lalu"

        # > 24 jam → format tanggal
        months = {
            1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr',
            5: 'Mei', 6: 'Jun', 7: 'Jul', 8: 'Agt',
            9: 'Sep', 10: 'Okt', 11: 'Nov', 12: 'Des'
        }
        return f"{last.day} {months[last.month]}, {last.strftime('%H:%M')}"

    except Exception as e:
        print(f"Error formatting last_login: {e}")
        return "-"


def is_user_online(last_login):
    """Check if user is online (last login < 1 minute ago)"""
    if last_login is None:
        return False

    try:
        # Parse ISO format timestamp
        if isinstance(last_login, str):
            last = datetime.fromisoformat(last_login.replace('Z', '+00:00'))
        else:
            last = last_login

        # Make timezone-aware if naive
        if last.tzinfo is None:
            last = last.replace(tzinfo=timezone.utc)

        now = datetime.now(timezone.utc)
        diff = now - last

        # Online jika < 1 menit (60 detik)
        return diff.total_seconds() < 60

    except Exception as e:
        print(f"Error checking online status: {e}")
        return False


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')

    if not username or not password:
        return jsonify({'error': 'Username dan password harus diisi'}), 400

    user = User.query.filter_by(username=username).first()
    if not user or not user.check_password(password):
        return jsonify({'error': 'Username atau password salah'}), 401

    # Check if this is a return after long absence (>30 days)
    from routes.notifications import create_notification
    last_login = user.last_login
    notify_return = False
    days_since_last_login = 0

    if last_login:
        # Make last_login timezone-aware if it's naive
        if last_login.tzinfo is None:
            last_login = last_login.replace(tzinfo=timezone.utc)
        days_since_last_login = (datetime.now(timezone.utc) - last_login).days
        notify_return = days_since_last_login > 30

    # Update last_login
    user.last_login = datetime.now(timezone.utc)
    db.session.commit()

    # Notify managers if user returns after long absence
    if notify_return:
        managers = User.query.filter_by(role='manager').all()
        message = f"{user.full_name} login setelah {days_since_last_login} hari tidak aktif"
        for manager in managers:
            create_notification(
                user_id=manager.id,
                actor_id=user.id,
                action_type='return_login',
                target_type='user',
                target_id=user.id,
                message=message,
                link_path='/settings'
            )

    token = create_access_token(identity=str(user.id))
    return jsonify({
        'token': token,
        'user': user.to_dict()
    }), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')
    full_name = data.get('full_name', '').strip()
    role = data.get('role', 'staff')

    # Validasi input
    if not username or not password or not full_name:
        return jsonify({'error': 'Username, password, dan nama lengkap wajib diisi'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password minimal 6 karakter'}), 400

    # Cek username duplikat
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username sudah dipakai, gunakan yang lain'}), 409

    # Validasi role (hanya staff atau mitra_eks untuk registrasi mandiri)
    if role not in ['staff', 'mitra_eks']:
        role = 'staff'

    # Buat user baru
    user = User(username=username, full_name=full_name, role=role)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    # Notify managers about new user
    message = f"User baru terdaftar: {full_name} (@{username}) - Role: {role}"
    notify_managers('register', 'user', user.id, message, user.id, f'/settings')

    return jsonify({
        'message': 'Akun berhasil dibuat! Silakan login.',
        'user': user.to_dict()
    }), 201


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def me():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User tidak ditemukan'}), 404
    return jsonify({'user': user.to_dict()}), 200


@auth_bp.route('/users', methods=['GET'])
@jwt_required()
def list_users():
    current_user = User.query.get(int(get_jwt_identity()))
    if current_user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    users = User.query.all()
    result = []
    for u in users:
        user_data = {
            'id': u.id,
            'username': u.username,
            'full_name': u.full_name,
            'role': u.role,
            'last_login': u.last_login.isoformat() if u.last_login else None,
            'last_login_formatted': format_last_login(u.last_login),
            'is_online': is_user_online(u.last_login)
        }
        print(f"DEBUG User {u.username}: last_login={u.last_login}, formatted={user_data['last_login_formatted']}, online={user_data['is_online']}")
        result.append(user_data)

    return jsonify({'users': result}), 200


@auth_bp.route('/users', methods=['POST'])
@jwt_required()
def create_user():
    current_user = User.query.get(int(get_jwt_identity()))
    if current_user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    data = request.get_json()
    username = data.get('username', '').strip()
    password = data.get('password', '')
    full_name = data.get('full_name', '').strip()
    role = data.get('role', 'staff')

    if not username or not password or not full_name:
        return jsonify({'error': 'Semua field wajib diisi'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username sudah dipakai'}), 409

    user = User(username=username, full_name=full_name, role=role)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return jsonify({'user': user.to_dict()}), 201
