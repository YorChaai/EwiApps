from app import create_app
from models import db
from sqlalchemy import text

def migrate():
    app = create_app()
    with app.app_context():
        print("Starting migration: Adding new columns to users table...")

        try:
            # Check if columns already exist (PostgreSQL syntax)
            columns_to_add = [
                ("email", "VARCHAR(150)"),
                ("google_id", "VARCHAR(200)"),
                ("reset_token", "VARCHAR(100)"),
                ("reset_token_expiry", "TIMESTAMP")
            ]

            for col_name, col_type in columns_to_add:
                print(f"Checking column: {col_name}...")
                # Escape table name and column name for safety
                check_query = text(f"SELECT column_name FROM information_schema.columns WHERE table_name='users' AND column_name='{col_name}'")
                result = db.session.execute(check_query).fetchone()

                if not result:
                    print(f"Adding column {col_name}...")
                    alter_query = text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}")
                    db.session.execute(alter_query)

                    # Add unique constraints separately
                    if col_name in ['email', 'google_id']:
                        print(f"Adding UNIQUE constraint to {col_name}...")
                        unique_query = text(f"ALTER TABLE users ADD CONSTRAINT users_{col_name}_key UNIQUE ({col_name})")
                        db.session.execute(unique_query)
                else:
                    print(f"Column {col_name} already exists.")

            db.session.commit()
            print("Migration completed successfully.")

        except Exception as e:
            db.session.rollback()
            print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
