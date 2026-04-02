"""
Simple migration script to add revenue_type column to revenues table
Run this directly without Flask app context
"""
import sqlite3
import os

# Find database file
db_path = os.path.join(os.path.dirname(__file__), 'database.db')

if not os.path.exists(db_path):
    print(f"❌ Database not found at: {db_path}")
    print("Please make sure you're running this from the backend directory")
    exit(1)

print(f"📊 Using database: {db_path}")
print("-" * 70)

try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if column already exists
    cursor.execute("PRAGMA table_info(revenues)")
    columns = [row[1] for row in cursor.fetchall()]

    if 'revenue_type' in columns:
        print("✅ Column 'revenue_type' already exists. Migration not needed.")
    else:
        print("⏳ Step 1: Adding revenue_type column...")
        cursor.execute("""
            ALTER TABLE revenues
            ADD COLUMN revenue_type VARCHAR(32) NOT NULL DEFAULT 'pendapatan_langsung'
        """)
        conn.commit()
        print("✅ Column added successfully")

        print("⏳ Step 2: Creating index on revenue_type...")
        cursor.execute("""
            CREATE INDEX ix_revenues_revenue_type ON revenues(revenue_type)
        """)
        conn.commit()
        print("✅ Index created successfully")

    # Verify
    print("\n📊 Verification - Current revenue_type distribution:")
    cursor.execute("""
        SELECT COUNT(*) as total, revenue_type
        FROM revenues
        GROUP BY revenue_type
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f"   {row[1]}: {row[0]} records")

    if not rows:
        print("   (no records in table yet)")

    print("\n" + "=" * 70)
    print("✅ Migration completed successfully!")
    print("=" * 70)
    print("\n🚀 You can now run: python app.py")

except sqlite3.Error as e:
    print(f"\n❌ Migration failed: {str(e)}")
    exit(1)
finally:
    if conn:
        conn.close()
