import os
import uuid
import json
from typing import Any
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Expense, Settlement, Category, User
from datetime import datetime

expenses_bp = Blueprint('expenses', __name__, url_prefix='/api/expenses')


def allowed_file(filename):
    allowed = current_app.config.get('ALLOWED_EXTENSIONS', {'png', 'jpg', 'jpeg', 'pdf'})
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed


def _parse_checklist_notes(notes_value):
    if not notes_value:
        return []
    raw = str(notes_value).strip()
    if not raw.startswith('['):
        return []
    try:
        parsed = json.loads(raw)
    except (ValueError, TypeError):
        return []
    if not isinstance(parsed, list):
        return []
    normalized = []
    for item in parsed:
        if isinstance(item, dict) and 'text' in item:
            normalized.append({
                'text': str(item.get('text', '')).strip(),
                'checked': bool(item.get('checked', False)),
            })
        elif isinstance(item, str):
            normalized.append({'text': item.strip(), 'checked': False})
    return [item for item in normalized if item['text']]


@expenses_bp.route('', methods=['POST'])
@jwt_required()
def create_expense():
    user_id = int(get_jwt_identity())

    settlement_id = request.form.get('settlement_id', type=int)
    # Support both category_id (legacy) and category_ids (list)
    category_id = request.form.get('category_id', type=int)
    category_ids_raw = request.form.get('category_ids')
    category_ids = []
    if category_ids_raw:
        try:
            category_ids = json.loads(category_ids_raw)
        except:
            pass
    if not category_ids and category_id:
        category_ids = [category_id]
 
    description = request.form.get('description', '').strip()
    amount = request.form.get('amount', type=float)
    date_str = request.form.get('date', '')
    source = request.form.get('source', '').strip() or None
    currency = request.form.get('currency', 'IDR').strip()
    currency_exchange = request.form.get('currency_exchange', type=float) or 1

    if not all([settlement_id, category_ids, description, amount, date_str]):
        return jsonify({'error': 'Semua field wajib diisi (termasuk sub-kategori)'}), 400

    # Validasi nominal minimal 100 (dalam ekuivalen Rupiah)
    idr_equivalent = amount * (currency_exchange if currency_exchange else 1)
    if idr_equivalent <= 100:
        return jsonify({'error': 'Nominal ekuivalen Rupiah harus lebih dari Rp 100'}), 400

    settlement = Settlement.query.get(settlement_id)
    if not settlement:
        return jsonify({'error': 'Settlement tidak ditemukan'}), 404
    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if settlement.status not in ('draft', 'rejected'):
        return jsonify({'error': 'Settlement sudah tidak bisa diedit'}), 400

    # single settlement hanya boleh 1 expense
    if settlement.settlement_type == 'single' and len(settlement.expenses) >= 1:
        return jsonify({'error': 'Settlement sendiri hanya boleh memiliki 1 expense'}), 400

    # Validasi kategori: semua harus di bawah parent yang sama
    categories = Category.query.filter(Category.id.in_(category_ids)).all()
    if len(categories) != len(category_ids):
        return jsonify({'error': 'Salah satu kategori tidak ditemukan'}), 404
 
    parent_ids = {c.parent_id for c in categories}
    if len(parent_ids) > 1:
        return jsonify({'error': 'Semua sub-kategori harus berada di bawah kategori utama yang sama'}), 400
    if None in parent_ids:
        # Jika salah satu kategori adalah parent, pastikan dia sendirian atau logic lain
        # Tapi biasanya user pilih sub-kategori (yang punya parent)
        pass
 
    # Gunakan ID pertama sebagai legacy category_id
    primary_category_id = category_ids[0]

    try:
        expense_date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Format tanggal: YYYY-MM-DD'}), 400

    evidence_path = None
    evidence_filename = None

    if 'evidence' in request.files:
        file = request.files['evidence']
        if file and file.filename and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            unique_name = f"{uuid.uuid4().hex}.{ext}"

            # buat subfolder tahun/bulan
            now = datetime.now()
            year_month = f"{now.year}/{now.month:02d}"
            upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'receipts', year_month)
            os.makedirs(upload_dir, exist_ok=True)

            file.save(os.path.join(upload_dir, unique_name))

            # simpan path relatif ke db
            evidence_path = f"receipts/{year_month}/{unique_name}"
            evidence_filename = file.filename

    expense = Expense(
        settlement_id=settlement_id,
        category_id=primary_category_id,
        description=description,
        amount=amount,
        date=expense_date,
        source=source,
        currency=currency,
        currency_exchange=currency_exchange,
        evidence_path=evidence_path,
        evidence_filename=evidence_filename,
        status='pending'
    )
    if categories:
        expense.subcategories = categories
    db.session.add(expense)
    db.session.commit()

    return jsonify({'expense': expense.to_dict()}), 201


