import os
import uuid
import json
from typing import Any
from datetime import datetime, timezone

from flask import Blueprint, current_app, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import Advance, AdvanceItem, Category, Expense, Settlement, User, db
from routes.notifications import notify_managers, notify_staff

advances_bp = Blueprint('advances', __name__, url_prefix='/api/advances')


def allowed_file(filename):
    allowed = current_app.config.get(
        'ALLOWED_EXTENSIONS',
        {'png', 'jpg', 'jpeg', 'pdf'},
    )
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in allowed


def _advance_view_status_filter(query, status_filter):
    if not status_filter:
        return query
    if status_filter == 'completed':
        return query.filter_by(status='completed')
    return query.filter_by(status=status_filter)


def _editable_revision_no(advance):
    if advance.status in ('draft', 'rejected', 'pending', 'submitted'):
        return 0
    if advance.status in ('revision_draft', 'revision_rejected', 'revision_submitted'):
        return advance.active_revision_no
    return None


def _items_for_revision(advance, revision_no):
    return [
        item for item in advance.items
        if (item.revision_no or 0) == revision_no
    ]


def _settlement_blocks_revision(advance):
    settlement = advance.settlement
    return settlement and settlement.status in ('submitted', 'approved', 'completed')


def _sync_revision_items_to_settlement(advance, revision_no):
    settlement = advance.settlement
    if not settlement or settlement.status not in ('draft', 'rejected'):
        return

    existing_advance_item_ids = {
        expense.advance_item_id
        for expense in settlement.expenses
        if expense.advance_item_id is not None
    }
    today = datetime.now(timezone.utc).date()
    for item in _items_for_revision(advance, revision_no):
        if item.id in existing_advance_item_ids:
            continue
        db.session.add(
            Expense(
                settlement_id=settlement.id,
                category_id=item.category_id,
                description=item.description,
                amount=item.estimated_amount,
                date=today,
                source=f'Advance Revisi {revision_no}' if revision_no > 0 else 'Advance',
                advance_item_id=item.id,
                revision_no=revision_no,
                currency='IDR',
                currency_exchange=1,
                evidence_path=item.evidence_path,
                evidence_filename=item.evidence_filename,
                status='pending',
            )
        )


def _next_revision_no(advance):
    return (advance.approved_revision_no or 0) + 1


def _status_after_approval(advance):
    return 'in_settlement' if advance.settlement else 'approved'


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


def _has_unchecked_checklist(item):
    checklist = _parse_checklist_notes(item.notes)
    return bool(checklist) and any(not note['checked'] for note in checklist)


@advances_bp.route('', methods=['GET'])
@jwt_required()
def list_advances():
    user = User.query.get(int(get_jwt_identity()))
    status_filter = request.args.get('status')
    report_year = request.args.get('report_year', type=int)
    type_filter = request.args.get('type')

    query = Advance.query
    if user.role != 'manager':
        query = query.filter_by(user_id=user.id)

    query = _advance_view_status_filter(query, status_filter)
    if type_filter in ('single', 'batch'):
        query = query.filter_by(advance_type=type_filter)

    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    if start_date_str:
        try:
            start_date = datetime.strptime(
                start_date_str,
                '%Y-%m-%d',
            ).replace(tzinfo=timezone.utc)
            query = query.filter(Advance.created_at >= start_date)
        except ValueError:
            pass

    if end_date_str:
        try:
            end_date = datetime.strptime(
                end_date_str,
                '%Y-%m-%d',
            ).replace(hour=23, minute=59, second=59, tzinfo=timezone.utc)
            query = query.filter(Advance.created_at <= end_date)
        except ValueError:
            pass

    if report_year is not None:
        query = query.filter(db.extract('year', Advance.created_at) == report_year)

    search_query = request.args.get('search', '').strip()
    if search_query:
        like_pattern = f'%{search_query}%'
        query = query.filter(
            db.or_(
                Advance.title.ilike(like_pattern),
                Advance.description.ilike(like_pattern),
            )
        )

    advances = query.order_by(Advance.created_at.asc(), Advance.id.asc()).all()
    return jsonify({'advances': [a.to_dict() for a in advances]}), 200


@advances_bp.route('', methods=['POST'])
@jwt_required()
def create_advance():
    user_id = int(get_jwt_identity())
    # Support both JSON and Form data
    data = request.get_json(silent=True) or request.form.to_dict()

    title = data.get('title', '').strip()
    description = data.get('description', '').strip()
    advance_type = data.get('advance_type', 'single')

    if advance_type not in ('single', 'batch'):
        advance_type = 'single'

    if not title:
        return jsonify({'error': 'Title wajib diisi'}), 400

    advance = Advance(
        title=title,
        description=description,
        advance_type=advance_type,
        user_id=user_id,
        status='draft',
        approved_revision_no=0,
        active_revision_no=None,
    )
    db.session.add(advance)
    db.session.commit()

    return jsonify({'advance': advance.to_dict()}), 201


