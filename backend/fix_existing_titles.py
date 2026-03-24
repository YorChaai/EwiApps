import sys
import os
sys.path.append(os.getcwd())
from app import app, db
from models import Advance, AdvanceItem

def fix_all_titles():
    with app.app_context():
        # Get all single advances
        advances = Advance.query.filter_by(advance_type='single').all()
        fixed_count = 0
        for a in advances:
            # Find the most recent item (highest ID or latest created_at)
            item = AdvanceItem.query.filter_by(advance_id=a.id).order_by(AdvanceItem.id.desc()).first()
            if item and item.description:
                if a.title != item.description:
                    print(f"Fixing Advance ID {a.id}: '{a.title}' -> '{item.description}'")
                    a.title = item.description
                    fixed_count += 1
            elif not item:
                if a.title != "Kasbon Mandiri":
                    a.title = "Kasbon Mandiri"
                    fixed_count += 1
                    
        db.session.commit()
        print(f"Update complete. Fixed {fixed_count} records.")

if __name__ == "__main__":
    fix_all_titles()
