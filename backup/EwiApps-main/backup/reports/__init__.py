from flask import Blueprint

reports_bp = Blueprint('reports', __name__, url_prefix='/api/reports')

# import route modul
from . import summary   # noqa: F401, E402
from . import annual    # noqa: F401, E402
