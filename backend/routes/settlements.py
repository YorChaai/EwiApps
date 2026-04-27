from datetime import datetime, timezone
import json
from typing import Any

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy.orm import joinedload
from models import Advance, Expense, Settlement, User, db
from routes.notifications import notify_managers, notify_staff

settlements_bp = Blueprint('settlements', __name__, url_prefix='/api/settlements')


def _sync_advance_after_settlement(settlement):
    if not settlement.advance:
        return
    if settlement.status in ('draft', 'submitted', 'approved', 'rejected', 'completed'):
        settlement.advance.status = 'in_settlement'


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


def _has_unchecked_checklist(expense):
    checklist = _parse_checklist_notes(expense.notes)
    return bool(checklist) and any(not item['checked'] for item in checklist)


@settlements_bp.route('', methods=['GET'])
@jwt_required()
def list_settlements():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)

    status_filter = request.args.get('status')
    report_year = request.args.get('report_year', type=int)
    mode = request.args.get('mode', 'report') # 'report' or 'actual'
    search_query = request.args.get('search', '').strip()

    # Debug logging - DETAIL
    print(f'[SETTLEMENT_API] ===== REQUEST =====')
    print(f'[SETTLEMENT_API] user_id={user_id}, role={user.role}')
    print(f'[SETTLEMENT_API] status_filter={status_filter}')
    print(f'[SETTLEMENT_API] report_year={report_year}, mode={mode}')
    print(f'[SETTLEMENT_API] search_query={search_query}')

    if user.role == 'manager':
        query = Settlement.query.options(joinedload(Settlement.expenses))
    else:
        query = Settlement.query.options(joinedload(Settlement.expenses)).filter_by(user_id=user_id)

    # STATUS FILTER
    if status_filter in ('approved', 'completed'):
        print(f'[SETTLEMENT_API] Filtering status: approved OR completed')
        query = query.filter(Settlement.status.in_(('approved', 'completed')))
    elif status_filter == 'rejected':
        # Include settlement status 'rejected' OR settlements with any rejected expense
        has_rejected_expenses = db.exists().where(
            db.and_(
                Expense.settlement_id == Settlement.id,
                Expense.status == 'rejected'
            )
        )
        query = query.filter(db.or_(Settlement.status == 'rejected', has_rejected_expenses))
    elif status_filter:
        print(f'[SETTLEMENT_API] Filtering status: {status_filter}')
        query = query.filter_by(status=status_filter)

    # YEAR FILTER
    if report_year is not None and report_year != 0:
        print(f'[SETTLEMENT_API] Filtering year={report_year} with mode={mode}')

        if mode == 'report':
            # MURNI berdasarkan report_year
            query = query.filter(Settlement.report_year == report_year)
        else:
            # MURNI berdasarkan tahun aktual di item
            expense_match = db.exists().where(
                db.and_(
                    Expense.settlement_id == Settlement.id,
                    db.extract('year', Expense.date) == report_year,
                )
            )
            # Jika tidak ada item, fallback ke tahun created_at
            settlement_no_expenses = db.not_(
                db.exists().where(Expense.settlement_id == Settlement.id)
            )
            settlement_created_year_match = db.extract('year', Settlement.created_at) == report_year

            query = query.filter(db.or_(
                expense_match,
                db.and_(settlement_no_expenses, settlement_created_year_match)
            )).distinct()
    else:
        print(f'[SETTLEMENT_API] NO year filter (report_year={report_year})')

    # SEARCH FILTER
    if search_query:
        like_pattern = f'%{search_query}%'
        print(f'[SETTLEMENT_API] Filtering search: {search_query}')
        query = query.filter(
            db.or_(
                Settlement.title.ilike(like_pattern),
                Settlement.description.ilike(like_pattern),
            )
        )

    type_filter = request.args.get('type')
    if type_filter and type_filter in ('single', 'batch'):
        query = query.filter_by(settlement_type=type_filter)

    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    if start_date_str:
        try:
            start_date = datetime.strptime(
                start_date_str,
                '%Y-%m-%d',
            ).replace(tzinfo=timezone.utc)
            query = query.filter(Settlement.created_at >= start_date)
        except ValueError:
            pass

    if end_date_str:
        try:
            end_date = datetime.strptime(
                end_date_str,
                '%Y-%m-%d',
            ).replace(hour=23, minute=59, second=59, tzinfo=timezone.utc)
            query = query.filter(Settlement.created_at <= end_date)
        except ValueError:
            pass

    # Execute query
    settlements = query.order_by(
        Settlement.created_at.asc(),
        Settlement.id.asc()
    ).all()

    singles = [s for s in settlements if s.settlement_type == 'single']
    batches = [s for s in settlements if s.settlement_type == 'batch']
    ordered = singles + batches

    # Log detail hasil
    print(f'[SETTLEMENT_API] ===== RESULT =====')
    print(f'[SETTLEMENT_API] Total: {len(ordered)} settlements')
    for s in ordered[:10]:  # Log first 10
        print(f'[SETTLEMENT_API]   - ID={s.id}, title={s.title}, status={s.status}, created_at={s.created_at}, year={s.created_at.year if s.created_at else "?"}')
    if len(ordered) > 10:
        print(f'[SETTLEMENT_API]   ... and {len(ordered) - 10} more')

    return jsonify({'settlements': [s.to_dict() for s in ordered]}), 200


