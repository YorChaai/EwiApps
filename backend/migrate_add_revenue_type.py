"""
Migration script to add revenue_type column to revenues table
Run this script to add the new column for revenue type differentiation
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from models import db
from sqlalchemy import text

app = create_app()

def run_migration():
    with app.app_context():
        print("🔄 Starting migration: Add revenue_type column to revenues table")
        print("-" * 70)

        try:
            # Check if column already exists
            result = db.session.execute(text("""
                SELECT COLUMN_NAME
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_NAME = 'revenues'
                AND COLUMN_NAME = 'revenue_type'
            """)).fetchone()

            if result:
                print("✅ Column 'revenue_type' already exists. Migration not needed.")
                return

            # Step 1: Add the column
            print("⏳ Step 1: Adding revenue_type column...")
            db.session.execute(text("""
                ALTER TABLE revenues
                ADD COLUMN revenue_type VARCHAR(32) NOT NULL DEFAULT 'pendapatan_langsung'
            """))
            db.session.commit()
            print("✅ Column added successfully")

            # Step 2: Create index
            print("⏳ Step 2: Creating index on revenue_type...")
            db.session.execute(text("""
                CREATE INDEX ix_revenues_revenue_type ON revenues(revenue_type)
            """))
            db.session.commit()
            print("✅ Index created successfully")

            # Step 3: Verify
            result = db.session.execute(text("""
                SELECT COUNT(*) as total, revenue_type
                FROM revenues
                GROUP BY revenue_type
            """)).fetchall()

            print("\n📊 Verification - Current revenue_type distribution:")
            for row in result:
                print(f"   {row.revenue_type}: {row.total} records")

            print("\n" + "=" * 70)
            print("✅ Migration completed successfully!")
            print("=" * 70)

        except Exception as e:
            db.session.rollback()
            print(f"\n❌ Migration failed: {str(e)}")
            print("Database changes have been rolled back.")
            sys.exit(1)

if __name__ == '__main__':
    run_migration()
