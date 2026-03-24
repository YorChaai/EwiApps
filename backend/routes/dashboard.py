# endpoint summary dashboard - yield count dan total user/manager

from datetime import datetime, timezone
from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from sqlalchemy import func

from models import db, User, Settlement, Advance, Expense

dashboard_bp = Blueprint('dashboard', __name__, url_prefix='/api/dashboard')


@dashboard_bp.route('/summary', methods=['GET'])
@jwt_required()
def get_summary():
    user = User.query.get(int(get_jwt_identity()))
    is_manager = user.role == 'manager'

    # pending counts
    settle_q = Settlement.query.filter_by(status='submitted')
    advance_q = Advance.query.filter_by(status='submitted')

    if not is_manager:
        settle_q = settle_q.filter_by(user_id=user.id)
        advance_q = advance_q.filter_by(user_id=user.id)

    pending_settlements = settle_q.count()
    pending_advances = advance_q.count()

    # total expenses bulan ini (idr)
    now = datetime.now(timezone.utc)
    first_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    expense_q = (
        db.session.query(func.coalesce(func.sum(Expense.idr_amount), 0))
        .filter(Expense.status == 'approved')
        .filter(Expense.date >= first_of_month.date())
    )
    if not is_manager:
        expense_q = expense_q.join(Settlement).filter(Settlement.user_id == user.id)

    total_expenses_month = float(expense_q.scalar() or 0)

    # total settlements & advances
    total_settle_q = Settlement.query
    total_advance_q = Advance.query
    if not is_manager:
        total_settle_q = total_settle_q.filter_by(user_id=user.id)
        total_advance_q = total_advance_q.filter_by(user_id=user.id)

    total_settlements = total_settle_q.count()
    total_advances = total_advance_q.count()

    return jsonify({
        'pending_settlements': pending_settlements,
        'pending_advances': pending_advances,
        'total_expenses_this_month': total_expenses_month,
        'total_settlements': total_settlements,
        'total_advances': total_advances,
        'is_manager': is_manager,
    }), 200