@settlements_bp.route('', methods=['POST'])
@jwt_required()
def create_settlement():
    user_id = int(get_jwt_identity())
    data = request.get_json() or {}

    title = data.get('title', '').strip()
    description = data.get('description', '').strip()
    advance_id = data.get('advance_id')
    settlement_type = data.get('settlement_type', 'single')
    try:
        report_year = int(data.get('report_year')) if data.get('report_year') else None
    except (ValueError, TypeError):
        report_year = None

    if settlement_type not in ('single', 'batch'):
        settlement_type = 'single'

    if not title:
        return jsonify({'error': 'Title wajib diisi'}), 400

    linked_advance = None
    if advance_id:
        linked_advance = Advance.query.get(advance_id)
        if not linked_advance or linked_advance.user_id != user_id:
            return jsonify({'error': 'Kasbon tidak ditemukan atau bukan milik Anda'}), 404
        if linked_advance.status not in ('approved', 'in_settlement'):
            return jsonify({'error': 'Kasbon harus berstatus approved sebelum dibuat settlement'}), 400
        if linked_advance.settlement:
            return jsonify({'error': 'Kasbon ini sudah punya settlement'}), 400
        settlement_type = linked_advance.advance_type

    # Set created_at to match report_year if provided
    created_at = datetime.now(timezone.utc)
    if report_year:
        try:
            created_at = created_at.replace(year=report_year)
        except ValueError:
            created_at = created_at.replace(year=report_year, day=28)

    settlement = Settlement(
        title=title,
        description=description,
        user_id=user_id,
        status='draft',
        settlement_type=settlement_type,
        advance_id=advance_id,
        report_year=report_year,
        created_at=created_at
    )
    db.session.add(settlement)
    db.session.flush()

    if linked_advance:
        for item in linked_advance.items:
            revision_no = item.revision_no or 0
            if revision_no > (linked_advance.approved_revision_no or 0):
                continue
            expense_date = item.date or datetime.now(timezone.utc).date()
            db.session.add(
                Expense(
                    settlement_id=settlement.id,
                    category_id=item.category_id,
                    description=item.description,
                    amount=item.estimated_amount,
                    date=expense_date,
                    source='Kasbon',
                    advance_item_id=item.id,
                    revision_no=revision_no,
                    currency='IDR',
                    currency_exchange=1,
                    evidence_path=item.evidence_path,
                    evidence_filename=item.evidence_filename,
                    status='pending',
                )
            )
        linked_advance.status = 'in_settlement'

    db.session.commit()
    # Refresh to ensure all properties are loaded correctly
    db.session.refresh(settlement)

    return jsonify({'settlement': settlement.to_dict()}), 201


@settlements_bp.route('/<int:settlement_id>', methods=['GET'])
@jwt_required()
def get_settlement(settlement_id):
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    settlement = Settlement.query.get_or_404(settlement_id)

    if user.role != 'manager' and settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403

    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 200