@expenses_bp.route('/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    user_id = int(get_jwt_identity())
    expense = Expense.query.get_or_404(expense_id)
    settlement = expense.settlement

    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    # data handling: support both json and form-data
    data = request.get_json(silent=True) or request.form.to_dict()
    files = request.files

    # edit rules:
    # - draft: full edit
    # - submitted: view only
    # - rejected: checklist items only
    if settlement.status == 'submitted':
        return jsonify({'error': 'saat disubmit hanya bisa melihat, tidak bisa mengubah data'}), 400

    if settlement.status not in ('draft', 'rejected'):
        return jsonify({'error': 'settlement tidak dalam status yang dapat diedit'}), 400

    data_keys = set(data.keys())
    only_checklist = data_keys.issubset({'notes', 'status'}) and 'notes' in data_keys

    if settlement.status == 'rejected' and not only_checklist:
        # rejected status: only allow updates to 'notes' or 'status'
        if any(k in data_keys for k in ['category_id', 'description', 'amount', 'date', 'source', 'currency', 'currency_exchange']):
            return jsonify({'error': 'saat rejected hanya boleh mengubah checklist, tidak bisa mengubah data utama'}), 400

    if 'category_ids' in data or 'category_id' in data:
        cat_ids = data.get('category_ids')
        if not isinstance(cat_ids, list):
            # Coba parse jika string
            try:
                cat_ids = json.loads(cat_ids)
            except:
                cat_ids = [int(data['category_id'])] if 'category_id' in data else []
 
        if cat_ids:
            new_cats = Category.query.filter(Category.id.in_(cat_ids)).all()
            if len(new_cats) != len(cat_ids):
                return jsonify({'error': 'Salah satu kategori tidak ditemukan'}), 404
 
            # Validasi parent sama
            p_ids = {c.parent_id for c in new_cats}
            if len(p_ids) > 1:
                return jsonify({'error': 'Semua sub-kategori harus berada di bawah kategori utama yang sama'}), 400
 
            expense.category_id = cat_ids[0]
            expense.subcategories = new_cats
    if 'description' in data:
        expense.description = str(data['description']).strip()
    if 'amount' in data:
        expense.amount = float(data['amount'])
    if 'date' in data:
        try:
            expense.date = datetime.strptime(str(data['date']), '%Y-%m-%d').date()
        except (ValueError, TypeError):
            return jsonify({'error': 'format tanggal harus YYYY-MM-DD'}), 400
    if 'source' in data:
        expense.source = str(data['source']).strip() or None
    if 'currency' in data:
        expense.currency = str(data['currency']).strip().upper()
    if 'currency_exchange' in data:
        expense.currency_exchange = float(data['currency_exchange'] or 1)

    if 'evidence' in files:
        file = files['evidence']
        if file and file.filename and allowed_file(file.filename):
            # delete old file if exists
            if expense.evidence_path:
                old_path = os.path.join(current_app.config['UPLOAD_FOLDER'], expense.evidence_path)
                if os.path.exists(old_path):
                    os.remove(old_path)

            ext = file.filename.rsplit('.', 1)[1].lower()
            unique_name = f"{uuid.uuid4().hex}.{ext}"

            # create year/month subfolders
            now = datetime.now()
            year_month = f"{now.year}/{now.month:02d}"
            upload_dir = os.path.join(current_app.config['UPLOAD_FOLDER'], 'receipts', year_month)
            os.makedirs(upload_dir, exist_ok=True)

            file.save(os.path.join(upload_dir, unique_name))

            expense.evidence_path = f"receipts/{year_month}/{unique_name}"
            expense.evidence_filename = file.filename

    if 'notes' in data:
        expense.notes = data['notes']
    if 'status' in data:
        expense.status = data['status']

    db.session.commit()
    return jsonify({'expense': expense.to_dict()}), 200


@expenses_bp.route('/bulk-delete', methods=['POST'])
@jwt_required()
def bulk_delete_expenses():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    data = request.get_json() or {}
    expense_ids = data.get('expense_ids', [])

    if not expense_ids:
        return jsonify({'error': 'Daftar ID expense kosong'}), 400

    expenses = Expense.query.filter(Expense.id.in_(expense_ids)).all()
    count = 0

    for expense in expenses:
        settlement = expense.settlement
        # Ijin: Pemilik draft/rejected ATAU manager
        can_delete = False
        if user.role == 'manager':
            if settlement.status not in ('approved', 'completed'):
                can_delete = True
        else:
            if settlement.user_id == user_id and settlement.status in ('draft', 'rejected'):
                can_delete = True

        if can_delete:
            # hapus evidence file
            if expense.evidence_path:
                file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], expense.evidence_path)
                if os.path.exists(file_path):
                    os.remove(file_path)

            db.session.delete(expense)
            count += 1

    db.session.commit()
    return jsonify({'message': f'{count} expense berhasil dihapus'}), 200


@expenses_bp.route('/<int:expense_id>', methods=['DELETE'])
@jwt_required()
def delete_expense(expense_id):
    user_id = int(get_jwt_identity())
    expense = Expense.query.get_or_404(expense_id)
    settlement = expense.settlement

    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if settlement.status not in ('draft', 'rejected'):
        return jsonify({'error': 'Settlement sudah tidak bisa diedit'}), 400

    # hapus evidence file
    if expense.evidence_path:
        file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], expense.evidence_path)
        if os.path.exists(file_path):
            os.remove(file_path)

    db.session.delete(expense)
    db.session.commit()
    return jsonify({'message': 'Expense dihapus'}), 200


