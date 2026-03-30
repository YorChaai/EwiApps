"""
Debug script untuk investigate missing expense items
Usage: python scripts/debug_expense_items.py --year 2024
"""
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

def debug_expenses(year):
    from app import create_app
    from models import db, Expense, Settlement, Category

    app = create_app()

    with app.app_context():
        print(f"\n{'#'*70}")
        print(f"# DEBUG EXPENSE ITEMS FOR YEAR {year}")
        print(f"{'#'*70}\n")

        # 1. Query all expenses
        expenses_query = Expense.query.join(
            Settlement, Expense.settlement_id == Settlement.id
        ).filter(
            Settlement.status.in_(('approved', 'completed')),
            db.extract('year', Expense.date) == year,
        )
        expenses = expenses_query.order_by(Expense.date.asc()).all()

        print(f"Total expenses in DB: {len(expenses)}\n")

        # 2. Group by settlement
        groups = defaultdict(list)
        for e in expenses:
            is_batch = e.settlement.settlement_type == 'batch' if e.settlement else False
            key = 'Batch' if is_batch else 'Single'
            groups[key].append(e)

        print(f"Breakdown by type:")
        for key, items in groups.items():
            print(f"  {key}: {len(items)} expenses")

        # 3. Detailed batch breakdown
        batch_groups = defaultdict(list)
        for e in expenses:
            if e.settlement and e.settlement.settlement_type == 'batch':
                batch_groups[e.settlement_id].append(e)

        if batch_groups:
            print(f"\n{'='*70}")
            print(f"BATCH EXPENSE DETAILS:")
            print(f"{'='*70}")
            for settlement_id, items in sorted(batch_groups.items()):
                settlement = items[0].settlement
                print(f"\n  Settlement #{settlement_id}: {len(items)} expenses")
                print(f"    Title: {settlement.title}")
                print(f"    Type: {settlement.settlement_type}")
                print(f"    Description: {settlement.description[:100] if settlement.description else 'N/A'}...")

                # Show first 5 expenses
                print(f"    Sample expenses:")
                for i, item in enumerate(items[:5]):
                    desc = item.description[:50] if item.description else 'N/A'
                    print(f"      {i+1}. [{item.date}] {desc}...")
                if len(items) > 5:
                    print(f"      ... and {len(items) - 5} more")

        # 4. Check settlement descriptions for "Imported from Sheet"
        print(f"\n{'='*70}")
        print(f"SETTLEMENT DESCRIPTION ANALYSIS:")
        print(f"{'='*70}")

        for settlement_id, items in sorted(batch_groups.items()):
            settlement = items[0].settlement
            desc = settlement.description or ''

            # Check for "Imported from Sheet" pattern
            import re
            match = re.search(r'Imported from Sheet (\d+)', desc, re.IGNORECASE)
            if match:
                sheet_num = match.group(1)
                print(f"\n  Settlement #{settlement_id}:")
                print(f"    Has 'Imported from Sheet {sheet_num}' in description")
                print(f"    Expense count: {len(items)}")

        # 5. Category breakdown
        print(f"\n{'='*70}")
        print(f"CATEGORY BREAKDOWN:")
        print(f"{'='*70}")

        all_categories = Category.query.all()
        category_by_id = {c.id: c for c in all_categories}

        cat_counts = defaultdict(int)
        for e in expenses:
            cat_id = e.category_id
            if cat_id and cat_id in category_by_id:
                cat = category_by_id[cat_id]
                # Get root category
                while cat.parent_id:
                    cat = category_by_id.get(cat.parent_id, cat)
                cat_counts[cat.name] += 1

        for cat_name, count in sorted(cat_counts.items()):
            print(f"  {cat_name}: {count} expenses")

        # 6. Check for potential issues
        print(f"\n{'='*70}")
        print(f"POTENTIAL ISSUES CHECK:")
        print(f"{'='*70}")

        # Check expenses without settlement
        no_settlement = [e for e in expenses if not e.settlement]
        if no_settlement:
            print(f"\n  ⚠️  {len(no_settlement)} expenses without settlement")

        # Check expenses with null category
        no_category = [e for e in expenses if not e.category_id]
        if no_category:
            print(f"\n  ⚠️  {len(no_category)} expenses without category")

        # Check settlements with no description
        no_desc = [s_id for s_id, items in batch_groups.items()
                   if not items[0].settlement or not items[0].settlement.description]
        if no_desc:
            print(f"\n  ⚠️  {len(no_desc)} batches without settlement description")

        print(f"\n{'#'*70}")
        print(f"# DEBUG COMPLETE")
        print(f"{'#'*70}\n")

        return len(expenses), batch_groups

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Debug expense items in database')
    parser.add_argument('--year', type=int, default=2024, help='Year to debug (default: 2024)')
    args = parser.parse_args()

    debug_expenses(args.year)