@settlements_bp.route('/<int:settlement_id>', methods=['PUT'])
@jwt_required()
def update_settlement(settlement_id):
    user_id = int(get_jwt_identity())
    settlement = Settlement.query.get_or_404(settlement_id)

    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if settlement.status not in ('draft', 'rejected'):
        return jsonify({'error': 'Settlement sudah tidak bisa diedit'}), 400

    data = request.get_json(silent=True) or request.form.to_dict()
    if 'title' in data:
        settlement.title = str(data['title']).strip()
    if 'description' in data:
        settlement.description = str(data['description']).strip()

    db.session.commit()
    return jsonify({'settlement': settlement.to_dict()}), 200

@settlements_bp.route('/expenses/<int:expense_id>', methods=['PUT'])
@jwt_required()
def update_expense(expense_id):
    user_id = int(get_jwt_identity())
    expense = Expense.query.get_or_404(expense_id)
    settlement = expense.settlement

    user = User.query.get(user_id)
    is_manager = user.role == 'manager'

    # data handling: support json and form
    data = request.get_json(silent=True) or request.form.to_dict()

    # edit rules:
    # - non-manager owner: edit only in draft/rejected/pending
    # - manager: can always update notes/status for review
    if settlement.status not in ('draft', 'rejected', 'pending', 'submitted'):
        return jsonify({'error': 'expense sudah tidak bisa diedit'}), 400

    if 'notes' in data:
        expense.notes = data['notes']
    if 'status' in data:
        expense.status = data['status']

    db.session.commit()
    return jsonify({'expense': expense.to_dict(), 'settlement': settlement.to_dict(include_expenses=True)}), 200

@settlements_bp.route('/<int:settlement_id>', methods=['DELETE'])
@jwt_required()
def delete_settlement(settlement_id):
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    settlement = Settlement.query.get_or_404(settlement_id)

    is_manager = user.role == 'manager'

    if not is_manager:
        if settlement.user_id != user_id:
            return jsonify({'error': 'Akses ditolak'}), 403
        if settlement.status not in ('draft',):
            return jsonify({'error': 'Hanya draft yang bisa dihapus'}), 400

    if settlement.advance:
        # Jika settlement dihapus, kembalikan status kasbon aslinya
        # agar bisa disalin (copy) lagi nantinya.
        adv = settlement.advance
        adv.status = 'approved'
        adv.settlement_id = None
        # Biarkan kasbon tetap ada, jangan di-delete

    # Hapus semua expenses terkait secara eksplisit (opsional tapi aman)
    for exp in settlement.expenses:
        db.session.delete(exp)

    db.session.delete(settlement)
    db.session.commit()
    return jsonify({'message': 'Settlement berhasil dihapus. Kasbon asal tetap tersedia.'}), 200

@settlements_bp.route('/<int:settlement_id>/submit', methods=['POST'])
@jwt_required()
def submit_settlement(settlement_id):
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    settlement = Settlement.query.get_or_404(settlement_id)

    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak'}), 403
    if settlement.status not in ('draft', 'rejected'):
        return jsonify({'error': 'Settlement sudah disubmit'}), 400
    if len(settlement.expenses) == 0:
        return jsonify({'error': 'Tambahkan minimal 1 expense'}), 400
    unresolved_expense = next(
        (expense for expense in settlement.expenses if _has_unchecked_checklist(expense)),
        None,
    )
    if unresolved_expense is not None:
        unresolved_description = unresolved_expense.description
        return jsonify({
            'error': f'Expense "{unresolved_description}" masih memiliki komentar revisi yang belum dicentang.'
        }), 400

    settlement.status = 'submitted'
    _sync_advance_after_settlement(settlement)
    db.session.commit()

    # Notify managers
    message = f"{user.full_name} melakukan submit settlement: {settlement.title}"
    notify_managers('submit', 'settlement', settlement.id, message, user_id, f'/settlements/{settlement.id}')

    # Notify staff as confirmation
    notify_staff(user_id, 'submit_confirmation', 'settlement', settlement.id,
                f'Settlement "{settlement.title}" Anda telah disubmit', user_id, f'/settlements/{settlement.id}')

    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 200


