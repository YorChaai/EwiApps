import os
import uuid
import random
import string
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from flask_mail import Mail, Message
from models import db, User
from datetime import datetime, timezone, timedelta
from routes.notifications import notify_managers, create_notification
from google.oauth2 import id_token
from google.auth.transport import requests

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')
mail = Mail()

def init_mail(app):
    mail.init_app(app)

def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email', '').strip()

    if not email:
        return jsonify({'error': 'Email wajib diisi'}), 400

    user = User.query.filter_by(email=email).first()
    if not user:
        # Untuk keamanan, jangan beri tahu jika email tidak ada
        return jsonify({'message': 'Jika email terdaftar, kode OTP akan dikirim.'}), 200

    otp = generate_otp()
    user.reset_token = otp
    user.reset_token_expiry = datetime.now(timezone.utc) + timedelta(minutes=10)
    db.session.commit()

    try:
        from flask import current_app
        if not current_app.config.get('MAIL_USERNAME'):
            # Jika belum diatur di .env, bypass email dan print di terminal
            print(f"\n[DEBUG OTP] Kode OTP untuk {email} adalah: {otp}\n")
            return jsonify({'message': 'Mode Testing: Cek console backend untuk kode OTP.'}), 200

        msg = Message(
            'Kode Reset Password ExspanApp',
            recipients=[email]
        )
        msg.body = f"Halo {user.full_name},\n\nKode OTP Anda untuk reset password adalah: {otp}\n\nKode ini akan kadaluarsa dalam 10 menit. Jika Anda tidak merasa meminta reset password, abaikan email ini."
        mail.send(msg)
        return jsonify({'message': 'Kode OTP telah dikirim ke email Anda.'}), 200
    except Exception as e:
        print(f"Error sending email: {e}")
        print(f"\n[FALLBACK OTP] Karena email gagal, kode OTP untuk {email} adalah: {otp}\n")
        return jsonify({'message': 'Email gagal dikirim, tapi OTP dicetak di terminal server.'}), 200

@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email', '').strip()
    otp = data.get('otp', '').strip()
    new_password = data.get('new_password', '')

    if not email or not otp or not new_password:
        return jsonify({'error': 'Semua field wajib diisi'}), 400

    user = User.query.filter_by(email=email, reset_token=otp).first()

    if not user or not user.reset_token_expiry:
        return jsonify({'error': 'Kode OTP salah atau tidak valid'}), 400

    # Check expiry
    expiry = user.reset_token_expiry
    if expiry.tzinfo is None:
        expiry = expiry.replace(tzinfo=timezone.utc)

    if datetime.now(timezone.utc) > expiry:
        return jsonify({'error': 'Kode OTP telah kadaluarsa'}), 400

    if len(new_password) < 6:
        return jsonify({'error': 'Password minimal 6 karakter'}), 400

    user.set_password(new_password)
    user.reset_token = None
    user.reset_token_expiry = None
    db.session.commit()

    return jsonify({'message': 'Password berhasil diganti. Silakan login kembali.'}), 200

@auth_bp.route('/google-login', methods=['POST'])
def google_login():
    data = request.get_json()
    id_token_str = data.get('id_token')

    if not id_token_str:
        return jsonify({'error': 'ID Token Google tidak ditemukan'}), 400

    try:
        # Verify the ID token
        client_id = current_app.config.get('GOOGLE_CLIENT_ID')
        id_info = id_token.verify_oauth2_token(id_token_str, requests.Request(), client_id)

        email = id_info.get('email')
        google_id = id_info.get('sub')
        full_name = id_info.get('name')

        # Check if user exists by google_id or email
        user = User.query.filter((User.google_id == google_id) | (User.email == email)).first()

        if not user:
            # User not found, return info to Flutter to complete registration
            return jsonify({
                'new_user': True,
                'email': email,
                'google_id': google_id,
                'full_name': full_name,
                'message': 'Email belum terdaftar. Silakan lengkapi profil.'
            }), 200

        # User found, update info if needed
        if not user.google_id:
            user.google_id = google_id
        if not user.email:
            user.email = email

        user.last_login = datetime.now(timezone.utc)
        db.session.commit()

        token = create_access_token(identity=str(user.id))
        return jsonify({
            'token': token,
            'user': user.to_dict()
        }), 200

    except ValueError:
        return jsonify({'error': 'Verifikasi token Google gagal'}), 401
    except Exception as e:
        print(f"Google login error: {e}")
        return jsonify({'error': str(e)}), 500

