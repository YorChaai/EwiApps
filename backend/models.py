from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.ext.hybrid import hybrid_property

db = SQLAlchemy()


class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    full_name = db.Column(db.String(150), nullable=False)
    role = db.Column(db.String(20), nullable=False, default='staff')  # staff, manager, mitra_eks
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    settlements = db.relationship('Settlement', backref='creator', lazy=True)
    advances = db.relationship('Advance', backref='requester', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'full_name': self.full_name,
            'role': self.role,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Category(db.Model):
    __tablename__ = 'categories'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    code = db.Column(db.String(10), unique=True, nullable=False)  # a, b, c...
    parent_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=True)
    status = db.Column(db.String(20), default='approved')  # approved, pending
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)

    children = db.relationship('Category', backref=db.backref('parent', remote_side=[id]), lazy=True)
    expenses = db.relationship('Expense', backref='category', lazy=True)

    @property
    def full_name(self):
        if self.parent:
            return f"{self.parent.name} > {self.name}"
        return self.name

    def to_dict(self, include_children=False):
        data = {
            'id': self.id,
            'name': self.name,
            'full_name': self.full_name,
            'code': self.code,
            'parent_id': self.parent_id,
            'status': self.status,
            'created_by': self.created_by
        }
        if include_children:
            data['children'] = [c.to_dict() for c in self.children]
        return data


