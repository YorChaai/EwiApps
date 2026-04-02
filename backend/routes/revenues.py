import json
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Revenue, ManualCombineGroup
from datetime import datetime

revenues_bp = Blueprint('revenues', __name__, url_prefix='/api/revenues')

def _parse_date(date_str):
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None


def _validate_manual_revenue_group(year, row_ids):
    clean_ids = []
    for row_id in row_ids or []:
        try:
            clean_ids.append(int(row_id))
        except Exception:
            continue
    clean_ids = list(dict.fromkeys(clean_ids))
    if len(clean_ids) < 2:
        return None, 'Pilih minimal 2 data revenue untuk combine.'

    items = Revenue.query.filter(Revenue.id.in_(clean_ids)).order_by(
        Revenue.invoice_date.asc(),
        Revenue.id.asc(),
    ).all()
    if len(items) != len(clean_ids):
        return None, 'Sebagian data revenue tidak ditemukan.'

    receive_dates = {item.receive_date.isoformat() for item in items if item.receive_date}
    if len(receive_dates) != 1 or any(item.receive_date is None for item in items):
        return None, 'Combine revenue hanya bisa jika Receive Date sama persis.'

    positions = {
        row_id: idx
        for idx, (row_id,) in enumerate(
            db.session.query(Revenue.id)
            .filter(db.extract('year', Revenue.invoice_date) == int(year))
            .order_by(Revenue.invoice_date.asc(), Revenue.id.asc())
            .all()
        )
    }
    selected_positions = sorted(positions.get(row_id, -1) for row_id in clean_ids)
    if -1 in selected_positions:
        return None, 'Data revenue yang dipilih tidak sesuai tahun laporan.'
    if selected_positions[-1] - selected_positions[0] + 1 != len(selected_positions):
        return None, 'Combine revenue hanya bisa untuk baris yang berurutan.'

    overlap = ManualCombineGroup.query.filter_by(
        table_name='revenues',
        report_year=int(year),
    ).all()
    for group in overlap:
        existing_ids = set(group.row_ids())
        if existing_ids.intersection(clean_ids):
            return None, 'Ada data revenue yang sudah masuk combine lain. Lepas combine lama dulu.'

    return {
        'group_date': items[0].receive_date,
        'row_ids': clean_ids,
    }, None

@revenues_bp.route('', methods=['GET'])
@jwt_required()
def get_revenues():
    user = User.query.get(int(get_jwt_identity()))

    # filter opsional
    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    query = Revenue.query

    if start_date_str:
        start_date = _parse_date(start_date_str)
        if start_date:
            query = query.filter(Revenue.invoice_date >= start_date)

    if end_date_str:
        end_date = _parse_date(end_date_str)
        if end_date:
            query = query.filter(Revenue.invoice_date <= end_date)

    revenues = query.order_by(Revenue.invoice_date.asc(), Revenue.id.asc()).all()
    return jsonify([r.to_dict() for r in revenues]), 200

@revenues_bp.route('/<int:revenue_id>', methods=['GET'])
@jwt_required()
def get_revenue(revenue_id):
    revenue = Revenue.query.get_or_404(revenue_id)
    return jsonify(revenue.to_dict()), 200

