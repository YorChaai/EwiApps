from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Category, User
from routes.notifications import notify_managers, notify_staff

categories_bp = Blueprint('categories', __name__, url_prefix='/api/categories')


@categories_bp.route('', methods=['GET'])
@jwt_required()
def list_categories():
    # list semua kategori (staff hanya approved, manager semua)
    user = User.query.get(int(get_jwt_identity()))

    # Staff can see pending categories they (or others) created to use them, but they still need manager approval for final settlement.
    if user.role == 'manager':
        cats = Category.query.filter_by(parent_id=None).all()
    else:
        # Allow staff to see pending categories so they can select them in expenses
        cats = Category.query.filter_by(parent_id=None).all()

    return jsonify({
        'categories': [c.to_dict(include_children=True) for c in cats]
    }), 200


@categories_bp.route('/pending', methods=['GET'])
@jwt_required()
def list_pending():
    # manager only: list pending kategori
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    pending = Category.query.filter_by(status='pending').all()
    return jsonify({
        'categories': [c.to_dict() for c in pending]
    }), 200


@categories_bp.route('', methods=['POST'])
@jwt_required()
def create_category():
    # buat kategori baru: staff -> pending, manager -> approved
    user = User.query.get(int(get_jwt_identity()))
    data = request.get_json()

    name = data.get('name', '').strip()
    parent_id = data.get('parent_id')

    if not name:
        return jsonify({'error': 'Nama kategori wajib diisi'}), 400

    # buat kode unik
    existing_codes = [c.code for c in Category.query.all()]
    if parent_id:
        parent = Category.query.get(parent_id)
        if not parent:
            return jsonify({'error': 'Parent kategori tidak ditemukan'}), 404
        # kode subkategori: parent_code + angka
        base = parent.code
        idx = 1
        while f"{base}{idx}" in existing_codes:
            idx += 1
        code = f"{base}{idx}"
    else:
        # kode top-level: huruf berikutnya
        import string
        for letter in string.ascii_uppercase:
            if letter not in existing_codes:
                code = letter
                break
        else:
            code = f"X{len(existing_codes)}"

    # All new categories start as 'pending' to follow the strict approval flow, even if created by manager
    status = 'pending'

    cat = Category(
        name=name,
        code=code,
        parent_id=parent_id,
        status=status,
        created_by=user.id
    )
    db.session.add(cat)
    db.session.flush()  # Get ID before commit

    # Auto-create "-" subcategory for top-level
    if not parent_id:
        sub_code = f"{code}0"
        sub_cat = Category(
            name="-",
            code=sub_code,
            parent_id=cat.id,
            status=status,
            created_by=user.id
        )
        db.session.add(sub_cat)

    db.session.commit()
    
    # Notify managers about new category creation
    message = f"{user.full_name} membuat kategori baru: {name}"
    notify_managers('create', 'category', cat.id, message, user.id, f'/categories')

    return jsonify({'category': cat.to_dict()}), 201


@categories_bp.route('/<int:cat_id>', methods=['PUT'])
@jwt_required()
def update_category(cat_id):
    # update kategori (manager only)
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    cat = Category.query.get_or_404(cat_id)
    data = request.get_json()

    if 'name' in data:
        cat.name = data['name'].strip()
    if 'parent_id' in data:
        cat.parent_id = data['parent_id']

    db.session.commit()
    return jsonify({'category': cat.to_dict()}), 200


@categories_bp.route('/<int:cat_id>', methods=['DELETE'])
@jwt_required()
def delete_category(cat_id):
    # hapus kategori (manager only, jika tidak ada relasi expense)
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    cat = Category.query.get_or_404(cat_id)

    # cek apakah kategori atau children punya expense
    if cat.expenses:
        return jsonify({'error': 'Kategori memiliki expense, tidak bisa dihapus'}), 400
    for child in cat.children:
        if child.expenses:
            return jsonify({'error': f'Sub-kategori "{child.name}" memiliki expense'}), 400

    # hapus children dulu
    for child in cat.children:
        db.session.delete(child)

    db.session.delete(cat)
    db.session.commit()
    return jsonify({'message': 'Kategori dihapus'}), 200


@categories_bp.route('/<int:cat_id>/approve', methods=['POST'])
@jwt_required()
def approve_category(cat_id):
    # manager approve kategori pending
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    cat = Category.query.get_or_404(cat_id)
    if cat.status != 'pending':
        return jsonify({'error': 'Kategori sudah diapprove'}), 400

    data = request.get_json(silent=True) or {}
    action = data.get('action', 'approve')

    try:
        if action == 'approve':
            cat.status = 'approved'
            # Auto-approve "-" subcategory if it exists
            for child in cat.children:
                if child.name == "-" and child.status == 'pending':
                    child.status = 'approved'
        elif action == 'reject':
            # Cascade delete children
            for child in cat.children:
                db.session.delete(child)
            db.session.delete(cat)
        else:
            return jsonify({'error': 'Action harus approve atau reject'}), 400

        db.session.commit()
        
        # Notify staff who created the category
        created_by_user = User.query.get(cat.created_by) if cat.created_by else None
        if created_by_user and action == 'approve':
            message = f"Kategori '{cat.name}' Anda telah disetujui"
            notify_staff(created_by_user.id, 'approve', 'category', cat.id, message, user.id, f'/categories')
        elif created_by_user and action == 'reject':
            message = f"Kategori '{cat.name}' Anda telah ditolak"
            notify_staff(created_by_user.id, 'reject', 'category', cat.id, message, user.id, f'/categories')
        
        return jsonify({
            'message': f'Kategori {action}d',
            'status': 'success'
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': f'Gagal memproses kategori: {str(e)}'}), 500