class Advance(db.Model):
    __tablename__ = 'advances'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)  # Format: [Kategori] Vendor - Barang - Keperluan
    advance_type = db.Column(db.String(10), default='single')  # 'single' or 'batch'
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    status = db.Column(db.String(30), default='draft')  # draft, submitted, approved, rejected, revision_draft, revision_submitted, revision_rejected, in_settlement, completed(legacy)
    notes = db.Column(db.Text, nullable=True)  # notes approval mgr
    approved_revision_no = db.Column(db.Integer, default=0)
    active_revision_no = db.Column(db.Integer, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    approved_at = db.Column(db.DateTime, nullable=True)

    settlement = db.relationship('Settlement', backref='advance', uselist=False)
    items = db.relationship('AdvanceItem', backref='advance', lazy=True, cascade='all, delete-orphan')

    @property
    def total_amount(self):
        return sum(item.estimated_amount for item in self.items)

    @property
    def approved_amount(self):
        return sum(
            item.estimated_amount
            for item in self.items
            if (item.revision_no or 0) <= (self.approved_revision_no or 0)
        )

    @property
    def base_amount(self):
        return sum(
            item.estimated_amount
            for item in self.items
            if (item.revision_no or 0) == 0
        )

    @property
    def revision_amount(self):
        return max(0, self.approved_amount - self.base_amount)

    @property
    def max_revision_no(self):
        revision_numbers = [item.revision_no or 0 for item in self.items]
        return max(revision_numbers, default=0)

    def to_dict(self, include_items=False):
        settlement_total = self.settlement.total_amount if self.settlement else 0
        variance_amount = self.approved_amount - settlement_total
        revision_summaries = []
        for revision_no in range(0, self.max_revision_no + 1):
            revision_items = [
                item for item in self.items
                if (item.revision_no or 0) == revision_no
            ]
            if not revision_items:
                continue
            revision_summaries.append({
                'revision_no': revision_no,
                'label': 'Pengajuan Awal' if revision_no == 0 else f'Revisi {revision_no}',
                'item_count': len(revision_items),
                'total_amount': sum(item.estimated_amount for item in revision_items),
                'is_approved': revision_no <= (self.approved_revision_no or 0),
                'is_active': revision_no == self.active_revision_no,
            })

        policy_warnings = []
        if self.active_revision_no:
            policy_warnings.append(
                f"Sedang ada draft/approval revisi {self.active_revision_no}."
            )
        if self.settlement:
            if settlement_total > self.approved_amount:
                policy_warnings.append(
                    'Realisasi settlement melebihi total dana kasbon yang disetujui.'
                )
            elif variance_amount > 0:
                policy_warnings.append(
                    'Masih ada sisa dana kasbon yang belum terpakai.'
                )

        sorted_items = sorted(self.items, key=lambda x: x.id, reverse=True)
        first_item = sorted_items[0] if sorted_items else None
        data = {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'first_item_description': first_item.description if first_item else None,
            'advance_type': self.advance_type or 'single',
            'user_id': self.user_id,
            'requester_name': self.requester.full_name if self.requester else None,
            'status': self.status,
            'notes': self.notes,
            'total_amount': self.total_amount,
            'approved_amount': self.approved_amount,
            'base_amount': self.base_amount,
            'revision_amount': self.revision_amount,
            'item_count': len(self.items),
            'approved_revision_no': self.approved_revision_no or 0,
            'active_revision_no': self.active_revision_no,
            'max_revision_no': self.max_revision_no,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'approved_at': self.approved_at.isoformat() if self.approved_at else None,
            'settlement_id': self.settlement.id if self.settlement else None,
            'settlement_status': self.settlement.status if self.settlement else None,
            'settlement_total_amount': settlement_total,
            'variance_amount': variance_amount,
            'policy_warnings': policy_warnings,
            'revision_summaries': revision_summaries,
        }
        if include_items:
            data['items'] = [i.to_dict() for i in self.items]
        return data


class AdvanceItem(db.Model):
    __tablename__ = 'advance_items'
    id = db.Column(db.Integer, primary_key=True)
    advance_id = db.Column(db.Integer, db.ForeignKey('advances.id'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False)
    description = db.Column(db.String(300), nullable=False)  # Format: [Kategori] Vendor - Barang - Keperluan
    estimated_amount = db.Column(db.Float, nullable=False)
    revision_no = db.Column(db.Integer, default=0)
    evidence_path = db.Column(db.String(500), nullable=True)
    evidence_filename = db.Column(db.String(200), nullable=True)
    date = db.Column(db.Date, nullable=True)
    source = db.Column(db.String(50), nullable=True)
    currency = db.Column(db.String(10), default='IDR')
    currency_exchange = db.Column(db.Float, default=1.0)
    status = db.Column(db.String(20), default='pending')  # pending, approved, rejected
    notes = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    category = db.relationship('Category')

    def to_dict(self):
        d_val = None
        if self.date:
            try:
                d_val = self.date.isoformat() if hasattr(self.date, 'isoformat') else str(self.date)
            except:
                d_val = str(self.date)

        return {
            'id': self.id,
            'advance_id': self.advance_id,
            'category_id': self.category_id,
            'category_name': self.category.full_name if self.category else (self.category.name if self.category else None),
            'category_code': self.category.code if self.category else None,
            'description': self.description,
            'estimated_amount': self.estimated_amount,
            'revision_no': self.revision_no or 0,
            'evidence_path': self.evidence_path,
            'evidence_filename': self.evidence_filename,
            'date': d_val,
            'source': self.source,
            'currency': self.currency or 'IDR',
            'currency_exchange': self.currency_exchange or 1.0,
            'status': self.status or 'pending',
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Settlement(db.Model):
    __tablename__ = 'settlements'
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    settlement_type = db.Column(db.String(10), default='single')  # 'single' or 'batch'
    status = db.Column(db.String(20), default='draft')  # draft, submitted, approved, rejected, completed(legacy)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc),
                           onupdate=lambda: datetime.now(timezone.utc))
    completed_at = db.Column(db.DateTime, nullable=True)

    advance_id = db.Column(db.Integer, db.ForeignKey('advances.id'), nullable=True)

    expenses = db.relationship('Expense', backref='settlement', lazy=True,
                               cascade='all, delete-orphan')

    @property
    def total_amount(self):
        return sum((e.idr_amount or 0) for e in self.expenses)

    @property
    def approved_amount(self):
        return sum((e.idr_amount or 0) for e in self.expenses if e.status == 'approved')

    def to_dict(self, include_expenses=False):
        advance = self.advance
        available_fund = advance.approved_amount if advance else 0
        variance_amount = available_fund - self.total_amount if advance else None
        policy_warnings = []
        if advance:
            if self.total_amount > available_fund:
                policy_warnings.append(
                    'Total realisasi melebihi dana kasbon yang sudah disetujui.'
                )
            elif variance_amount and variance_amount > 0:
                policy_warnings.append(
                    'Masih ada sisa dana kasbon dibanding realisasi saat ini.'
                )

        first_exp = self.expenses[0] if self.expenses else None
        data = {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'first_expense_description': first_exp.description if first_exp else None,
            'user_id': self.user_id,
            'creator_name': self.creator.full_name if self.creator else None,
            'settlement_type': self.settlement_type,
            'status': self.status,
            'total_amount': self.total_amount,
            'approved_amount': self.approved_amount,
            'expense_count': len(self.expenses),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'advance_id': self.advance_id,
            'available_fund': available_fund,
            'variance_amount': variance_amount,
            'policy_warnings': policy_warnings,
        }
        if advance:
            data['advance_summary'] = {
                'advance_id': advance.id,
                'base_amount': advance.base_amount,
                'revision_amount': advance.revision_amount,
                'approved_amount': advance.approved_amount,
                'approved_revision_no': advance.approved_revision_no or 0,
                'status': advance.status,
            }
        if include_expenses:
            data['expenses'] = [e.to_dict() for e in self.expenses]
        return data


class Expense(db.Model):
    __tablename__ = 'expenses'
    id = db.Column(db.Integer, primary_key=True)
    settlement_id = db.Column(db.Integer, db.ForeignKey('settlements.id'), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False)
    description = db.Column(db.String(300), nullable=False)  # Format: [Kategori] Vendor - Barang - Keperluan
    amount = db.Column(db.Float, nullable=False)
    date = db.Column(db.Date, nullable=False)
    source = db.Column(db.String(50), nullable=True)  # bca, bri, cash, dll
    advance_item_id = db.Column(db.Integer, db.ForeignKey('advance_items.id'), nullable=True)
    revision_no = db.Column(db.Integer, default=0)
    currency = db.Column(db.String(10), default='IDR')  # idr, usd
    currency_exchange = db.Column(db.Float, default=1)  # exchange rate
    evidence_path = db.Column(db.String(500), nullable=True)
    evidence_filename = db.Column(db.String(200), nullable=True)
    status = db.Column(db.String(20), default='pending')  # pending, approved, rejected
    notes = db.Column(db.Text, nullable=True)  # notes
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    advance_item = db.relationship('AdvanceItem')

    @hybrid_property
    def idr_amount(self):
        # amount idr setelah exchange
        if self.currency != 'IDR' and self.currency_exchange:
            return self.amount * self.currency_exchange
        return self.amount

    @idr_amount.expression
    def idr_amount(cls):
        return db.case(
            (db.and_(cls.currency != 'IDR', cls.currency_exchange.isnot(None)), cls.amount * cls.currency_exchange),
            else_=cls.amount
        )

    def to_dict(self):
        d_val = None
        if self.date:
            try:
                d_val = self.date.isoformat() if hasattr(self.date, 'isoformat') else str(self.date)
            except:
                d_val = str(self.date)

        return {
            'id': self.id,
            'settlement_id': self.settlement_id,
            'category_id': self.category_id,
            'category_name': self.category.full_name if self.category else (self.category.name if self.category else None),
            'category_code': self.category.code if self.category else None,
            'description': self.description,
            'amount': self.amount,
            'date': d_val,
            'source': self.source,
            'advance_item_id': self.advance_item_id,
            'revision_no': self.revision_no or 0,
            'currency': self.currency,
            'currency_exchange': self.currency_exchange,
            'idr_amount': self.idr_amount,
            'evidence_path': self.evidence_path,
            'evidence_filename': self.evidence_filename,
            'status': self.status,
            'notes': self.notes,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Revenue(db.Model):
    __tablename__ = 'revenues'
    id = db.Column(db.Integer, primary_key=True)
    invoice_date = db.Column(db.Date, nullable=False)
    description = db.Column(db.String(300), nullable=False)
    invoice_value = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(10), default='IDR')
    currency_exchange = db.Column(db.Float, nullable=True) # nilai tukar jika bukan idr
    invoice_number = db.Column(db.String(50), nullable=True)
    client = db.Column(db.String(150), nullable=True)
    receive_date = db.Column(db.Date, nullable=True)
    amount_received = db.Column(db.Float, nullable=True)
    ppn = db.Column(db.Float, nullable=True)
    pph_23 = db.Column(db.Float, nullable=True)
    transfer_fee = db.Column(db.Float, nullable=True)
    remark = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def idr_invoice_value(self):
        if self.currency != 'IDR' and self.currency_exchange:
            return self.invoice_value * self.currency_exchange
        return self.invoice_value

    @property
    def idr_amount_received(self):
        if self.amount_received is None:
            return 0
        if self.currency != 'IDR' and self.currency_exchange:
            return self.amount_received * self.currency_exchange
        return self.amount_received

    def to_dict(self):
        return {
            'id': self.id,
            'invoice_date': self.invoice_date.isoformat() if self.invoice_date else None,
            'description': self.description,
            'invoice_value': self.invoice_value,
            'currency': self.currency,
            'currency_exchange': self.currency_exchange,
            'invoice_number': self.invoice_number,
            'client': self.client,
            'receive_date': self.receive_date.isoformat() if self.receive_date else None,
            'amount_received': self.amount_received,
            'ppn': self.ppn,
            'pph_23': self.pph_23,
            'transfer_fee': self.transfer_fee,
            'remark': self.remark,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class Tax(db.Model):
    __tablename__ = 'taxes'
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.Date, nullable=False)
    description = db.Column(db.String(300), nullable=False)
    transaction_value = db.Column(db.Float, nullable=False)
    currency = db.Column(db.String(10), default='IDR')
    currency_exchange = db.Column(db.Float, nullable=True)

    # simpan nilai nominal pajak saja
    ppn = db.Column(db.Float, nullable=True)
    pph_21 = db.Column(db.Float, nullable=True)
    pph_23 = db.Column(db.Float, nullable=True)
    pph_26 = db.Column(db.Float, nullable=True)

    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    @property
    def idr_transaction_value(self):
        if self.currency != 'IDR' and self.currency_exchange:
            return self.transaction_value * self.currency_exchange
        return self.transaction_value

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date.isoformat() if self.date else None,
            'description': self.description,
            'transaction_value': self.transaction_value,
            'currency': self.currency,
            'currency_exchange': self.currency_exchange,
            'ppn': self.ppn,
            'pph_21': self.pph_21,
            'pph_23': self.pph_23,
            'pph_26': self.pph_26,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }


class ManualCombineGroup(db.Model):
    __tablename__ = 'manual_combine_groups'
    id = db.Column(db.Integer, primary_key=True)
    table_name = db.Column(db.String(20), nullable=False)
    report_year = db.Column(db.Integer, nullable=False)
    group_date = db.Column(db.Date, nullable=False)
    row_ids_json = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def row_ids(self):
        try:
            import json
            data = json.loads(self.row_ids_json or '[]')
            if isinstance(data, list):
                return [int(x) for x in data]
        except Exception:
            pass
        return []

    def to_dict(self):
        return {
            'id': self.id,
            'table_name': self.table_name,
            'report_year': self.report_year,
            'group_date': self.group_date.isoformat() if self.group_date else None,
            'row_ids': self.row_ids(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Dividend(db.Model):
    __tablename__ = 'dividends'
    id = db.Column(db.Integer, primary_key=True)
    date = db.Column(db.Date, nullable=False)
    name = db.Column(db.String(150), nullable=False)
    amount = db.Column(db.Float, nullable=False, default=0.0)
    recipient_count = db.Column(db.Integer, nullable=False, default=1)
    tax_percentage = db.Column(db.Float, nullable=False, default=0.0)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'date': self.date.isoformat() if self.date else None,
            'name': self.name,
            'amount': self.amount,
            'recipient_count': self.recipient_count or 1,
            'tax_percentage': self.tax_percentage or 0.0,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class DividendSetting(db.Model):
    __tablename__ = 'dividend_settings'
    id = db.Column(db.Integer, primary_key=True)
    year = db.Column(db.Integer, nullable=False, unique=True)
    profit_retained = db.Column(db.Float, nullable=False, default=0.0)
    opening_cash_balance = db.Column(db.Float, nullable=False, default=0.0)
    accounts_receivable = db.Column(db.Float, nullable=False, default=0.0)
    prepaid_tax_pph23 = db.Column(db.Float, nullable=False, default=0.0)
    prepaid_expenses = db.Column(db.Float, nullable=False, default=0.0)
    other_receivables = db.Column(db.Float, nullable=False, default=0.0)
    office_inventory = db.Column(db.Float, nullable=False, default=0.0)
    other_assets = db.Column(db.Float, nullable=False, default=0.0)
    accounts_payable = db.Column(db.Float, nullable=False, default=0.0)
    salary_payable = db.Column(db.Float, nullable=False, default=0.0)
    shareholder_payable = db.Column(db.Float, nullable=False, default=0.0)
    accrued_expenses = db.Column(db.Float, nullable=False, default=0.0)
    share_capital = db.Column(db.Float, nullable=False, default=0.0)
    retained_earnings_balance = db.Column(db.Float, nullable=False, default=0.0)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))

    def to_dict(self):
        return {
            'id': self.id,
            'year': self.year,
            'profit_retained': self.profit_retained,
            'opening_cash_balance': self.opening_cash_balance,
            'accounts_receivable': self.accounts_receivable,
            'prepaid_tax_pph23': self.prepaid_tax_pph23,
            'prepaid_expenses': self.prepaid_expenses,
            'other_receivables': self.other_receivables,
            'office_inventory': self.office_inventory,
            'other_assets': self.other_assets,
            'accounts_payable': self.accounts_payable,
            'salary_payable': self.salary_payable,
            'shareholder_payable': self.shareholder_payable,
            'accrued_expenses': self.accrued_expenses,
            'share_capital': self.share_capital,
            'retained_earnings_balance': self.retained_earnings_balance,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Notification(db.Model):
    __tablename__ = 'notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    actor_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    action_type = db.Column(db.String(50), nullable=False)  # submit, approve, reject, create
    target_type = db.Column(db.String(50), nullable=False)  # settlement, advance, category
    target_id = db.Column(db.Integer, nullable=False)
    message = db.Column(db.Text, nullable=False)
    read_status = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    link_path = db.Column(db.String(200), nullable=True)

    user = db.relationship('User', foreign_keys=[user_id], backref='notifications_received')
    actor = db.relationship('User', foreign_keys=[actor_id], backref='notifications_created')

    def to_dict(self):
        actor_name = self.actor.full_name if self.actor else 'System'
        return {
            'id': self.id,
            'user_id': self.user_id,
            'actor_id': self.actor_id,
            'actor_name': actor_name,
            'action_type': self.action_type,
            'target_type': self.target_type,
            'target_id': self.target_id,
            'message': self.message,
            'read_status': self.read_status,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'link_path': self.link_path
        }