@advances_bp.route('/<int:advance_id>', methods=['GET'])
@jwt_required()
def get_advance(advance_id):
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    advance = Advance.query.get_or_404(advance_id)

    if user.role != 'manager' and advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    return jsonify({'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>', methods=['PUT'])
@jwt_required()
def update_advance(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if advance.status not in ('draft', 'rejected'):
        return jsonify({'error': 'Header kasbon awal sudah tidak bisa diedit'}), 400

    # Support both JSON and Form data
    data = request.get_json(silent=True) or request.form.to_dict()
    if 'title' in data:
        advance.title = data['title'].strip()
    if 'description' in data:
        advance.description = data['description'].strip()
    if 'advance_type' in data and data['advance_type'] in ('single', 'batch'):
        advance.advance_type = data['advance_type']

    db.session.commit()
    return jsonify({'advance': advance.to_dict()}), 200


@advances_bp.route('/<int:advance_id>', methods=['DELETE'])
@jwt_required()
def delete_advance(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if advance.status not in ('draft',):
        return jsonify({'error': 'Hanya draft yang bisa dihapus'}), 400

    db.session.delete(advance)
    db.session.commit()
    return jsonify({'message': 'Kasbon dihapus'}), 200


@advances_bp.route('/<int:advance_id>/start_revision', methods=['POST'])
@jwt_required()
def start_revision(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if advance.status not in ('approved', 'in_settlement'):
        return jsonify({'error': 'Revisi hanya bisa dibuat dari kasbon yang sudah disetujui'}), 400
    if advance.active_revision_no:
        return jsonify({'error': 'Masih ada revisi yang belum selesai diproses'}), 400

    if _settlement_blocks_revision(advance):
        return jsonify({'error': 'Settlement sudah disubmit/final, revisi tidak bisa ditambah'}), 400

    advance.active_revision_no = _next_revision_no(advance)
    advance.status = 'revision_draft'
    db.session.commit()
    return jsonify({'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>/items', methods=['POST'])
@jwt_required()
def add_advance_item(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    editable_revision_no = _editable_revision_no(advance)
    if editable_revision_no is None:
        return jsonify({'error': 'Kasbon saat ini tidak dalam mode edit'}), 400

    category_id = request.form.get('category_id')
    description = request.form.get('description', '').strip()
    estimated_amount = request.form.get('estimated_amount')
    date_str = request.form.get('date')
    source = request.form.get('source', '').strip() or None
    currency = request.form.get('currency', 'IDR').strip().upper() or 'IDR'
    currency_exchange_str = request.form.get('currency_exchange', '1')

    if not all([category_id, description, estimated_amount]):
        return jsonify({'error': 'Semua field wajib diisi'}), 400

    category = Category.query.get(category_id)
    if not category:
        return jsonify({'error': 'Kategori tidak ditemukan'}), 404

    try:
        estimated_amount = float(estimated_amount)
        if estimated_amount <= 0:
            raise ValueError()
    except (ValueError, TypeError):
        return jsonify({'error': 'Jumlah harus angka positif'}), 400

    item_date = None
    if date_str:
        try:
            item_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            pass

    try:
        currency_exchange = float(currency_exchange_str)
        if currency_exchange <= 0:
            currency_exchange = 1.0
    except (ValueError, TypeError):
        currency_exchange = 1.0

    evidence_path = None
    evidence_filename = None
    if 'evidence' in request.files:
        file = request.files['evidence']
        if file and file.filename and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            unique_name = f"{uuid.uuid4().hex}.{ext}"
            now = datetime.now()
            year_month = f"{now.year}/{now.month:02d}"
            upload_dir = os.path.join(
                current_app.config['UPLOAD_FOLDER'],
                'receipts',
                year_month,
            )
            os.makedirs(upload_dir, exist_ok=True)
            file.save(os.path.join(upload_dir, unique_name))
            evidence_path = f"receipts/{year_month}/{unique_name}"
            evidence_filename = file.filename

    item = AdvanceItem(
        advance_id=advance.id,
        category_id=category_id,
        description=description,
        estimated_amount=estimated_amount,
        revision_no=editable_revision_no or 0,
        evidence_path=evidence_path,
        evidence_filename=evidence_filename,
        date=item_date,
        source=source,
        currency=currency,
        currency_exchange=currency_exchange,
    )
    db.session.add(item)

    # Auto-sync title for single type
    if advance.advance_type == 'single':
        advance.title = item.description

    db.session.commit()
    return jsonify({'item': item.to_dict(), 'advance': advance.to_dict(include_items=True)}), 201


@advances_bp.route('/items/<int:item_id>', methods=['PUT'])
@jwt_required()
def update_advance_item(item_id):
    user_id = int(get_jwt_identity())
    item = AdvanceItem.query.get_or_404(item_id)
    advance = item.advance

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    editable_revision_no = _editable_revision_no(advance)
    if editable_revision_no is None or (item.revision_no or 0) != editable_revision_no:
        return jsonify({'error': 'Item ini sudah terkunci dan tidak bisa diedit'}), 400

    # data handling: support both json and form-data
    data = request.get_json(silent=True) or request.form.to_dict()

    # edit rules:
    # - draft: full edit
    # - submitted: view only
    # - rejected: checklist items only
    is_submitted = advance.status in ('submitted', 'revision_submitted')
    is_rejected = advance.status in ('rejected', 'revision_rejected')

    only_checklist = set(data.keys()).issubset({'notes', 'status'}) and 'notes' in data

    if is_submitted:
        return jsonify({'error': 'saat disubmit hanya bisa melihat, tidak bisa mengubah data'}), 400

    if is_rejected and not only_checklist:
        # rejected status: only allow updates to 'notes' or 'status'
        if any(k in data.keys() for k in ['category_id', 'description', 'estimated_amount', 'date', 'source', 'currency', 'currency_exchange']):
            return jsonify({'error': 'saat rejected hanya boleh mengubah checklist, tidak bisa mengubah data utama'}), 400

    if 'category_id' in data:
        item.category_id = data['category_id']
    if 'description' in data:
        item.description = data['description'].strip()
    if 'estimated_amount' in data:
        try:
            amount = float(data['estimated_amount'])
            if amount <= 0:
                raise ValueError()
            item.estimated_amount = amount
        except (ValueError, TypeError):
            return jsonify({'error': 'Jumlah harus angka positif'}), 400
    if 'date' in data:
        date_str = data['date']
        if date_str:
            try:
                item.date = datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass
        else:
            item.date = None
    if 'source' in data:
        item.source = data['source'].strip() or None
    if 'currency' in data:
        item.currency = (data['currency'] or 'IDR').strip().upper()
    if 'currency_exchange' in data:
        try:
            ex = float(data['currency_exchange'])
            item.currency_exchange = ex if ex > 0 else 1.0
        except (ValueError, TypeError):
            item.currency_exchange = 1.0
    if 'notes' in data:
        item.notes = data['notes']
    if 'status' in data:
        item.status = data['status']

    db.session.commit()

    # Auto-sync title for single type
    if advance.advance_type == 'single':
        # Check if this is the first item or just always sync the edited item to title
        # For simplicity and since 'single' usually has one main meaningful item per revision,
        # we sync the current edited item's description if it's single.
        advance.title = item.description
        db.session.commit()

    return jsonify({'item': item.to_dict(), 'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/items/<int:item_id>', methods=['DELETE'])
@jwt_required()
def delete_advance_item(item_id):
    user_id = int(get_jwt_identity())
    item = AdvanceItem.query.get_or_404(item_id)
    advance = item.advance

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    editable_revision_no = _editable_revision_no(advance)
    if editable_revision_no is None or (item.revision_no or 0) != editable_revision_no:
        return jsonify({'error': 'Item ini sudah terkunci dan tidak bisa dihapus'}), 400

    if item.evidence_path:
        file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], item.evidence_path)
        if os.path.exists(file_path):
            os.remove(file_path)

    db.session.delete(item)
    db.session.commit()
    return jsonify({'message': 'Item dihapus', 'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>/submit', methods=['POST'])
@jwt_required()
def submit_advance(advance_id):
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    if advance.status in ('draft', 'rejected'):
        revision_no = 0
        next_status = 'submitted'
    elif advance.status in ('revision_draft', 'revision_rejected'):
        revision_no = advance.active_revision_no
        next_status = 'revision_submitted'
    else:
        return jsonify({'error': 'Kasbon saat ini tidak bisa disubmit'}), 400

    if revision_no is None:
        return jsonify({'error': 'Revisi belum aktif'}), 400

    revision_items = _items_for_revision(advance, revision_no)
    if len(revision_items) == 0:
        return jsonify({'error': 'Tambahkan minimal 1 item pengeluaran'}), 400
    unresolved_item = next(
        (item for item in revision_items if _has_unchecked_checklist(item)),
        None,
    )
    if unresolved_item:
        return jsonify({
            'error': f'Item "{unresolved_item.description}" masih memiliki komentar revisi yang belum dicentang.'
        }), 400

    advance.status = next_status
    db.session.commit()

    # Notify managers
    message = f"{user.full_name} melakukan submit kasbon: {advance.title}"
    notify_managers('submit', 'advance', advance.id, message, user_id, f'/advances/{advance.id}')

    # Notify staff as confirmation
    notify_staff(user_id, 'submit_confirmation', 'advance', advance.id,
                f'Kasbon "{advance.title}" Anda telah disubmit', user_id, f'/advances/{advance.id}')

    return jsonify({'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>/approve_all', methods=['POST'])
@jwt_required()
def approve_advance(advance_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    advance = Advance.query.get_or_404(advance_id)
    if advance.status not in ('submitted', 'revision_submitted'):
        return jsonify({'error': 'Kasbon ini tidak sedang menunggu approval'}), 400

    # Support both JSON and Form data
    data = request.get_json(silent=True) or request.form.to_dict()
    notes = data.get('notes', 'Disetujui oleh manager')

    if advance.status == 'submitted':
        # Validasi checklist: semua item harus disetujui
        revision_no = 0
        items = _items_for_revision(advance, revision_no)
        for itm in items:
            if itm.status != 'approved':
                return jsonify({
                    'error': f'Gagal approve: Item "{itm.description}" belum disetujui. '
                             'Semua item harus disetujui (Approved) secara individu terlebih dahulu.'
                }), 400

        advance.approved_revision_no = 0
        advance.active_revision_no = None
        advance.status = _status_after_approval(advance)
    else:
        revision_no = advance.active_revision_no
        if revision_no is None:
            return jsonify({'error': 'Nomor revisi tidak ditemukan'}), 400

        # Validasi checklist untuk revisi
        items = _items_for_revision(advance, revision_no)
        for itm in items:
            if itm.status != 'approved':
                return jsonify({
                    'error': f'Gagal approve: Item "{itm.description}" belum disetujui (revisi {revision_no}). '
                             'Semua item harus disetujui (Approved) secara individu terlebih dahulu.'
                }), 400

        advance.approved_revision_no = revision_no
        _sync_revision_items_to_settlement(advance, revision_no)
        advance.active_revision_no = None
        advance.status = _status_after_approval(advance)

    advance.notes = notes
    advance.approved_at = datetime.now(timezone.utc)
    db.session.commit()

    # Notify staff
    message = f"Kasbon Anda telah disetujui: {advance.title}"
    notify_staff(advance.user_id, 'approve', 'advance', advance.id, message, user.id, f'/advances/{advance.id}')

    return jsonify({'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>/reject_all', methods=['POST'])
@jwt_required()
def reject_advance(advance_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    advance = Advance.query.get_or_404(advance_id)
    if advance.status not in ('submitted', 'revision_submitted'):
        return jsonify({'error': 'Kasbon ini tidak sedang menunggu approval'}), 400

    # Support both JSON and Form data
    data = request.get_json(silent=True) or request.form.to_dict()
    notes = str(data.get('notes', '')).strip()
    if not notes:
        return jsonify({'error': 'Alasan penolakan wajib diisi'}), 400

    if advance.status == 'submitted':
        revision_no = 0
        advance.status = 'draft'
    else:
        revision_no = advance.active_revision_no
        advance.status = 'revision_draft'

    if revision_no is None:
        return jsonify({'error': 'Nomor revisi tidak ditemukan'}), 400

    for item in _items_for_revision(advance, revision_no):
        if item.status in ('pending', 'approved'):
            item.status = 'rejected'
            item.notes = _merge_rejection_notes_advance(item.notes or '', notes)

    advance.notes = notes
    db.session.commit()

    # Notify staff
    message = f"Kasbon Anda telah ditolak: {advance.title}. Alasan: {notes}"
    notify_staff(advance.user_id, 'reject', 'advance', advance.id, message, user.id, f'/advances/{advance.id}')

    return jsonify({'advance': advance.to_dict(include_items=True)}), 200


@advances_bp.route('/<int:advance_id>/create_settlement', methods=['POST'])
@jwt_required()
def create_settlement_from_advance(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if advance.status not in ('approved', 'in_settlement'):
        return jsonify({'error': 'Kasbon harus sudah disetujui sebelum dibuat settlement'}), 400
    if advance.settlement:
        return jsonify({
            'message': 'Settlement sudah ada',
            'settlement': advance.settlement.to_dict(include_expenses=True),
        }), 200

    settlement = Settlement(
        title=advance.title,
        description=advance.description,
        user_id=advance.user_id,
        settlement_type=advance.advance_type,
        status='draft',
        advance_id=advance.id,
    )
    db.session.add(settlement)
    db.session.flush()

    today = datetime.now(timezone.utc).date()
    for item in advance.items:
        revision_no = item.revision_no or 0
        if revision_no > (advance.approved_revision_no or 0):
            continue
        db.session.add(
            Expense(
                settlement_id=settlement.id,
                category_id=item.category_id,
                description=item.description,
                amount=item.estimated_amount,
                date=today,
                source=f'Advance Revisi {revision_no}' if revision_no > 0 else 'Advance',
                advance_item_id=item.id,
                revision_no=revision_no,
                currency='IDR',
                currency_exchange=1,
                evidence_path=item.evidence_path,
                evidence_filename=item.evidence_filename,
                status='pending',
            )
        )

    advance.status = 'in_settlement'
    db.session.commit()
    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 201


@advances_bp.route('/items/<int:item_id>/approve', methods=['POST'])
@jwt_required()
def approve_advance_item(item_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    item = AdvanceItem.query.get_or_404(item_id)
    advance = item.advance
    if advance.status not in ('submitted', 'revision_submitted'):
        return jsonify({'error': 'Kasbon ini tidak sedang menunggu approval'}), 400

    item.status = 'approved'
    item.notes = 'Disetujui oleh manager'
    db.session.commit()
    return jsonify({'item': item.to_dict()}), 200


def _merge_rejection_notes_advance(old_notes_str, new_notes_str):
    """Gabungkan komentar reject baru ke checklist lama (append)."""
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


@advances_bp.route('/items/<int:item_id>/reject', methods=['POST'])
@jwt_required()
def reject_advance_item(item_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    item = AdvanceItem.query.get_or_404(item_id)
    advance = item.advance
    if advance.status not in ('submitted', 'revision_submitted'):
        return jsonify({'error': 'Kasbon ini tidak sedang menunggu approval'}), 400

    data = request.get_json(silent=True) or request.form.to_dict()
    notes = data.get('notes', '').strip()
    if not notes:
        return jsonify({'error': 'Alasan penolakan wajib diisi'}), 400

    item.status = 'rejected'
    item.notes = _merge_rejection_notes_advance(item.notes or '', notes)
    if advance.status == 'submitted':
        advance.status = 'draft'
    elif advance.status == 'revision_submitted':
        advance.status = 'revision_draft'
    db.session.commit()
    return jsonify({'item': item.to_dict()}), 200


@advances_bp.route('/items/bulk-delete', methods=['POST'])
@jwt_required()
def bulk_delete_advance_items():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    # Support both JSON and Form data
    data = request.get_json(silent=True) or request.form.to_dict()
    item_ids = data.get('item_ids', [])

    if not item_ids:
        return jsonify({'error': 'Daftar ID item kosong'}), 400

    items = AdvanceItem.query.filter(AdvanceItem.id.in_(item_ids)).all()
    count = 0

    for item in items:
        advance = item.advance
        can_delete = False
        if user.role == 'manager':
            if advance.status not in ('approved', 'in_settlement'):
                can_delete = True
        else:
            if advance.user_id == user_id and advance.status in ('draft', 'rejected', 'revision_draft', 'revision_rejected'):
                can_delete = True

        if can_delete:
            if item.evidence_path:
                file_path = os.path.join(current_app.config['UPLOAD_FOLDER'], item.evidence_path)
                if os.path.exists(file_path):
                    os.remove(file_path)

            db.session.delete(item)
            count += 1

    db.session.commit()
    return jsonify({'message': f'{count} item berhasil dihapus'}), 200
@advances_bp.route('/<int:advance_id>/move_to_draft', methods=['POST'])
@jwt_required()
def move_advance_to_draft(advance_id):
    user_id = int(get_jwt_identity())
    advance = Advance.query.get_or_404(advance_id)

    if advance.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    if advance.status == 'submitted' or advance.status == 'rejected':
        advance.status = 'draft'
    elif advance.status == 'revision_submitted' or advance.status == 'revision_rejected':
        advance.status = 'revision_draft'
    else:
        return jsonify({'error': f'Status {advance.status} tidak bisa ditarik ke draft'}), 400

    db.session.commit()
    return jsonify({'message': 'Kasbon ditarik ke draft', 'advance': advance.to_dict(include_items=True)}), 200
