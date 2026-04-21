from datetime import datetime

from flask import Blueprint, jsonify, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from models import Dividend, DividendSetting, Expense, Revenue, Settlement, User, db

dividends_bp = Blueprint('dividends', __name__, url_prefix='/api/dividends')


def _parse_date(date_str):
    if not date_str:
        return None
    try:
        return datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return None


def _compute_profit_after_tax(year: int) -> float:
    revenues = Revenue.query.filter(
        db.extract('year', Revenue.invoice_date) == year,
    ).all()
    expenses = Expense.query.join(
        Settlement, Expense.settlement_id == Settlement.id
    ).filter(
        Settlement.status.in_(('approved', 'completed')),
        db.extract('year', Expense.date) == year,
    ).all()

    revenue_total = sum((r.idr_amount_received or 0) for r in revenues)
    pph23_total = sum((r.pph_23 or 0) for r in revenues)
    total_cost = sum((e.idr_amount or 0) for e in expenses)
    profit_before_tax = revenue_total - total_cost
    tax_corporate = profit_before_tax * 0.22 * 0.5 if profit_before_tax > 0 else 0.0
    return profit_before_tax - (tax_corporate - pph23_total)


SETTING_FLOAT_FIELDS = [
    'profit_retained',
    'opening_cash_balance',
    'accounts_receivable',
    'prepaid_tax_pph23',
    'prepaid_expenses',
    'other_receivables',
    'office_inventory',
    'other_assets',
    'accounts_payable',
    'salary_payable',
    'shareholder_payable',
    'accrued_expenses',
    'share_capital',
    'retained_earnings_balance',
]


def _build_dividend_payload(year: int):
    setting = DividendSetting.query.filter_by(year=year).first()
    recipients = Dividend.query.filter(
        db.extract('year', Dividend.date) == year,
    ).order_by(Dividend.date.asc(), Dividend.id.asc()).all()

    profit_after_tax = _compute_profit_after_tax(year)
    profit_retained = setting.profit_retained if setting else 0.0
    dividend_distributed = max(profit_after_tax - profit_retained, 0.0)
    recipient_count = len(recipients)
    dividend_per_person = (
        dividend_distributed / recipient_count if recipient_count > 0 else 0.0
    )

    recipient_data = []
    for item in recipients:
        data = item.to_dict()
        data['dividend_per_person'] = dividend_per_person
        recipient_data.append(data)

    return {
        'year': year,
        'profit_after_tax': profit_after_tax,
        'profit_retained': profit_retained,
        'dividend_distributed': dividend_distributed,
        'recipient_count': recipient_count,
        'dividend_per_person': dividend_per_person,
        'settings': setting.to_dict() if setting else {
            'year': year,
            **{field: 0.0 for field in SETTING_FLOAT_FIELDS},
        },
        'data': recipient_data,
    }


@dividends_bp.route('', methods=['GET'])
@jwt_required()
def get_dividends():
    User.query.get(int(get_jwt_identity()))
    year = request.args.get('year', type=int)
    if year is None:
        return jsonify({'error': 'year wajib diisi'}), 400
    return jsonify(_build_dividend_payload(year)), 200


@dividends_bp.route('/<int:dividend_id>', methods=['GET'])
@jwt_required()
def get_dividend(dividend_id):
    dividend = Dividend.query.get_or_404(dividend_id)
    return jsonify(dividend.to_dict()), 200


@dividends_bp.route('', methods=['POST'])
@jwt_required()
def create_dividend():
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak. Hanya manager yang dapat membuat data dividen.'}), 403

    data = request.get_json() or {}
    date = _parse_date(data.get('date'))
    name = (data.get('name') or '').strip()
    profit_retained = data.get('profit_retained')

    if not date or not name:
        return jsonify({'error': 'date dan name wajib diisi'}), 400

    try:
        year = date.year
        setting = DividendSetting.query.filter_by(year=year).first()
        if setting is None:
            setting = DividendSetting(year=year, profit_retained=float(profit_retained or 0))
            db.session.add(setting)
        elif profit_retained is not None:
            setting.profit_retained = float(profit_retained or 0)

        dividend = Dividend(
            date=date,
            name=name,
            amount=0.0,
            recipient_count=1,
            tax_percentage=0.0,
        )
        db.session.add(dividend)
        db.session.commit()
        return jsonify(dividend.to_dict()), 201
    except Exception as exc:
        db.session.rollback()
        return jsonify({'error': str(exc)}), 500


@dividends_bp.route('/<int:dividend_id>', methods=['PUT'])
@jwt_required()
def update_dividend(dividend_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    dividend = Dividend.query.get_or_404(dividend_id)
    data = request.get_json() or {}

    if 'date' in data:
        parsed = _parse_date(data.get('date'))
        if not parsed:
            return jsonify({'error': 'Format date tidak valid'}), 400
        dividend.date = parsed
    if 'name' in data:
        dividend.name = (data.get('name') or '').strip()

    if not dividend.name:
        return jsonify({'error': 'name wajib diisi'}), 400

    try:
        db.session.commit()
        return jsonify(dividend.to_dict()), 200
    except Exception as exc:
        db.session.rollback()
        return jsonify({'error': str(exc)}), 500


@dividends_bp.route('/settings/<int:year>', methods=['PUT'])
@jwt_required()
def update_dividend_setting(year):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    data = request.get_json() or {}
    if not any(field in data for field in SETTING_FLOAT_FIELDS):
        return jsonify({'error': 'minimal satu field setting wajib diisi'}), 400

    try:
        setting = DividendSetting.query.filter_by(year=year).first()
        if setting is None:
            setting = DividendSetting(year=year)
            db.session.add(setting)
        for field in SETTING_FLOAT_FIELDS:
            if field in data:
                setattr(setting, field, float(data.get(field) or 0))
        db.session.commit()
        return jsonify(setting.to_dict()), 200
    except Exception as exc:
        db.session.rollback()
        return jsonify({'error': str(exc)}), 500


@dividends_bp.route('/<int:dividend_id>', methods=['DELETE'])
@jwt_required()
def delete_dividend(dividend_id):
    user = User.query.get(int(get_jwt_identity()))
    if user.role != 'manager':
        return jsonify({'error': 'Akses ditolak.'}), 403

    dividend = Dividend.query.get_or_404(dividend_id)
    try:
        db.session.delete(dividend)
        db.session.commit()
        return jsonify({'message': 'Penerima dividen dihapus'}), 200
    except Exception as exc:
        db.session.rollback()
        return jsonify({'error': str(exc)}), 500
