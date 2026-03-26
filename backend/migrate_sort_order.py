"""
Migration script to add sort_order column to categories table
and populate with default values based on category id.

Run this script once to initialize sort_order for all existing categories.
"""

import sys
import os

# Add parent directory to path to import models
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from models import db, Category, app
from sqlalchemy import text

def migrate():
    """Add sort_order column and populate with default values"""

    with app.app_context():
        print("🔧 Starting migration: Adding sort_order column to categories table...")

        try:
            # Step 1: Add sort_order column if not exists
            print("📝 Step 1: Adding sort_order column...")
            db.session.execute(text(
                """
                ALTER TABLE categories
                ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0
                """
            ))
            db.session.commit()
            print("✅ sort_order column added successfully!")

            # Step 2: Populate sort_order based on id (ascending)
            print("📝 Step 2: Populating sort_order with default values...")
            categories = Category.query.order_by(Category.id).all()

            for idx, category in enumerate(categories, 1):
                category.sort_order = idx

            db.session.commit()
            print(f"✅ Successfully populated sort_order for {len(categories)} categories!")

            # Step 3: Verify migration
            print("📝 Step 3: Verifying migration...")
            verify_categories = Category.query.order_by(Category.sort_order).all()
            print("\n📊 Migration Result:")
            print("-" * 60)
            print(f"{'ID':<5} {'Code':<10} {'Name':<30} {'Sort Order':<12}")
            print("-" * 60)
            for cat in verify_categories[:20]:  # Show first 20
                print(f"{cat.id:<5} {cat.code:<10} {cat.name:<30} {cat.sort_order:<12}")

            if len(verify_categories) > 20:
                print(f"... and {len(verify_categories) - 20} more categories")

            print("-" * 60)
            print("\n✅ Migration completed successfully!")
            print("\n💡 Next steps:")
            print("   1. Restart the Flask backend server")
            print("   2. Test the API: GET /api/categories")
            print("   3. Use Kategori Tabular UI to reorder categories")

        except Exception as e:
            db.session.rollback()
            print(f"❌ Migration failed: {str(e)}")
            raise

if __name__ == '__main__':
    migrate()
