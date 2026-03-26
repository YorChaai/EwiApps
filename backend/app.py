import os
import sqlite3
from datetime import timedelta, datetime, timezone
from flask import Flask, send_from_directory, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager, verify_jwt_in_request, get_jwt_identity
from flask_migrate import Migrate
from config import Config
from models import db, User, Category, Revenue, Tax, Dividend, DividendSetting, Notification
from werkzeug.security import generate_password_hash

migrate = Migrate()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=7)

    # init extensions
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    JWTManager(app)

    # buat folder jika belum ada
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(app.config['EXPORT_FOLDER'], exist_ok=True)

    # register blueprints
    from routes.auth import auth_bp
    from routes.settlements import settlements_bp
    from routes.expenses import expenses_bp
    from routes.reports import reports_bp
    from routes.categories import categories_bp
    from routes.advances import advances_bp
    from routes.settings import settings_bp
    from routes.revenues import revenues_bp
    from routes.taxes import taxes_bp
    from routes.dividends import dividends_bp
    from routes.dashboard import dashboard_bp
    from routes.notifications import notifications_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(settlements_bp)
    app.register_blueprint(expenses_bp)
    app.register_blueprint(reports_bp)
    app.register_blueprint(categories_bp)
    app.register_blueprint(advances_bp)
    app.register_blueprint(settings_bp)
    app.register_blueprint(revenues_bp)
    app.register_blueprint(taxes_bp)
    app.register_blueprint(dividends_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(notifications_bp)

    @app.before_request
    def touch_authenticated_user_activity():
        if request.method == 'OPTIONS' or not request.path.startswith('/api/'):
            return
        if request.path in ('/api/auth/login', '/api/auth/register'):
            return

        try:
            verify_jwt_in_request(optional=True)
            identity = get_jwt_identity()
            if not identity:
                return

            user = User.query.get(int(identity))
            if not user:
                return

            now = datetime.now(timezone.utc)
            last_login = user.last_login
            if last_login and last_login.tzinfo is None:
                last_login = last_login.replace(tzinfo=timezone.utc)

            # Simpan heartbeat maksimal tiap 30 detik agar status online tetap akurat
            # tanpa menulis database di setiap request kecil.
            if last_login is None or (now - last_login).total_seconds() >= 30:
                user.last_login = now
                db.session.commit()
        except Exception:
            db.session.rollback()

    @app.route('/api/uploads/<path:filename>')
    def serve_upload(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    # create tables & seed data
    with app.app_context():
        db.create_all()
        ensure_last_login_column(app)
        ensure_advance_type_column(app)
        ensure_advance_revision_schema(app)
        ensure_expense_advance_link_schema(app)
        ensure_bank_subcategory(app)
        ensure_rental_tool_subcategory(app)
        ensure_settlement_status_compatibility(app)
        ensure_dividends_table(app)
        imported = bootstrap_from_database_new(app)
        if not imported:
            seed_data()

    return app


def _extract_sqlite_path(uri: str) -> str | None:
    prefix = 'sqlite:///'
    if not uri.startswith(prefix):
        return None
    return uri[len(prefix):]


def _looks_hashed(password_hash: str) -> bool:
    if not password_hash:
        return False
    # hash werkzeug biasanya pbkdf2/scrypt
    return password_hash.startswith('pbkdf2:') or password_hash.startswith('scrypt:')


def ensure_last_login_column(app: Flask) -> None:
    # Tambah kolom last_login ke tabel users jika belum ada
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        cols = {
            row[1]
            for row in conn.execute("PRAGMA table_info(users)").fetchall()
        }
        if 'last_login' not in cols:
            conn.execute("ALTER TABLE users ADD COLUMN last_login DATETIME")
            conn.commit()
            print("✅ Kolom last_login ditambahkan ke tabel users")
    finally:
        conn.close()


def ensure_advance_type_column(app: Flask) -> None:
    # backfill schema untuk advance_type
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        cols = {
            row[1]
            for row in conn.execute("PRAGMA table_info(advances)").fetchall()
        }
        if 'advance_type' not in cols:
            conn.execute(
                "ALTER TABLE advances ADD COLUMN advance_type VARCHAR(10) DEFAULT 'single'"
            )
            conn.commit()
    finally:
        conn.close()


def _ensure_column(conn: sqlite3.Connection, table_name: str, column_name: str, ddl: str) -> None:
    cols = {
        row[1]
        for row in conn.execute(f"PRAGMA table_info({table_name})").fetchall()
    }
    if column_name not in cols:
        conn.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {ddl}")
        conn.commit()


def ensure_advance_revision_schema(app: Flask) -> None:
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        _ensure_column(conn, 'advances', 'approved_revision_no', 'INTEGER DEFAULT 0')
        _ensure_column(conn, 'advances', 'active_revision_no', 'INTEGER')
        _ensure_column(conn, 'advance_items', 'revision_no', 'INTEGER DEFAULT 0')
        _ensure_column(conn, 'advance_items', 'date', 'DATE')
        _ensure_column(conn, 'advance_items', 'source', 'VARCHAR(50)')
        _ensure_column(conn, 'advance_items', 'currency', 'VARCHAR(10) DEFAULT "IDR"')
        _ensure_column(conn, 'advance_items', 'currency_exchange', 'FLOAT DEFAULT 1.0')
        _ensure_column(conn, 'advance_items', 'status', 'VARCHAR(20) DEFAULT "pending"')
        _ensure_column(conn, 'advance_items', 'notes', 'TEXT')
    finally:
        conn.close()


def ensure_expense_advance_link_schema(app: Flask) -> None:
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        _ensure_column(conn, 'expenses', 'advance_item_id', 'INTEGER')
        _ensure_column(conn, 'expenses', 'revision_no', 'INTEGER DEFAULT 0')
    finally:
        conn.close()


def ensure_settlement_status_compatibility(app: Flask) -> None:
    # normalize status completed jadi approved
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        conn.execute(
            """
            UPDATE settlements
            SET status = 'approved'
            WHERE status = 'completed'
            """
        )
        conn.commit()
    finally:
        conn.close()


def ensure_bank_subcategory(app: Flask) -> None:
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        admin_row = conn.execute(
            """
            SELECT id
            FROM categories
            WHERE code = 'E' OR LOWER(name) = 'administrasi'
            ORDER BY id
            LIMIT 1
            """
        ).fetchone()
        if not admin_row:
            return

        admin_id = int(admin_row[0])
        bank_row = conn.execute(
            """
            SELECT id
            FROM categories
            WHERE parent_id = ? AND (code = 'E2' OR LOWER(name) = 'biaya bank')
            ORDER BY id
            LIMIT 1
            """,
            (admin_id,),
        ).fetchone()

        if bank_row:
            bank_category_id = int(bank_row[0])
        else:
            conn.execute(
                """
                INSERT INTO categories (name, code, parent_id, status, created_by)
                VALUES ('Biaya Bank', 'E2', ?, 'approved', 1)
                """,
                (admin_id,),
            )
            bank_category_id = int(conn.execute("SELECT last_insert_rowid()").fetchone()[0])

        conn.execute(
            """
            UPDATE expenses
            SET category_id = ?
            WHERE category_id = ?
              AND LOWER(description) LIKE '%bank%'
            """,
            (bank_category_id, admin_id),
        )
        conn.commit()
    finally:
        conn.close()


def ensure_rental_tool_subcategory(app: Flask) -> None:
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db or not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        equipment_row = conn.execute(
            """
            SELECT id
            FROM categories
            WHERE code = 'C' OR LOWER(name) = 'biaya sewa peralatan'
            ORDER BY id
            LIMIT 1
            """
        ).fetchone()
        if not equipment_row:
            return

        equipment_id = int(equipment_row[0])
        tool_row = conn.execute(
            """
            SELECT id
            FROM categories
            WHERE parent_id = ? AND (code = 'C1' OR LOWER(name) = 'rental tool')
            ORDER BY id
            LIMIT 1
            """,
            (equipment_id,),
        ).fetchone()
        if not tool_row:
            conn.execute(
                """
                INSERT INTO categories (name, code, parent_id, status, created_by)
                VALUES ('Rental Tool', 'C1', ?, 'approved', 1)
                """,
                (equipment_id,),
            )
            tool_category_id = int(conn.execute("SELECT last_insert_rowid()").fetchone()[0])
        else:
            tool_category_id = int(tool_row[0])

        conn.execute(
            """
            UPDATE expenses
            SET category_id = ?
            WHERE category_id = ?
              AND LOWER(description) LIKE '%rental tool%'
            """,
            (tool_category_id, equipment_id),
        )
        conn.commit()
    finally:
        conn.close()


def ensure_dividends_table(app: Flask) -> None:
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)
    if not target_db:
        return

    os.makedirs(os.path.dirname(target_db), exist_ok=True)
    conn = sqlite3.connect(target_db)
    try:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS dividends (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                date DATE NOT NULL,
                name VARCHAR(150) NOT NULL,
                amount FLOAT NOT NULL,
                recipient_count INTEGER NOT NULL DEFAULT 1,
                tax_percentage FLOAT NOT NULL DEFAULT 10.0,
                created_at DATETIME
            )
            """
        )
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS dividend_settings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                year INTEGER NOT NULL UNIQUE,
                profit_retained FLOAT NOT NULL DEFAULT 0.0,
                opening_cash_balance FLOAT NOT NULL DEFAULT 0.0,
                accounts_receivable FLOAT NOT NULL DEFAULT 0.0,
                prepaid_tax_pph23 FLOAT NOT NULL DEFAULT 0.0,
                prepaid_expenses FLOAT NOT NULL DEFAULT 0.0,
                other_receivables FLOAT NOT NULL DEFAULT 0.0,
                office_inventory FLOAT NOT NULL DEFAULT 0.0,
                other_assets FLOAT NOT NULL DEFAULT 0.0,
                accounts_payable FLOAT NOT NULL DEFAULT 0.0,
                salary_payable FLOAT NOT NULL DEFAULT 0.0,
                shareholder_payable FLOAT NOT NULL DEFAULT 0.0,
                accrued_expenses FLOAT NOT NULL DEFAULT 0.0,
                share_capital FLOAT NOT NULL DEFAULT 0.0,
                retained_earnings_balance FLOAT NOT NULL DEFAULT 0.0,
                created_at DATETIME
            )
            """
        )
        columns = {
            row[1]
            for row in conn.execute("PRAGMA table_info(dividends)").fetchall()
        }
        if 'recipient_count' not in columns:
            conn.execute(
                "ALTER TABLE dividends ADD COLUMN recipient_count INTEGER NOT NULL DEFAULT 1"
            )
        _ensure_column(conn, 'dividend_settings', 'opening_cash_balance', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'accounts_receivable', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'prepaid_tax_pph23', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'prepaid_expenses', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'other_receivables', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'office_inventory', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'other_assets', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'accounts_payable', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'salary_payable', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'shareholder_payable', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'accrued_expenses', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'share_capital', 'FLOAT NOT NULL DEFAULT 0.0')
        _ensure_column(conn, 'dividend_settings', 'retained_earnings_balance', 'FLOAT NOT NULL DEFAULT 0.0')
        conn.commit()
    finally:
        conn.close()


