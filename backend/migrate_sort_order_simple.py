"""
Simple migration script to add sort_order column to categories table
Run this ONCE to initialize sort_order for all existing categories.
"""

import sqlite3
import os

# Database path - try multiple possible locations
DB_PATHS = [
    os.path.join(os.path.dirname(__file__), 'database.db'),
    os.path.join(os.path.dirname(__file__), 'app.db'),
    os.path.join(os.path.dirname(__file__), 'ewi.db'),
    'D:\\2. Organize\\1. Projects\\MiniProjectKPI_EWI\\backend\\database.db',
]

def migrate():
    """Add sort_order column and populate with default values"""

    print("🔧 Starting migration: Adding sort_order column to categories table...")

    # Find existing database
    db_path = None
    for path in DB_PATHS:
        if os.path.exists(path):
            db_path = path
            break

    if not db_path:
        print("❌ Database file not found! Please run backend first to create database.")
        return

    print(f"📂 Using database: {db_path}")

    try:
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()

        # Step 1: Add sort_order column if not exists
        print("📝 Step 1: Adding sort_order column...")
        try:
            cursor.execute("ALTER TABLE categories ADD COLUMN sort_order INTEGER DEFAULT 0")
            print("✅ sort_order column added successfully!")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print("⚠️  Column sort_order already exists, skipping...")
            else:
                raise

        # Step 2: Populate sort_order based on id (ascending)
        print("📝 Step 2: Populating sort_order with default values...")
        cursor.execute("SELECT id FROM categories ORDER BY id")
        categories = cursor.fetchall()

        for idx, (cat_id,) in enumerate(categories, 1):
            cursor.execute("UPDATE categories SET sort_order = ? WHERE id = ?", (idx, cat_id))

        conn.commit()
        print(f"✅ Successfully populated sort_order for {len(categories)} categories!")

        # Step 3: Verify migration
        print("📝 Step 3: Verifying migration...")
        cursor.execute("SELECT id, code, name, sort_order FROM categories ORDER BY sort_order LIMIT 20")
        verify_categories = cursor.fetchall()

        print("\n📊 Migration Result:")
        print("-" * 60)
        print(f"{'ID':<5} {'Code':<10} {'Name':<30} {'Sort Order':<12}")
        print("-" * 60)
        for cat_id, code, name, sort_order in verify_categories:
            print(f"{cat_id:<5} {code:<10} {name:<30} {sort_order:<12}")

        if len(verify_categories) > 20:
            cursor.execute("SELECT COUNT(*) FROM categories")
            total = cursor.fetchone()[0]
            print(f"... and {total - 20} more categories")

        print("-" * 60)
        print("\n✅ Migration completed successfully!")
        print("\n💡 Next steps:")
        print("   1. Restart the Flask backend server")
        print("   2. Test the API: GET /api/categories")
        print("   3. Use Kategori Tabular UI to reorder categories")

        conn.close()

    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        raise

if __name__ == '__main__':
    migrate()
