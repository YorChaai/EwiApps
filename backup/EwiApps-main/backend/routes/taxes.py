import json
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Tax, ManualCombineGroup
from datetime import datetime

taxes_bp = Blueprint('taxes', __name__, url_prefix='/api/taxes')

def _parse_date(date_str):
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None


def _validate_manual_tax_group(year, row_ids):
    clean_ids = []
    for row_id in row_ids or []:
        try:
            clean_ids.append(int(row_id))
        except Exception:
            continue
    clean_ids = list(dict.fromkeys(clean_ids))
    if len(clean_ids) < 2:
        return None, 'Pilih minimal 2 data pajak untuk combine.'

    items = Tax.query.filter(Tax.id.in_(clean_ids)).order_by(
        Tax.date.asc(),
        Tax.id.asc(),
    ).all()
    if len(items) != len(clean_ids):
        return None, 'Sebagian data pajak tidak ditemukan.'

    dates = {item.date.isoformat() for item in items if item.date}
    if len(dates) != 1 or any(item.date is None for item in items):
        return None, 'Combine pajak hanya bisa jika tanggal sama persis.'

    positions = {
        row_id: idx
        for idx, (row_id,) in enumerate(
            db.session.query(Tax.id)
            .filter(db.extract('year', Tax.date) == int(year))
            .order_by(Tax.date.asc(), Tax.id.asc())
            .all()
        )
    }
    selected_positions = sorted(positions.get(row_id, -1) for row_id in clean_ids)
    if -1 in selected_positions:
        return None, 'Data pajak yang dipilih tidak sesuai tahun laporan.'
    if selected_positions[-1] - selected_positions[0] + 1 != len(selected_positions):
        return None, 'Combine pajak hanya bisa untuk baris yang berurutan.'

    overlap = ManualCombineGroup.query.filter_by(
        table_name='taxes',
        report_year=int(year),
    ).all()
    for group in overlap:
        existing_ids = set(group.row_ids())
        if existing_ids.intersection(clean_ids):
            return None, 'Ada data pajak yang sudah masuk combine lain. Lepas combine lama dulu.'

    return {
        'group_date': items[0].date,
        'row_ids': clean_ids,
    }, None

@taxes_bp.route('', methods=['GET'])
@jwt_required()
def get_taxes():
    user = User.query.get(int(get_jwt_identity()))

    start_date_str = request.args.get('start_date')
    end_date_str = request.args.get('end_date')

    query = Tax.query

    if start_date_str:
        start_date = _parse_date(start_date_str)
        if start_date:
            query = query.filter(Tax.date >= start_date)

    if end_date_str:
        end_date = _parse_date(end_date_str)
        if end_date:
            query = query.filter(Tax.date <= end_date)

    taxes = query.order_by(Tax.date.asc(), Tax.id.asc()).all()
    return jsonify([t.to_dict() for t in taxes]), 200

@taxes_bp.route('/<int:tax_id>', methods=['GET'])
@jwt_required()
def get_tax(tax_id):
    tax = Tax.query.get_or_404(tax_id)
    return jsonify(tax.to_dict()), 200

@taxes_bp.route('', methods=['POST'])
@jwt_required()
def create_tax():
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Must provide data'}), 400

    date = _parse_date(data.get('date'))
    description = data.get('description')
    transaction_value = data.get('transaction_value')

    if not date or not description or transaction_value is None:
        return jsonify({'error': 'date, description, and transaction_value are required'}), 400

    try:
        tax = Tax(
            date=date,
            description=description,
            transaction_value=float(transaction_value),
            currency=data.get('currency', 'IDR'),
            currency_exchange=float(data['currency_exchange']) if data.get('currency_exchange') else None,
            ppn=float(data['ppn']) if data.get('ppn') is not None else None,
            pph_21=float(data['pph_21']) if data.get('pph_21') is not None else None,
            pph_23=float(data['pph_23']) if data.get('pph_23') is not None else None,
            pph_26=float(data['pph_26']) if data.get('pph_26') is not None else None
        )
        db.session.add(tax)
        db.session.commit()
        return jsonify(tax.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@taxes_bp.route('/<int:tax_id>', methods=['PUT'])
@jwt_required()
def update_tax(tax_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    tax = Tax.query.get_or_404(tax_id)
    data = request.get_json()

    if 'date' in data:
        tax.date = _parse_date(data['date'])
    if 'description' in data:
        tax.description = data['description']
    if 'transaction_value' in data:
        tax.transaction_value = float(data['transaction_value'])
    if 'currency' in data:
        tax.currency = data['currency']
    if 'currency_exchange' in data:
        tax.currency_exchange = float(data['currency_exchange']) if data['currency_exchange'] else None
    if 'ppn' in data:
        tax.ppn = float(data['ppn']) if data['ppn'] is not None else None
    if 'pph_21' in data:
        tax.pph_21 = float(data['pph_21']) if data['pph_21'] is not None else None
    if 'pph_23' in data:
        tax.pph_23 = float(data['pph_23']) if data['pph_23'] is not None else None
    if 'pph_26' in data:
        tax.pph_26 = float(data['pph_26']) if data['pph_26'] is not None else None

    try:
        db.session.commit()
        return jsonify(tax.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@taxes_bp.route('/<int:tax_id>', methods=['DELETE'])
@jwt_required()
def delete_tax(tax_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    tax = Tax.query.get_or_404(tax_id)
    try:
        # Hapus combine groups yang mengandung row ini
        groups_to_delete = []
        groups_to_update = []
        for group in ManualCombineGroup.query.filter_by(table_name='taxes').all():
            row_ids = group.row_ids()
            if tax_id in row_ids:
                if len(row_ids) <= 2:
                    # Hanya 2 row, hapus group saja
                    groups_to_delete.append(group)
                else:
                    # Lebih dari 2, hapus ID dari group
                    new_row_ids = [rid for rid in row_ids if rid != tax_id]
                    group.row_ids_json = json.dumps(new_row_ids)
                    groups_to_update.append(group)

        for group in groups_to_delete:
            db.session.delete(group)
        for group in groups_to_update:
            db.session.add(group)

        db.session.delete(tax)
        db.session.commit()
        return jsonify({'message': 'Tax deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@taxes_bp.route('/combine-groups', methods=['GET'])
@jwt_required()
def get_tax_combine_groups():
    year = request.args.get('year', type=int)
    if not year:
        return jsonify({'error': 'year is required'}), 400

    groups = ManualCombineGroup.query.filter_by(
        table_name='taxes',
        report_year=year,
    ).order_by(ManualCombineGroup.group_date.asc(), ManualCombineGroup.id.asc()).all()
    return jsonify([group.to_dict() for group in groups]), 200


@taxes_bp.route('/combine-groups', methods=['POST'])
@jwt_required()
def create_tax_combine_group():
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    data = request.get_json() or {}
    year = data.get('year')
    validated, error = _validate_manual_tax_group(year, data.get('row_ids') or [])
    if error:
        return jsonify({'error': error}), 400

    group = ManualCombineGroup(
        table_name='taxes',
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


@taxes_bp.route('/combine-groups/<int:group_id>', methods=['DELETE'])
@jwt_required()
def delete_tax_combine_group(group_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    group = ManualCombineGroup.query.filter_by(
        id=group_id,
        table_name='taxes',
    ).first_or_404()
    try:
        db.session.delete(group)
        db.session.commit()
        return jsonify({'message': 'Tax combine group deleted'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
