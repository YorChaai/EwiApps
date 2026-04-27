import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..')))

from app import create_app
from models import db, Category

app = create_app()

with app.app_context():
    categories = Category.query.all()
    for c in categories:
        print(f"{c.id}|{c.parent_id}|{c.name}|{c.code}")
