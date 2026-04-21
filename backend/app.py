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

            user = db.session.get(User, int(identity))
            if not user:
                return

            now = datetime.now(timezone.utc)
            last_login = user.last_login
            if last_login and last_login.tzinfo is None:
                last_login = last_login.replace(tzinfo=timezone.utc)

            if last_login is None or (now - last_login).total_seconds() >= 30:
                user.last_login = now
                db.session.commit()
        except Exception:
            db.session.rollback()

    @app.route('/api/uploads/<path:filename>')
    def serve_upload(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    # create tables & initial sync
    with app.app_context():
        db.create_all()
        run_database_integrity_maintenance(app)

        # Seed initial data safely
        try:
            seed_data()
        except Exception as e:
            print(f"⚠️ Warning: Seeding skipped ({str(e)}). Run migrations first.")

    return app


def run_database_integrity_maintenance(app: Flask):
    """
    Menangani normalisasi data ringan yang tidak bisa dihandle Flask-Migrate.
    Hapus fungsi ini jika database sudah benar-benar mature.
    """
    target_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    prefix = 'sqlite:///'
    if not target_uri.startswith(prefix):
        return

    target_db = target_uri[len(prefix):]
    if not os.path.exists(target_db):
        return

    conn = sqlite3.connect(target_db)
    try:
        # 1. Normalize status completed -> approved
        conn.execute("UPDATE settlements SET status = 'approved' WHERE status = 'completed'")

        # 2. Ensure default bank/tool subcategories (Opsional - sebaiknya di seed_data)
        conn.commit()
    except Exception as e:
        print(f"❌ Database Maintenance Error: {e}")
    finally:
        conn.close()


def seed_data():
    # seed default users & categories jika kosong
    if User.query.first() is None:
        manager = User(username='manager1', full_name='Manager', role='manager')
        manager.set_password('manager12345')

        staff1 = User(username='staff1', full_name='Staff 1', role='staff')
        staff1.set_password('staff12345')

        db.session.add_all([manager, staff1])

    if Category.query.first() is None:
        initial_data = {
            "Biaya Operasi": ["Transportation", "Accommodation", "Allowance", "Meal"],
            "Biaya Research (R&D)": [],
            "Administrasi": ["Biaya Bank"],
        }
        import string
        letters = string.ascii_uppercase

        for idx, (parent_name, subs) in enumerate(initial_data.items()):
            code = letters[idx] if idx < len(letters) else f"Z{idx}"
            parent = Category(name=parent_name, code=code, created_by=1, main_group='BIAYA ADMINISTRASI DAN UMUM')
            if 'operasi' in parent_name.lower() or 'research' in parent_name.lower():
                parent.main_group = 'BEBAN LANGSUNG'

            db.session.add(parent)
            db.session.flush()

            for i, sub_name in enumerate(subs, 1):
                db.session.add(Category(name=sub_name, code=f"{code}{i}", parent_id=parent.id, created_by=1))

    db.session.commit()


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