@expenses_bp.route('/<int:expense_id>/approve', methods=['POST'])
@jwt_required()
def approve_expense(expense_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    expense = Expense.query.get_or_404(expense_id)
    settlement = expense.settlement

    if settlement.status != 'submitted':
        return jsonify({'error': 'Settlement belum disubmit'}), 400

    # Cek apakah kategori sudah diapprove
    if expense.category.status == 'pending':
        return jsonify({
            'error': f'Kategori "{expense.category.name}" belum disetujui. Silakan approve kategori terlebih dahulu.',
            'category_id': expense.category_id,
            'reason': 'category_unapproved'
        }), 400

    # Cek parent jika ada
    if expense.category.parent and expense.category.parent.status == 'pending':
        return jsonify({
            'error': f'Induk kategori "{expense.category.parent.name}" belum disetujui. Silakan approve kategori induk terlebih dahulu.',
            'category_id': expense.category.parent_id,
            'reason': 'category_unapproved'
        }), 400

    expense.status = 'approved'
    expense.notes = 'Disetujui oleh manager.'
    db.session.commit()

    # Notify staff about expense approval
    from routes.notifications import notify_staff
    message = f"Expense disetujui: {expense.description}"
    notify_staff(settlement.user_id, 'approve_expense', 'expense', expense.id, message, user.id, f'/settlements/{settlement.id}')

    return jsonify({'expense': expense.to_dict()}), 200


def _merge_rejection_notes(old_notes_str, new_notes_str):
    """Gabungkan komentar reject baru ke checklist lama (append), jangan ganti."""
    import json as json_mod
    old_list: list[dict[str, Any]] = []

    # 1. Parse old notes
    if old_notes_str and str(old_notes_str).strip().startswith('['):
        try:
            parsed_old = json_mod.loads(str(old_notes_str))
            if isinstance(parsed_old, list):
                for item in parsed_old:
                    if isinstance(item, dict) and 'text' in item:
                        old_list.append({'text': str(item['text']), 'checked': bool(item.get('checked', False))})
                    elif isinstance(item, str):
                        old_list.append({'text': str(item), 'checked': False})
            else:
                old_list = [{'text': str(old_notes_str), 'checked': False}]
        except (ValueError, TypeError):
            old_list = [{'text': str(old_notes_str), 'checked': False}]
    elif old_notes_str:
        old_list = [{'text': str(old_notes_str).strip(), 'checked': False}]

    # 2. Parse new notes - check if it's already JSON
    if new_notes_str and str(new_notes_str).strip().startswith('['):
        try:
            new_list = json_mod.loads(str(new_notes_str))
            if isinstance(new_list, list):
                for item in new_list:
                    if isinstance(item, dict) and 'text' in item:
                        old_list.append({'text': str(item['text']), 'checked': bool(item.get('checked', False))})
                    elif isinstance(item, str):
                        old_list.append({'text': str(item), 'checked': False})
                return json_mod.dumps(old_list)
        except:
            pass

    # 3. Fallback: treat as plain text
    new_reasons = [line.strip() for line in str(new_notes_str).strip().split('\n') if line.strip()]
    for r in new_reasons:
        old_list.append({'text': str(r), 'checked': False})
    return json_mod.dumps(old_list)


@expenses_bp.route('/<int:expense_id>/reject', methods=['POST'])
@jwt_required()
def reject_expense(expense_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    expense = Expense.query.get_or_404(expense_id)
    settlement = expense.settlement

    if settlement.status != 'submitted':
        return jsonify({'error': 'Settlement belum disubmit'}), 400

    data = request.get_json() or {}
    notes = data.get('notes', '')

    if not notes:
        return jsonify({'error': 'Alasan penolakan wajib diisi'}), 400

    expense.status = 'rejected'
    expense.notes = _merge_rejection_notes(expense.notes or '', notes)
    # ✅ FIX: Jangan auto-draft parent settlement saat satu item ditolak.
    # Status parent tetap 'submitted' agar manager bisa lanjut review item lain.
    # Draft hanya bisa diubah secara manual oleh pemilik melalui tombol "Move to Draft".
    db.session.commit()

    # Notify staff about expense rejection
    from routes.notifications import notify_staff
    message = f"Expense ditolak: {expense.description}"
    notify_staff(settlement.user_id, 'reject_expense', 'expense', expense.id, message, user.id, f'/settlements/{settlement.id}')

    return jsonify({'expense': expense.to_dict()}), 200


@expenses_bp.route('/evidence/<path:filename>', methods=['GET'])
def serve_evidence(filename):
    upload_dir = current_app.config['UPLOAD_FOLDER']
    return send_from_directory(upload_dir, filename)


@expenses_bp.route('/categories', methods=['GET'])
@jwt_required()
def list_categories():
    # Allow all statuses for selection, ordered by manual sort_order
    categories = Category.query.filter_by(parent_id=None).order_by(Category.sort_order).all()
    return jsonify({
        'categories': [c.to_dict(include_children=True) for c in categories]
    }), 200
