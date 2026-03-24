from app import app, db
from models import Advance, AdvanceItem

with app.app_context():
    advances = Advance.query.filter_by(advance_type='single').all()
    print(f"Total single advances: {len(advances)}")
    for a in advances:
        first_item = AdvanceItem.query.filter_by(advance_id=a.id).order_by(AdvanceItem.created_at.desc()).first()
        item_desc = first_item.description if first_item else "N/A"
        print(f"ID: {a.id}, Title: '{a.title}', First Item Desc: '{item_desc}'")
