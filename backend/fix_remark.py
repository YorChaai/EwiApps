#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Fix script to clear "inc.PPN11%" from revenues.remark column
Run this ONCE to clean up existing data.
"""

import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from models import db, Revenue
from app import app

def fix_remark_database():
    with app.app_context():
        print('[FIX] Starting to clear remark column...')

        # Step 1: Count records with "inc.PPN11%" or "Pemungut"
        affected = Revenue.query.filter(
            db.or_(
                Revenue.remark.like('%inc.PPN11%'),
                Revenue.remark.like('%inc. PPN11%'),
                Revenue.remark.like('%Pemungut%')
            )
        ).all()

        print(f'[FIX] Found {len(affected)} records with remark to clear:')
        for r in affected[:10]:  # Show first 10
            print(f'  - ID {r.id}: {r.invoice_number} | remark: "{r.remark}"')

        if len(affected) > 10:
            print(f'  ... and {len(affected) - 10} more')

        # Step 2: Clear remark
        for r in affected:
            r.remark = ''

        db.session.commit()

        print(f'[FIX] Successfully cleared {len(affected)} records!')
        print('[FIX] DONE! Please restart your application.')

if __name__ == '__main__':
    fix_remark_database()