def bootstrap_from_database_new(app: Flask) -> bool:
    # auto import dari database_new.db jika utama kosong
    source_db = os.path.join(os.path.abspath(os.path.dirname(__file__)), 'database_new.db')
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    target_db = _extract_sqlite_path(target_uri)

    if not target_db or not os.path.exists(source_db):
        return False

    # jangan timpa db terisi
    if User.query.count() > 0 or Category.query.count() > 0 or Revenue.query.count() > 0:
        return False

    src = sqlite3.connect(source_db)
    src.row_factory = sqlite3.Row
    dst = sqlite3.connect(target_db)
    dst.execute('PRAGMA foreign_keys=OFF')

    try:
        table_exists = {
            row['name']
            for row in src.execute("SELECT name FROM sqlite_master WHERE type='table'")
        }
        required = {'users', 'categories', 'settlements', 'expenses', 'revenues', 'taxes'}
        if not required.issubset(table_exists):
            return False

        # clear tabel tujuan dulu
        for table in (
            'dividend_settings',
            'dividends',
            'expenses',
            'advance_items',
            'settlements',
            'advances',
            'taxes',
            'revenues',
            'categories',
            'users',
        ):
            try:
                dst.execute(f'DELETE FROM {table}')
            except sqlite3.Error:
                # abaikan jika tabel belum ada
                pass

        # users
        user_rows = src.execute(
            "SELECT id, username, password_hash, full_name, role, created_at FROM users ORDER BY id"
        ).fetchall()
        for row in user_rows:
            raw_hash = row['password_hash'] or ''
            safe_hash = raw_hash if _looks_hashed(raw_hash) else generate_password_hash(raw_hash or 'changeme123')
            dst.execute(
                """
                INSERT INTO users (id, username, password_hash, full_name, role, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['username'],
                    safe_hash,
                    row['full_name'],
                    row['role'],
                    row['created_at'],
                ),
            )

        # categories
        category_rows = src.execute(
            "SELECT id, name, code, parent_id, status, created_by FROM categories ORDER BY id"
        ).fetchall()
        for row in category_rows:
            dst.execute(
                """
                INSERT INTO categories (id, name, code, parent_id, status, created_by)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['name'],
                    row['code'],
                    row['parent_id'],
                    row['status'],
                    row['created_by'],
                ),
            )

        # advances jika ada di source
        if 'advances' in table_exists:
            advance_cols = {
                row['name']
                for row in src.execute("PRAGMA table_info(advances)").fetchall()
            }
            if 'advance_type' in advance_cols:
                advance_rows = src.execute(
                    """
                    SELECT id, title, description, COALESCE(advance_type, 'single') AS advance_type,
                           user_id, status, notes, created_at, updated_at, approved_at
                    FROM advances ORDER BY id
                    """
                ).fetchall()
            else:
                advance_rows = src.execute(
                    """
                    SELECT id, title, description, 'single' AS advance_type,
                           user_id, status, notes, created_at, updated_at, approved_at
                    FROM advances ORDER BY id
                    """
                ).fetchall()
            for row in advance_rows:
                dst.execute(
                    """
                    INSERT INTO advances (id, title, description, advance_type, user_id, status, notes, created_at, updated_at, approved_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        row['id'],
                        row['title'],
                        row['description'],
                        row['advance_type'],
                        row['user_id'],
                        row['status'],
                        row['notes'],
                        row['created_at'],
                        row['updated_at'],
                        row['approved_at'],
                    ),
                )

        if 'advance_items' in table_exists:
            item_rows = src.execute(
                """
                SELECT id, advance_id, category_id, description, estimated_amount,
                       evidence_path, evidence_filename, created_at
                FROM advance_items ORDER BY id
                """
            ).fetchall()
            for row in item_rows:
                dst.execute(
                    """
                    INSERT INTO advance_items (id, advance_id, category_id, description, estimated_amount, evidence_path, evidence_filename, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        row['id'],
                        row['advance_id'],
                        row['category_id'],
                        row['description'],
                        row['estimated_amount'],
                        row['evidence_path'],
                        row['evidence_filename'],
                        row['created_at'],
                    ),
                )

        # settlements
        settlement_rows = src.execute(
            """
            SELECT id, title, description, user_id, settlement_type, status,
                   created_at, updated_at, completed_at, advance_id
            FROM settlements ORDER BY id
            """
        ).fetchall()
        for row in settlement_rows:
            settlement_status = row['status']
            completed_at = row['completed_at']
            if settlement_status == 'completed':
                settlement_status = 'approved'
            dst.execute(
                """
                INSERT INTO settlements (id, title, description, user_id, settlement_type, status, created_at, updated_at, completed_at, advance_id)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['title'],
                    row['description'],
                    row['user_id'],
                    row['settlement_type'],
                    settlement_status,
                    row['created_at'],
                    row['updated_at'],
                    completed_at,
                    row['advance_id'],
                ),
            )

        # expenses
        expense_rows = src.execute(
            """
            SELECT id, settlement_id, category_id, description, amount, date,
                   source, currency, currency_exchange, evidence_path,
                   evidence_filename, status, notes, created_at
            FROM expenses ORDER BY id
            """
        ).fetchall()
        for row in expense_rows:
            dst.execute(
                """
                INSERT INTO expenses (id, settlement_id, category_id, description, amount, date, source, currency, currency_exchange, evidence_path, evidence_filename, status, notes, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['settlement_id'],
                    row['category_id'],
                    row['description'],
                    row['amount'],
                    row['date'],
                    row['source'],
                    row['currency'],
                    row['currency_exchange'],
                    row['evidence_path'],
                    row['evidence_filename'],
                    row['status'],
                    row['notes'],
                    row['created_at'],
                ),
            )

        # revenues
        revenue_rows = src.execute(
            """
            SELECT id, invoice_date, description, invoice_value, currency,
                   currency_exchange, invoice_number, client, receive_date,
                   amount_received, ppn, pph_23, transfer_fee, remark, created_at
            FROM revenues ORDER BY id
            """
        ).fetchall()
        for row in revenue_rows:
            dst.execute(
                """
                INSERT INTO revenues (id, invoice_date, description, invoice_value, currency, currency_exchange, invoice_number, client, receive_date, amount_received, ppn, pph_23, transfer_fee, remark, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['invoice_date'],
                    row['description'],
                    row['invoice_value'],
                    row['currency'],
                    row['currency_exchange'],
                    row['invoice_number'],
                    row['client'],
                    row['receive_date'],
                    row['amount_received'],
                    row['ppn'],
                    row['pph_23'],
                    row['transfer_fee'],
                    row['remark'],
                    row['created_at'],
                ),
            )

        # taxes
        tax_rows = src.execute(
            """
            SELECT id, date, description, transaction_value, currency,
                   currency_exchange, ppn, pph_21, pph_23, pph_26, created_at
            FROM taxes ORDER BY id
            """
        ).fetchall()
        for row in tax_rows:
            dst.execute(
                """
                INSERT INTO taxes (id, date, description, transaction_value, currency, currency_exchange, ppn, pph_21, pph_23, pph_26, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row['id'],
                    row['date'],
                    row['description'],
                    row['transaction_value'],
                    row['currency'],
                    row['currency_exchange'],
                    row['ppn'],
                    row['pph_21'],
                    row['pph_23'],
                    row['pph_26'],
                    row['created_at'],
                ),
            )

        if 'dividends' in table_exists:
            dividend_rows = src.execute(
                """
                SELECT id, date, name, amount, tax_percentage, created_at
                FROM dividends ORDER BY id
                """
            ).fetchall()
            src_dividend_columns = {
                row['name']
                for row in src.execute("PRAGMA table_info(dividends)").fetchall()
            }
            for row in dividend_rows:
                dst.execute(
                    """
                    INSERT INTO dividends (id, date, name, amount, recipient_count, tax_percentage, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        row['id'],
                        row['date'],
                        row['name'],
                        row['amount'],
                        row['recipient_count'] if 'recipient_count' in src_dividend_columns else 1,
                        row['tax_percentage'],
                        row['created_at'],
                    ),
                )

        if 'dividend_settings' in table_exists:
            src_setting_columns = {
                row[1]
                for row in src.execute("PRAGMA table_info(dividend_settings)").fetchall()
            }
            setting_rows = src.execute(
                """
                SELECT id, year, profit_retained, created_at
                FROM dividend_settings ORDER BY id
                """
            ).fetchall()
            for row in setting_rows:
                dst.execute(
                    """
                    INSERT INTO dividend_settings (
                        id, year, profit_retained, opening_cash_balance,
                        accounts_receivable, prepaid_tax_pph23, prepaid_expenses,
                        other_receivables, office_inventory, other_assets,
                        accounts_payable, salary_payable, shareholder_payable,
                        accrued_expenses, share_capital, retained_earnings_balance,
                        created_at
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (
                        row['id'],
                        row['year'],
                        row['profit_retained'],
                        row['opening_cash_balance'] if 'opening_cash_balance' in src_setting_columns else 0,
                        row['accounts_receivable'] if 'accounts_receivable' in src_setting_columns else 0,
                        row['prepaid_tax_pph23'] if 'prepaid_tax_pph23' in src_setting_columns else 0,
                        row['prepaid_expenses'] if 'prepaid_expenses' in src_setting_columns else 0,
                        row['other_receivables'] if 'other_receivables' in src_setting_columns else 0,
                        row['office_inventory'] if 'office_inventory' in src_setting_columns else 0,
                        row['other_assets'] if 'other_assets' in src_setting_columns else 0,
                        row['accounts_payable'] if 'accounts_payable' in src_setting_columns else 0,
                        row['salary_payable'] if 'salary_payable' in src_setting_columns else 0,
                        row['shareholder_payable'] if 'shareholder_payable' in src_setting_columns else 0,
                        row['accrued_expenses'] if 'accrued_expenses' in src_setting_columns else 0,
                        row['share_capital'] if 'share_capital' in src_setting_columns else 0,
                        row['retained_earnings_balance'] if 'retained_earnings_balance' in src_setting_columns else 0,
                        row['created_at'],
                    ),
                )

        dst.commit()
        return True
    finally:
        src.close()
        dst.close()


def seed_data():
    # seed default users & categories jika kosong
    if User.query.first() is None:
        # default users
        manager = User(username='manager1', full_name='Manager', role='manager')
        manager.set_password('manager12345')

        staff1 = User(username='staff1', full_name='Staff 1', role='staff')
        staff1.set_password('staff12345')

        staff2 = User(username='staff2', full_name='Staff 2', role='staff')
        staff2.set_password('staff67890')

        mitra1 = User(username='mitra1', full_name='Mitra Eksternal 1', role='mitra_eks')
        mitra1.set_password('mitra12345')

        db.session.add_all([manager, staff1, staff2, mitra1])

    if Category.query.first() is None:
        # kategori matching excel struktur oil & gas
        initial_data = {
            "Biaya Operasi": [
                "Transportation", "Accommodation", "Allowance", "Meal",
                "Shipping", "Laundry", "Operation", "Trip", "Training",
            ],
            "Biaya Research (R&D)": [],
            "Biaya Sewa Peralatan": [],
            "Biaya Interpretasi Log Data": [],
            "Administrasi": [
                "IT Services",
                "Biaya Bank",
            ],
            "Pembelian Barang": [
                "Logistic", "Hand Tools",
            ],
            "Sewa Kantor": [],
            "Kesehatan": [
                "Medical",
            ],
            "Bisnis Dev": [],
        }

        # generate kode dinamis (a, b, c...)
        import string
        letters = string.ascii_uppercase

        parent_idx = 0
        for parent_name, subs in initial_data.items():
            if parent_idx < len(letters):
                code = letters[parent_idx]
            else:
                code = f"Z{parent_idx - len(letters) + 1}"

            parent = Category(name=parent_name, code=code, created_by=1)
            db.session.add(parent)
            db.session.flush()

            for i, sub_name in enumerate(subs, 1):
                sub_code = f"{code}{i}"
                sub = Category(name=sub_name, code=sub_code, parent_id=parent.id, created_by=1)
                db.session.add(sub)

            parent_idx += 1

    if Revenue.query.first() is None:
        from datetime import date
        rev1 = Revenue(
            invoice_date=date(2025, 2, 1),
            description="Invoice untuk project bulan Jan 2025",
            invoice_value=11100000,
            invoice_number="INV-2025-001",
            client="PT Maju Jaya",
            currency="IDR",
            amount_received=10000000,
            ppn=1100000,
            pph_23=200000,
        )
        db.session.add(rev1)

    if Tax.query.first() is None:
        from datetime import date
        tax1 = Tax(
            date=date(2025, 2, 5),
            transaction_value=11100000,
            description="Pembayaran Pajak Jan 2025",
            ppn=1100000,
            pph_21=500000,
            pph_23=200000,
            pph_26=0,
        )
        db.session.add(tax1)

    db.session.commit()


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
