from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from models import db, User

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


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

    token = create_access_token(identity=str(user.id))
    return jsonify({
        'token': token,
        'user': user.to_dict()
    }), 200


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