def allowed_file(filename):
    allowed = current_app.config.get('ALLOWED_EXTENSIONS', {'png', 'jpg', 'jpeg', 'pdf'})
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed

@auth_bp.route('/login', methods=['POST'])
def login():
    # Gunakan limiter dari current_app untuk membatasi login (maks 5 kali/menit)
    # Ini adalah proteksi utama terhadap peretasan Brute Force
    if hasattr(current_app, 'limiter'):
        @current_app.limiter.limit("5 per minute")
        def _guarded_login():
            return _internal_login()
        return _guarded_login()
    return _internal_login()

def _internal_login():
    data = request.get_json()
    identifier = data.get('username', '').strip() # Bisa username atau email
    password = data.get('password', '')

    if not identifier or not password:
        return jsonify({'error': 'Username/Email dan password harus diisi'}), 400

    # Cari berdasarkan username ATAU email
    user = User.query.filter((User.username == identifier) | (User.email == identifier)).first()

    if not user or not user.check_password(password):
        return jsonify({'error': 'Username/Email atau password salah'}), 401

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
    email = data.get('email', '').strip().lower() or None
    password = data.get('password', '')
    full_name = data.get('full_name', '').strip()
    google_id = data.get('google_id', '').strip() or None
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

    if email and User.query.filter_by(email=email).first():
        return jsonify({'error': 'Email sudah dipakai, gunakan email lain'}), 409

    if google_id and User.query.filter_by(google_id=google_id).first():
        return jsonify({'error': 'Akun Google ini sudah terhubung ke user lain'}), 409

    # Validasi role (hanya staff atau mitra_eks untuk registrasi mandiri)
    if role not in ['staff', 'mitra_eks']:
        role = 'staff'

    # Buat user baru
    user = User(
        username=username,
        email=email,
        full_name=full_name,
        google_id=google_id,
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
    return jsonify({'users': [u.to_dict() for u in users]}), 200


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


@auth_bp.route('/users/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user_detail(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify({'user': user.to_dict()}), 200

@auth_bp.route('/link-google', methods=['POST'])
@jwt_required()
def link_google():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User tidak ditemukan'}), 404

    data = request.get_json()
    id_token_str = data.get('id_token')

    if not id_token_str:
        return jsonify({'error': 'ID Token Google tidak ditemukan'}), 400

    try:
        client_id = current_app.config.get('GOOGLE_CLIENT_ID')
        id_info = id_token.verify_oauth2_token(id_token_str, requests.Request(), client_id)

        email = id_info.get('email')
        google_id = id_info.get('sub')

        # Cek apakah google_id atau email sudah dipakai user lain
        existing_user = User.query.filter(
            ((User.google_id == google_id) | (User.email == email)) & (User.id != user.id)
        ).first()

        if existing_user:
            return jsonify({'error': 'Akun Google ini sudah terhubung ke user lain'}), 409

        user.google_id = google_id
        if not user.email: # Jika belum punya email, set dari google
            user.email = email

        db.session.commit()

        return jsonify({
            'success': True,
            'message': f'Berhasil menghubungkan akun Google: {email}',
            'user': user.to_dict()
        }), 200

    except ValueError:
        return jsonify({'error': 'Verifikasi token Google gagal'}), 401
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/unlink-google', methods=['POST'])
@jwt_required()
def unlink_google():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User tidak ditemukan'}), 404

    # Hapus koneksi Google
    user.google_id = None
    db.session.commit()

    return jsonify({
        'success': True,
        'message': 'Berhasil memutuskan hubungan akun Google',
        'user': user.to_dict()
    }), 200

# Endpoint untuk membuka login Google di Browser (Windows)
@auth_bp.route('/google-login-browser')
def google_login_browser():
    # Ini akan mengarahkan ke halaman login Google
    # Untuk sementara kita buat halaman instruksi sederhana
    # karena integrasi OAuth2 lengkap butuh Client Secret dan Redirect URI yang valid
    return """
    <html>
        <body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
            <h2>Integrasi Google Browser</h2>
            <p>Fitur login via browser sedang disiapkan.</p>
            <p>Gunakan HP Android untuk menghubungkan akun Gmail untuk saat ini.</p>
        </body>
    </html>
    """