@settlements_bp.route('/<int:settlement_id>/approve', methods=['POST'])
@jwt_required()
def approve_settlement(settlement_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    settlement = Settlement.query.get_or_404(settlement_id)
    if settlement.status != 'submitted':
        return jsonify({'error': 'Hanya settlement submitted yang bisa diapprove'}), 400

    # Pastikan SEMUA item sudah diapprove oleh manager secara individu
    for expense in settlement.expenses:
        if expense.status != 'approved':
            return jsonify({
                'error': f'Gagal approve: Item "{expense.description}" masih berstatus {expense.status}. '
                         'Semua item harus disetujui (Approved) secara individu terlebih dahulu.'
            }), 400

    settlement.status = 'approved'
    _sync_advance_after_settlement(settlement)
    db.session.commit()

    # Notify staff
    message = f"Settlement Anda telah disetujui: {settlement.title}"
    notify_staff(settlement.user_id, 'approve', 'settlement', settlement.id, message, user.id, f'/settlements/{settlement.id}')

    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 200


@settlements_bp.route('/<int:settlement_id>/complete', methods=['POST'])
@jwt_required()
def complete_settlement(settlement_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    settlement = Settlement.query.get_or_404(settlement_id)
    if settlement.status not in ('approved', 'completed'):
        return jsonify(
            {'error': 'Hanya settlement approved yang bisa dibuka sebagai completed view'}
        ), 400

    for expense in settlement.expenses:
        if expense.status == 'rejected':
            return jsonify(
                {'error': 'Settlement dengan item rejected tidak bisa masuk completed view'}
            ), 400
        if expense.status == 'pending':
            return jsonify(
                {'error': 'Masih ada item pending, approve settlement terlebih dulu'}
            ), 400

    if settlement.completed_at is None:
        settlement.completed_at = datetime.now(timezone.utc)
    _sync_advance_after_settlement(settlement)
    db.session.commit()
    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 200



def _merge_rejection_notes_settlement(old_notes_str, new_notes_str):
    """gabungkan komentar reject baru ke checklist lama (append)."""
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


@settlements_bp.route('/<int:settlement_id>/reject_all', methods=['POST'])
@jwt_required()
def reject_all_expenses(settlement_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak'}), 403

    settlement = Settlement.query.get_or_404(settlement_id)
    if settlement.status not in ('submitted', 'approved'):
        return jsonify({'error': 'Hanya settlement submitted/approved yang bisa diproses'}), 400

    data = request.get_json() or {}
    rejection_notes = str(data.get('notes', '')).strip()
    if not rejection_notes:
        return jsonify({'error': 'Alasan penolakan wajib diisi'}), 400

    for expense in settlement.expenses:
        if expense.status in ('pending', 'approved'):
            expense.status = 'rejected'
            expense.notes = _merge_rejection_notes_settlement(expense.notes or '', rejection_notes)

    settlement.status = 'draft'
    _sync_advance_after_settlement(settlement)
    db.session.commit()

    # Notify staff
    message = f"Settlement Anda telah ditolak: {settlement.title}. Alasan: {rejection_notes}"
    notify_staff(settlement.user_id, 'reject', 'settlement', settlement.id, message, user.id, f'/settlements/{settlement.id}')

    return jsonify({'settlement': settlement.to_dict(include_expenses=True)}), 200

@settlements_bp.route('/<int:settlement_id>/move_to_draft', methods=['POST'])
@jwt_required()
def move_to_draft(settlement_id):
    user_id = int(get_jwt_identity())
    settlement = Settlement.query.get_or_404(settlement_id)

    if settlement.user_id != user_id:
        return jsonify({'error': 'Akses ditolak: Hanya pemilik yang bisa mengubah ke draft'}), 403

    if settlement.status not in ('submitted', 'rejected'):
        return jsonify({'error': 'Hanya settlement submitted atau rejected yang bisa dikembalikan ke draft'}), 400

    settlement.status = 'draft'
    db.session.commit()
    return jsonify({'message': 'Settlement berhasil dikembalikan ke draft', 'settlement': settlement.to_dict()}), 200
