from app import create_app
from models import db, Expense, AdvanceItem

app = create_app()

def sync_data():
    with app.app_context():
        print("Memulai sinkronisasi data kategori ke tabel asosiasi baru...")
        
        # Sync Expenses
        expenses = Expense.query.all()
        exp_count = 0
        for exp in expenses:
            if exp.category_id and exp.category_id not in [c.id for c in exp.subcategories]:
                exp.subcategories.append(exp.category)
                exp_count += 1
        
        # Sync AdvanceItems
        items = AdvanceItem.query.all()
        item_count = 0
        for item in items:
            if item.category_id and item.category_id not in [c.id for c in item.subcategories]:
                item.subcategories.append(item.category)
                item_count += 1
        
        db.session.commit()
        print(f"Selesai! {exp_count} expenses dan {item_count} advance items berhasil disinkronkan.")

if __name__ == '__main__':
    sync_data()