@revenues_bp.route('', methods=['POST'])
@jwt_required()
def create_revenue():
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak. Hanya manager yang dapat membuat record Revenue.'}), 403

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Must provide data'}), 400

    invoice_date = _parse_date(data.get('invoice_date'))
    description = data.get('description')
    invoice_value = data.get('invoice_value')

    if not invoice_date or not description or invoice_value is None:
        return jsonify({'error': 'invoice_date, description, and invoice_value are required'}), 400

    # Normalize and validate revenue_type
    revenue_type = Revenue.normalize_revenue_type(data.get('revenue_type'))
    if revenue_type not in (Revenue.REVENUE_DIRECT, Revenue.REVENUE_OTHER):
        return jsonify({'error': 'Invalid revenue_type. Must be "pendapatan_langsung" or "pendapatan_lain_lain"'}), 400

    try:
        revenue = Revenue(
            invoice_date=invoice_date,
            description=description,
            invoice_value=float(invoice_value),
            currency=data.get('currency', 'IDR'),
            currency_exchange=float(data['currency_exchange']) if data.get('currency_exchange') else None,
            invoice_number=data.get('invoice_number'),
            client=data.get('client'),
            receive_date=_parse_date(data.get('receive_date')),
            amount_received=float(data['amount_received']) if data.get('amount_received') is not None else None,
            ppn=float(data['ppn']) if data.get('ppn') is not None else None,
            pph_23=float(data['pph_23']) if data.get('pph_23') is not None else None,
            transfer_fee=float(data['transfer_fee']) if data.get('transfer_fee') is not None else None,
            remark=data.get('remark'),
            revenue_type=revenue_type
        )
        db.session.add(revenue)
        db.session.commit()
        return jsonify(revenue.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@revenues_bp.route('/<int:revenue_id>', methods=['PUT'])
@jwt_required()
def update_revenue(revenue_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    revenue = Revenue.query.get_or_404(revenue_id)
    data = request.get_json()

    if 'invoice_date' in data:
        revenue.invoice_date = _parse_date(data['invoice_date'])
    if 'description' in data:
        revenue.description = data['description']
    if 'invoice_value' in data:
        revenue.invoice_value = float(data['invoice_value'])
    if 'currency' in data:
        revenue.currency = data['currency']
    if 'currency_exchange' in data:
        revenue.currency_exchange = float(data['currency_exchange']) if data['currency_exchange'] else None
    if 'invoice_number' in data:
        revenue.invoice_number = data['invoice_number']
    if 'client' in data:
        revenue.client = data['client']
    if 'receive_date' in data:
        revenue.receive_date = _parse_date(data['receive_date'])
    if 'amount_received' in data:
        revenue.amount_received = float(data['amount_received']) if data['amount_received'] is not None else None
    if 'ppn' in data:
        revenue.ppn = float(data['ppn']) if data['ppn'] is not None else None
    if 'pph_23' in data:
        revenue.pph_23 = float(data['pph_23']) if data['pph_23'] is not None else None
    if 'transfer_fee' in data:
        revenue.transfer_fee = float(data['transfer_fee']) if data['transfer_fee'] is not None else None
    if 'remark' in data:
        revenue.remark = data['remark']
    if 'revenue_type' in data:
        revenue_type = Revenue.normalize_revenue_type(data['revenue_type'])
        if revenue_type not in (Revenue.REVENUE_DIRECT, Revenue.REVENUE_OTHER):
            return jsonify({'error': 'Invalid revenue_type. Must be "pendapatan_langsung" or "pendapatan_lain_lain"'}), 400
        revenue.revenue_type = revenue_type

    try:
        db.session.commit()
        return jsonify(revenue.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@revenues_bp.route('/<int:revenue_id>', methods=['DELETE'])
@jwt_required()
def delete_revenue(revenue_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    revenue = Revenue.query.get_or_404(revenue_id)
    try:
        db.session.delete(revenue)
        db.session.commit()
        return jsonify({'message': 'Revenue deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@revenues_bp.route('/combine-groups', methods=['GET'])
@jwt_required()
def get_revenue_combine_groups():
    year = request.args.get('year', type=int)
    if not year:
        return jsonify({'error': 'year is required'}), 400

    groups = ManualCombineGroup.query.filter_by(
        table_name='revenues',
        report_year=year,
    ).order_by(ManualCombineGroup.group_date.asc(), ManualCombineGroup.id.asc()).all()
    return jsonify([group.to_dict() for group in groups]), 200


@revenues_bp.route('/combine-groups', methods=['POST'])
@jwt_required()
def create_revenue_combine_group():
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    data = request.get_json() or {}
    year = data.get('year')
    validated, error = _validate_manual_revenue_group(year, data.get('row_ids') or [])
    if error:
        return jsonify({'error': error}), 400

    group = ManualCombineGroup(
        table_name='revenues',
        report_year=int(year),
        group_date=validated['group_date'],
        row_ids_json=json.dumps(validated['row_ids']),
    )
    try:
        db.session.add(group)
        db.session.commit()
        return jsonify(group.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@revenues_bp.route('/combine-groups/<int:group_id>', methods=['DELETE'])
@jwt_required()
def delete_revenue_combine_group(group_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    group = ManualCombineGroup.query.filter_by(
        id=group_id,
        table_name='revenues',
    ).first_or_404()
    try:
        db.session.delete(group)
        db.session.commit()
        return jsonify({'message': 'Revenue combine group deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
