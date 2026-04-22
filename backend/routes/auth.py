import os
import uuid
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from models import db, User
from datetime import datetime, timezone
from routes.notifications import notify_managers, create_notification

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


def allowed_file(filename):
    allowed = current_app.config.get('ALLOWED_EXTENSIONS', {'png', 'jpg', 'jpeg', 'pdf'})
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed


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
    """Check if user is online based on recent activity window."""
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

        # Online jika masih ada aktivitas dalam 2 menit terakhir.
        # Heartbeat akan diperbarui oleh request JWT user yang memang masih aktif.
        return diff.total_seconds() < (2 * 60)

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
    phone_number = data.get('phone_number', '').strip() or '-'
    workplace = data.get('workplace', '').strip() or '-'
    role = data.get('role', 'staff')

    # Validasi input
    if not username or not password or not full_name:
        return jsonify({'error': 'Username, password, dan nama lengkap wajib diisi'}), 400

    if phone_number != '-' and not phone_number.isdigit():
        return jsonify({'error': 'Nomor HP harus berupa angka'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password minimal 6 karakter'}), 400

    # Cek username duplikat
    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username sudah dipakai, gunakan yang lain'}), 409

    # Validasi role (hanya staff atau mitra_eks untuk registrasi mandiri)
    if role not in ['staff', 'mitra_eks']:
        role = 'staff'

    # Buat user baru
    user = User(
        username=username,
        full_name=full_name,
        phone_number=phone_number,
        workplace=workplace,
        role=role
    )
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


@auth_bp.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User tidak ditemukan'}), 404

    # Handle both JSON and form data
    if request.is_json:
        data = request.get_json()
    else:
        data = request.form

    full_name = data.get('full_name', '').strip()
    phone_number = data.get('phone_number', '').strip()
    workplace = data.get('workplace', '').strip()
    old_password = data.get('old_password')
    new_password = data.get('new_password')
    remove_image = data.get('remove_profile_image') == 'true'

    if full_name:
        user.full_name = full_name

    if phone_number:
        if phone_number != '-' and not phone_number.isdigit():
            return jsonify({'error': 'Nomor HP harus berupa angka'}), 400
        user.phone_number = phone_number

    if workplace:
        user.workplace = workplace

    # Handle Profile Image Upload
    if 'profile_image' in request.files:
        file = request.files['profile_image']
        if file and file.filename and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            unique_name = f"profile_{user.id}_{uuid.uuid4().hex[:8]}.{ext}"

            upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'profiles')
            os.makedirs(upload_dir, exist_ok=True)

            # Delete old image if exists
            if user.profile_image:
                old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], user.profile_image)
                if os.path.exists(old_path):
                    try:
                        os.remove(old_path)
                    except:
                        pass

            file.save(os.path.join(upload_dir, unique_name))
            user.profile_image = f"profiles/{unique_name}"

    elif remove_image:
        if user.profile_image:
            old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], user.profile_image)
            if os.path.exists(old_path):
                try:
                    os.remove(old_path)
                except:
                    pass
            user.profile_image = None

    # Ganti Password logic
    if new_password:
        if not old_password:
            return jsonify({'error': 'Password lama wajib diisi untuk mengganti password'}), 400
        if not user.check_password(old_password):
            return jsonify({'error': 'Password lama salah'}), 401
        if len(new_password) < 6:
            return jsonify({'error': 'Password baru minimal 6 karakter'}), 400
        user.set_password(new_password)

    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Profil berhasil diperbarui',
        'user': user.to_dict()
    }), 200


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
            'phone_number': u.phone_number or '-',
            'workplace': u.workplace or '-',
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
    phone_number = data.get('phone_number', '').strip() or '-'
    workplace = data.get('workplace', '').strip() or '-'
    role = data.get('role', 'staff')

    if not username or not password or not full_name:
        return jsonify({'error': 'Semua field wajib diisi'}), 400

    if phone_number != '-' and not phone_number.isdigit():
        return jsonify({'error': 'Nomor HP harus berupa angka'}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({'error': 'Username sudah terdaftar'}), 409

    if role not in ['staff', 'manager', 'mitra_eks']:
        role = 'staff'

    user = User(
        username=username,
        full_name=full_name,
        phone_number=phone_number,
        workplace=workplace,
        role=role
    )
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    return jsonify({'user': user.to_dict()}), 201


@auth_bp.route('/users/<int:user_id>', methods=['PUT'])
@jwt_required()
def update_user_by_manager(user_id):
    current_user = User.query.get(int(get_jwt_identity()))
    if current_user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    user = User.query.get_or_404(user_id)
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Data tidak valid'}), 400

    full_name = data.get('full_name', '').strip()
    phone_number = data.get('phone_number', '').strip()
    workplace = data.get('workplace', '').strip()
    role = data.get('role')
    password = data.get('password')

    if full_name:
        user.full_name = full_name

    if phone_number:
        if phone_number != '-' and not phone_number.isdigit():
            return jsonify({'error': 'Nomor HP harus berupa angka'}), 400
        user.phone_number = phone_number

    if workplace:
        user.workplace = workplace

    if role and role in ['staff', 'manager', 'mitra_eks']:
        user.role = role

    if password:
        if len(password) < 6:
            return jsonify({'error': 'Password minimal 6 karakter'}), 400
        user.set_password(password)

    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Data user berhasil diperbarui oleh manager',
        'user': user.to_dict()
    }), 200
